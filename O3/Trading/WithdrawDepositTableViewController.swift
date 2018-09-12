//
//  WithdrawDepositTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 9/11/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import PKHUD

protocol WithdrawDepositTableViewControllerDelegate {
    func didFinishAction(action: WithdrawDepositTableViewController.Action)
}

class WithdrawDepositTableViewController: UITableViewController {
    
    enum Action: Int {
        case Withdraw = 0
        case Deposit
    }
    
    struct ActionAsset {
        var assetSymbol: String
        var amount: String
        var decimals: Int
        var action: Action
    }
    
    var withdrawableAsset: [TradableAsset]?
    var depositableAssets: [TradableAsset]? = []
    var selectedAsset: TradableAsset?
    var delegate: WithdrawDepositTableViewControllerDelegate?
    
    var selectedAction: Action? {
        didSet{
            self.title = selectedAction == Action.Deposit ? "Deposit" : "Withdraw"
        }
    }
    
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var assetIconImageView: UIImageView!
    @IBOutlet var assetSymbolLabel: UILabel!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var footerLabel: UILabel!
    @IBOutlet var confirmButton: UIButton?
    var inputToolbar = AssetInputToolbar()
    
    func setupView() {
        if selectedAction == Action.Deposit {
            headerLabel.text = "Enter the amount of tokens you wish to deposit to your trading account for fast trading."
            footerLabel.text = "Deposits will take about 30 seconds to confirm."
        } else {
            headerLabel.text = "Enter the amount of tokens you wish to withdraw from your trading account to your wallet."
            footerLabel.text = "Withdrawals will take about 60 seconds to confirm."
        }
        
        self.amountTextField.addTarget(self, action: #selector(amountTextChanged(_:)), for: .editingChanged)
        
        
        //when deposit we need to figure out what Switcheo supported and only show those
        if selectedAction == Action.Deposit {
            
            //append two native assets
            if O3Cache.neo().value > 0 {
                depositableAssets?.append(O3Cache.neo().toTradableAsset())
            }
            if O3Cache.gas().value > 0 {
                depositableAssets?.append(O3Cache.gas().toTradableAsset())
            }
            
            
            Switcheo(net: AppState.network == Network.main ? Switcheo.Net.Main : Switcheo.Net.Test)?.exchangeTokens(completion: { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let response):
                    for token in O3Cache.tokenAssets() {
                        if response[token.symbol.uppercased()] != nil {
                            self.depositableAssets?.append(token.toTradableAsset())
                        }
                    }
                }
            })
            
            //default to first one in the list
            selectedAsset = depositableAssets?.first
        }else if selectedAsset == nil && selectedAction == Action.Withdraw && withdrawableAsset != nil && (withdrawableAsset?.count)! > 0 {
            selectedAsset = withdrawableAsset?.first
        }
        
        
        if selectedAsset != nil {
            setupSelectedAsset(asset: selectedAsset!)
        }
        
        self.confirmButton?.setTitle(selectedAction == Action.Deposit ? "Deposit" : "Withdraw", for: .normal)
        self.checkEnableButton()
    }
    
    func setupSelectedAsset(asset: TradableAsset) {
        
        assetSymbolLabel.text = asset.symbol
        let imageURL = String(format: "https://cdn.o3.network/img/neo/%@.png", asset.symbol.uppercased())
        assetIconImageView.kf.setImage(with: URL(string: imageURL))
        
        inputToolbar.delegate = self
        amountTextField.inputAccessoryView = inputToolbar.loadNib()
        amountTextField.inputAccessoryView?.theme_backgroundColor = O3Theme.backgroundColorPicker
        
        inputToolbar.asset = TransferableAsset(id: asset.id, name: asset.name, symbol: asset.symbol, decimals: asset.decimals, value: asset.amountInDouble(), assetType: AccountState.TransferableAsset.AssetType.nep5Token)
        
        amountTextField.becomeFirstResponder()
    }
    
    @objc func amountTextChanged(_ sender: Any) {
        self.checkEnableButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.hideHairline()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(dismiss(_: )))
        setupView()
    }
    
    @objc func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    
    @IBAction func didTapSelectAsset(_ sender: Any) {
        guard let nav = UIStoryboard(name: "Trading", bundle: nil).instantiateViewController(withIdentifier: "TradableAssetSelectorTableViewControllerNav") as? UINavigationController else {
            return
        }
        guard let modal = nav.viewControllers.first as? TradableAssetSelectorTableViewController else {
            return
        }
        if selectedAction == Action.Withdraw {
            modal.assets = withdrawableAsset
        } else {
            modal.assets = depositableAssets
        }
        
        modal.delegate = self
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: nav)
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(nav, animated: true, completion: nil)
    }
    
    func checkEnableButton() {
        if self.amountTextField.text?.count == 0 {
            confirmButton?.isEnabled = false
            return
        }
        let valueDecimal = NSDecimalNumber(string: (self.amountTextField.text?.trim())!)
        let value = valueDecimal.doubleValue
        if value == 0 {
            self.confirmButton?.isEnabled = false
            return
        }
        
        if value.precised(selectedAsset!.decimals) > self.selectedAsset!.amountInDouble().precised(selectedAsset!.decimals) {
            DispatchQueue.main.async {
                self.amountTextField.shakeToShowError()
            }
            self.confirmButton?.isEnabled = false
            return
        }
        
        confirmButton?.isEnabled = selectedAsset != nil && (amountTextField.text?.count)! > 0
    }
    
    
    func withdraw(amount: Double) {
        let blockchain = "neo"
        let assetID = selectedAsset!.symbol
        let switcheoHash = "91b83e96f2a7c4fdf0c1688441ec61986c7cae26" //mainnet v2
        let request = RequestTransaction(blockchain: blockchain, assetID: assetID, amount: amount, contractHash: switcheoHash)
        let switcheoAccount = SwitcheoAccount(network: AppState.network == Network.main ? Switcheo.Net.Main : Switcheo.Net.Test, account: Authenticated.account!)
        switcheoAccount.withdrawal(requestTransaction: request!, completion: {result in
            switch result {
            case .failure(let error):
                print(error)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    HUD.hide()
                    HUD.flash(HUDContentType.labeledError(title: "Cannot withdraw", subtitle: "Please try again later."), delay: 3)
                }
            case .success(let response):
                DispatchQueue.main.async {
                    #if DEBUG
                    print(response)
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        HUD.hide()
                        self.dismiss(animated: true, completion: {
                            self.delegate?.didFinishAction(action: Action.Withdraw)
                        })
                    }
                }
            }
        })
    }
    
    func deposit(amount: Double) {
        let blockchain = "neo"
        let assetID = selectedAsset!.symbol
        let switcheoHash = "91b83e96f2a7c4fdf0c1688441ec61986c7cae26" //mainnet v2
        let request = RequestTransaction(blockchain: blockchain, assetID: assetID, amount: amount, contractHash: switcheoHash)
        let switcheoAccount = SwitcheoAccount(network: AppState.network == Network.main ? Switcheo.Net.Main : Switcheo.Net.Test, account: Authenticated.account!)
        switcheoAccount.deposit(requestTransaction: request!) { result in
            switch result {
            case .failure(_):
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    HUD.hide()
                    HUD.flash(HUDContentType.labeledError(title: "Cannot deposit", subtitle: "Please try again later."), delay: 3)
                }
            case .success(let response):
                DispatchQueue.main.async {
                    #if DEBUG
                    print(response)
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        HUD.hide()
                        self.dismiss(animated: true, completion: {
                            self.delegate?.didFinishAction(action: Action.Withdraw)
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func didTapConfirm(_ sender: Any) {
        
        let amountFormatter = NumberFormatter()
        amountFormatter.minimumFractionDigits = 0
        amountFormatter.maximumFractionDigits = self.selectedAsset!.decimals
        amountFormatter.numberStyle = .decimal
        
        let amount = amountFormatter.number(from: (amountTextField.text?.trim())!)
        
        if amount == nil {
            return
        }
        DispatchQueue.main.async {
            self.amountTextField.resignFirstResponder()
            HUD.show(.labeledProgress(title: nil, subtitle: ""))
        }
        if selectedAction == Action.Withdraw {
            self.withdraw(amount: amount!.doubleValue)
        } else {
            self.deposit(amount: amount!.doubleValue)
        }
    }
}

extension WithdrawDepositTableViewController: AssetInputToolbarDelegate {
    func percentAmountTapped(value: Double) {
        if value == 0 {
            return
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = selectedAsset!.decimals
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        let balanceString = formatter.string(for: value)
        amountTextField.text = balanceString
        self.checkEnableButton()
    }
    
    func maxAmountTapped(value: Double) {
        if value == 0 {
            return
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = selectedAsset!.decimals
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        let balanceString = formatter.string(for: value)
        amountTextField.text = balanceString
        self.checkEnableButton()
    }
    
}

extension WithdrawDepositTableViewController: TradableAssetSelectorTableViewControllerDelegate {
    func assetSelected(selected: TradableAsset) {
        selectedAsset = selected
        setupSelectedAsset(asset: selectedAsset!)
    }
}
