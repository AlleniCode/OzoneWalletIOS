//
//  TokenSalesList.swift
//  O3
//
//  Created by Andrei Terentiev on 4/12/18.
//  Copyright © 2018 drei. All rights reserved.
//

import Foundation
import UIKit
import WebBrowser

class TokenSalesListTableViewController: UITableViewController {
    var tokenSales: TokenSales?
    @IBOutlet var subscribeButton: UIButton?
    @IBOutlet weak var getNotifiedTitleLabel: UILabel!
    @IBOutlet weak var getNotifiedDescriptionLabel: UILabel!

    func setupNavigationBar() {
        self.navigationController?.hideHairline()
    }

    func setThemedElements() {
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        view.theme_backgroundColor = O3Theme.backgroundColorPicker
    }

    @objc func loadTokenSales() {
        DispatchQueue.global().async {
            O3Client().getTokenSales(address: (Authenticated.wallet?.address)!) { result in
                DispatchQueue.main.async { self.refreshControl?.endRefreshing() }
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
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setupNavigationBar()
        setThemedElements()

        //this to avoid double call in cellForRow
        //assign datasource and delegate only when data is loaded
        self.tableView.delegate = nil
        self.tableView.dataSource = nil
        loadTokenSales()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(loadTokenSales), for: .valueChanged)
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

    @IBAction func subscribeButtonTapped(_ sender: Any) {
        if tokenSales?.subscribeURL == nil {
            return
        }
        let webBrowserViewController = WebBrowserViewController()
        webBrowserViewController.tintColor = Theme.light.primaryColor
        webBrowserViewController.loadURLString(tokenSales!.subscribeURL)
        let navigationWebBrowser = WebBrowserViewController.rootNavigationWebBrowser(webBrowser: webBrowserViewController)
        present(navigationWebBrowser, animated: true, completion: nil)
    }

    @IBAction func tappedLeftBarButtonItem(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 190.0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokenSales?.live.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "tokenSaleTableViewCell") as? TokenSaleTableViewCell,
            let sale = tokenSales?.live[indexPath.row] else {
                return UITableViewCell(frame: CGRect.zero)
        }
        let data = TokenSaleTableViewCell.TokenSaleData(imageURL: sale.squareLogoURL, name: sale.name, shortDescription: sale.shortDescription, time: sale.endTime)
        cell.tokenSaleData = data
        cell.actionLabel.text = TokenSaleStrings.checkingStatus
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
        guard let dest = segue.destination as? UINavigationController else {
            return
        }
        if segue.identifier == "segueToTokenSale" {
            if let vc = dest.viewControllers.first as? TokenSaleTableViewController {
                let selectedSale = sender as? TokenSales.SaleInfo
                vc.saleInfo = selectedSale
            }
        }
    }

    // MARK: 
    func checkWhitelisted(sale: TokenSales.SaleInfo, indexPath: IndexPath) {
        DispatchQueue.main.async {
            guard let cell = self.tableView.cellForRow(at: indexPath) as? TokenSaleTableViewCell else {
                return
            }
            if sale.kycStatus.verified {
                cell.actionLabel.text = TokenSaleStrings.participate
                cell.actionLabel.theme_textColor = O3Theme.primaryColorPicker
            } else {
                cell.actionLabel.text = TokenSaleStrings.notWhitelisted
                cell.actionLabel.theme_textColor = O3Theme.disabledColorPicker
            }
        }
    }

    func setLocalizedStrings() {
        self.navigationItem.title = TokenSaleStrings.tokenSalesTitle
        getNotifiedTitleLabel.text = TokenSaleStrings.getNotifiedTitle
        getNotifiedDescriptionLabel.text = TokenSaleStrings.getNotifiedDescription
        subscribeButton?.setTitle(TokenSaleStrings.subscribe, for: UIControl.State())

    }
}
