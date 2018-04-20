//
//  TokenSalesList.swift
//  O3
//
//  Created by Andrei Terentiev on 4/12/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import UIKit
import NeoSwift

class TokenSalesListTableViewController: UITableViewController {
    var tokenSales: TokenSales?
    func setupNavigationBar() {
        self.navigationController?.hideHairline()
        self.navigationItem.title = "Token Sales"
    }
    
    func setThemedElements() {
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setThemedElements()
        
        #if PRIVATENET
        UserDefaultsManager.seed = "http://localhost:30333"
        UserDefaultsManager.useDefaultSeed = false
        UserDefaultsManager.network = .privateNet
        Authenticated.account?.neoClient = NeoClient(network: .privateNet)
        #endif
        
        //this to avoid double call in cellForRow
        //assign datasource and delegate only when data is loaded
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        O3Client().getTokenSales { result in
            switch result {
            case .failure:
                return
            case .success(let tokenSales):
                self.tokenSales = tokenSales
                DispatchQueue.main.async {
                    self.tableView.delegate = self
                    self.tableView.dataSource = self
                    self.tableView.reloadData()
                }
            }
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(tappedLeftBarButtonItem(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //this will remove a title to the back button in the pushed view
        self.title = ""
    }
    
    @IBAction func tappedLeftBarButtonItem(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 182.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokenSales?.live.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "tokenSaleTableViewCell") as? TokenSaleTableViewCell,
            let sale = tokenSales?.live[indexPath.row] else {
                return UITableViewCell()
        }
        let data = TokenSaleTableViewCell.TokenSaleData(imageURL: sale.squareLogoURL, name: sale.name,shortDescription: sale.shortDescription, time: sale.endTime)
        cell.tokenSaleData = data
        cell.actionLabel.text = "Checking status..."
        checkWhitelisted(sale: sale, indexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedSale = tokenSales?.live[indexPath.row] else {
            return
        }
        //allow user to go into sale page to see what it's like in there but disable participate button
        self.performSegue(withIdentifier: "segueToTokenSale", sender: selectedSale)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? TokenSaleTableViewController else {
            return
        }
        if segue.identifier == "segueToTokenSale" {
            let selectedSale = sender as? TokenSales.SaleInfo
            dest.saleInfo = selectedSale
        }
    }
    
    //mark: -
    func checkWhitelisted(sale: TokenSales.SaleInfo, indexPath: IndexPath) {
        DispatchQueue.main.async {
            
            guard let cell = self.tableView.cellForRow(at: indexPath) as? TokenSaleTableViewCell else {
                return
            }
            Authenticated.account?.allowToParticipateInTokenSale(scriptHash: sale.scriptHash, completion: { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .failure:
                        cell.actionLabel.text = "not whitelisted"
                        cell.actionLabel.theme_textColor = O3Theme.disabledColorPicker
                        self.tokenSales?.live[indexPath.row].allowToParticipate = false
                    case .success(let whitelisted):
                        self.tokenSales?.live[indexPath.row].allowToParticipate = whitelisted
                        if whitelisted == true {
                            cell.actionLabel.text = "Participate"
                            cell.actionLabel.theme_textColor = O3Theme.primaryColorPicker
                        } else {
                            cell.actionLabel.text = "Not whitelisted"
                            cell.actionLabel.theme_textColor = O3Theme.disabledColorPicker
                        }
                    }
                }
            })
        }
    }
}