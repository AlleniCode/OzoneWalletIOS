//
//  SendReviewTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/17/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher
import KeychainAccess
import Neoutils
import Amplitude

class SendReviewTableViewController: UITableViewController {
    @IBOutlet weak var sendReviewTitleLabel: UILabel!
    
    @IBOutlet weak var sendWhatLabel: UILabel!
    @IBOutlet weak var sendWhatImageView: UIImageView!
    
    @IBOutlet weak var sendToAliasLabel: UILabel!
    @IBOutlet weak var sendToAliasImageView: UIImageView!
    @IBOutlet weak var sendToAddressLabel: UILabel!
    
    @IBOutlet weak var feeLabel: UILabel!
    @IBOutlet weak var feeAmountLabel: UILabel!
    @IBOutlet weak var sendButton: ShadowedButton!
    @IBOutlet weak var contentView: UIView!
    
    var selectedAsset: TransferableAsset!
    var selectedAmount: Double!
    var sendToAddress: String!
    var addressAlias: String = ""
    var addressAliasImage: UIImage?
    var feeAmount = 0.0
    var feeEnabled = false
    var transactionCompleted = false
    
    var txId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        addThemedElements()
        initiateViews()
    }
    
    func initiateViews() {
        sendToAddressLabel.text = sendToAddress
        let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", selectedAsset.symbol.uppercased())
        sendWhatImageView.kf.setImage(with: URL(string: imageURL))
        sendToAliasLabel.text = addressAlias
        sendToAliasImageView.image = addressAliasImage
        sendWhatLabel.text = selectedAmount.string(8, removeTrailing: true) + " " + selectedAsset.symbol
        if addressAliasImage != nil {
            addressAliasImage = addressAliasImage!
        }
        sendButton.isEnabled = true
        
        if feeEnabled {
            feeAmountLabel.text = "0.0011 GAS"
        } else if selectedAsset.id.contains("0000000") {
            feeAmountLabel.text = "0.01 ONG"
        } else {
            feeLabel.isHidden = true
            feeAmountLabel.isHidden = true
        }
        
    }
    
    func sendNativeAsset(assetId: AssetId, assetName: String, amount: Double, toAddress: String) {
        DispatchQueue.main.async {
            let keychain = Keychain(service: "network.o3.neo.wallet")
            do {
                _ = try keychain
                    .authenticationPrompt(SendStrings.authenticateToSendPrompt)
                    .get(AppState.protectedKeyValue)
                
                    O3HUD.start()
                    if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                        AppState.bestSeedNodeURL = bestNode
                    }
                    var customAttributes: [TransactionAttritbute] = []
                    let remark = String(format: "O3XSEND")
                    customAttributes.append(TransactionAttritbute(remark: remark))
                    var fee = 0.0
                    if self.feeEnabled {
                        fee = 0.0011
                    }
                    Authenticated.wallet?.sendAssetTransaction(network: AppState.network, seedURL: AppState.bestSeedNodeURL, asset: assetId, amount: amount, toAddress: toAddress, attributes: customAttributes, fee: fee) { txid, _ in
                        O3HUD.stop {
                            if txid != nil {
                                self.txId = txid!
                                self.transactionCompleted = true
                                Amplitude.instance()?.logEvent("Asset Send", withEventProperties: ["asset": assetName,
                                                                                                "amount": amount])
                            } else {
                                self.transactionCompleted = false
                            }
                            //save to pending tx if it's completed
                            if self.transactionCompleted == true {
                                self.savePendingTransaction(blockchain: "neo", txID: txid!, from: (Authenticated.wallet?.address)!, to: toAddress, asset: self.selectedAsset!, amount: amount.string(self.selectedAsset!.decimals, removeTrailing: true))
                            }
                            self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                        }
                }
                } catch _ {
            }
        }
    }
    
    
    func sendOntology(assetSymbol: String, amount: Double, toAddress: String) {
        let ong = O3Cache.ontologyAssets().first { t -> Bool in
            return t.symbol.uppercased() == "ONG"
        }
        
        if ong == nil {
            return
        }
        
        if ong!.value.isLess(than: 0.01) {
            OzoneAlert.alertDialog(message: "Ontology network requires 0.01 ONG for transaction fees. You don't seem to have enough ONG in your wallet", dismissTitle: "OK") {
                
            }
            return
        }
        
        let wif = Authenticated.wallet?.wif
        var error: NSError?
        let endpoint = ONTNetworkMonitor.autoSelectBestNode(network: AppState.network)
        OntologyClient().getGasPrice { result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.transactionCompleted = false
                    self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                }
            case .success(let gasPrice):
                let txid = NeoutilsOntologyTransfer(endpoint, gasPrice, 20000, wif, assetSymbol, toAddress, amount, &error)
                DispatchQueue.main.async {
                    if txid != "" {
                        self.txId = txid!
                        self.savePendingTransaction(blockchain: "ontology", txID: txid!, from: (Authenticated.wallet?.address)!, to: toAddress, asset: self.selectedAsset!, amount: amount.string(self.selectedAsset!.decimals, removeTrailing: true))
                        self.transactionCompleted = true
                        self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                    } else {
                        Amplitude.instance()?.logEvent("Asset Send", withEventProperties: ["asset": assetSymbol,
                                                                                           "amount": amount ])
                        self.transactionCompleted = false
                        self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                    }
                }
            }
        }
    }
    
    
    func sendNEP5Token(tokenHash: String, decimals: Int, assetName: String, amount: Double, toAddress: String) {
        DispatchQueue.main.async {
            let keychain = Keychain(service: "network.o3.neo.wallet")
            do {
            _ = try keychain
                .authenticationPrompt(SendStrings.authenticateToSendPrompt)
                .get(AppState.protectedKeyValue)
                O3HUD.start()
                if let bestNode = NEONetworkMonitor.autoSelectBestNode(network: AppState.network) {
                    AppState.bestSeedNodeURL = bestNode
                }
                var fee = 0.0
                if self.feeEnabled {
                 fee = 0.0011
                }
                Authenticated.wallet?.sendNep5Token(network: AppState.network, seedURL: AppState.bestSeedNodeURL, tokenContractHash: tokenHash, decimals: self.selectedAsset!.decimals, amount: amount, toAddress: toAddress, fee: fee) { (completed, _ , txID) in
                        O3HUD.stop {
                            self.transactionCompleted = completed ?? false
                            Amplitude.instance()?.logEvent("Asset Send", withEventProperties: ["asset": assetName,
                                                                                               "amount": amount])
                            if self.transactionCompleted == true {
                                self.txId = txID!
                                self.savePendingTransaction(blockchain: "neo", txID: txID!, from: (Authenticated.wallet?.address)!, to: toAddress, asset: self.selectedAsset!, amount: amount.string(self.selectedAsset!.decimals, removeTrailing: true))
                                self.performSegue(withIdentifier: "segueToTransactionComplete", sender: nil)
                            }
                        }
                }
            } catch _ {
            }
        }
    }
    
    func savePendingTransaction(blockchain: String,txID: String, from: String, to: String, asset: TransferableAsset, amount: String) {
        let context = UIApplication.appDelegate.accountPersistentContainer.viewContext
        let pending = PendingTransaction(context: context)
        pending.blockchain = blockchain
        pending.txID = txID
        pending.from = from
        pending.to = to
        pending.amount = amount
        pending.timestamp = Int64(Date().timeIntervalSince1970)
        pending.asset = asset.symbol
        UIApplication.appDelegate.saveAccountContext()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "pendingTransactionAdded"), object: nil)
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        var id = selectedAsset.id
        if self.selectedAsset.assetType == .neoAsset {
            if selectedAsset.id.hasPrefix("0x") {
                id = String(id.dropFirst(2))
            }
            self.sendNativeAsset(assetId: AssetId(rawValue: id)!, assetName: selectedAsset.name, amount: selectedAmount, toAddress: sendToAddress)
        } else if self.selectedAsset?.assetType == .nep5Token {
            self.sendNEP5Token(tokenHash: id, decimals: self.selectedAsset!.decimals, assetName: selectedAsset.name, amount: selectedAmount, toAddress: sendToAddress)
        } else if self.selectedAsset?.assetType == .ontologyAsset {
            self.sendOntology(assetSymbol: selectedAsset.symbol, amount: selectedAmount, toAddress: sendToAddress)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToTransactionComplete" {
            guard let dest = segue.destination as? SendCompleteViewController else {
                fatalError("Undefined segue behavior")
            }
            dest.transactionSucceeded = self.transactionCompleted
            dest.toSendAddress = self.sendToAddress
            dest.transactionId = self.txId
            
        }
    }
    
    func addThemedElements() {
        contentView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        let themedLabels = [sendReviewTitleLabel, sendWhatLabel, sendToAddressLabel, feeLabel, feeAmountLabel]
        for label in themedLabels {
            label?.theme_textColor = O3Theme.titleColorPicker
        }
    }
    
    func setLocalizedStrings() {
        sendReviewTitleLabel.text = SendStrings.sendReviewTitle
        feeLabel.text = SendStrings.sendReviewFee
        sendButton.setTitle(SendStrings.send, for: UIControl.State())
    }
}
