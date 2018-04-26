//
//  AvailableNEP5TokensTableViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 1/22/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit
import Crashlytics

class AvailableNEP5TokensTableViewController: UITableViewController {

    var tokens: [NEP5Token]! = []
    func loadTokens() {
        //default is mainnet
        var request = NSMutableURLRequest(url: URL(string: "https://o3.network/settings/nep5.json")!)

        #if TESTNET
             request = NSMutableURLRequest(url: URL(string: "https://o3.network/settings/nep5.test.json")!)
        #endif
        #if PRIVATENET
             request = NSMutableURLRequest(url: URL(string: "https://s3-ap-northeast-1.amazonaws.com/network.o3.cdn/data/nep5.private.json")!)
        #endif

        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, _, err) in
            if err != nil {
                return
            }

            guard let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? JSONDictionary else {
                return
            }
            let decoder = JSONDecoder()
            guard let data = try? JSONSerialization.data(withJSONObject: json!["nep5tokens"]!, options: .prettyPrinted),
                let list = try? decoder.decode([NEP5Token].self, from: data) else {
                    return
            }
            self.tokens = list
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        task.resume()

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        applyNavBarTheme()
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        tableView.theme_separatorColor = O3Theme.tableSeparatorColorPicker
        self.title = NSLocalizedString("NEP5 Tokens", comment: "")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Done bar button item"), style: .done, target: self, action: #selector(doneTapped(_:)))
        self.loadTokens()
    }

    @objc func doneTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokens.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? NEP5TokenSelectorTableViewCell else {
            let cell =  UITableViewCell()
            cell.theme_backgroundColor = O3Theme.backgroundColorPicker
            return cell
        }
        let token = tokens[indexPath.row]
        cell.titleLabel.text = token.symbol
        cell.subtitleLabel.text = token.name

        if (UserDefaultsManager.selectedNEP5Token![token.tokenHash]) != nil {
            cell.accessoryType = .checkmark
            cell.setSelected(true, animated: false)
        } else {
            cell.setSelected(false, animated: false)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? NEP5TokenSelectorTableViewCell  else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        let token = tokens[indexPath.row]
        if UserDefaultsManager.selectedNEP5Token![token.tokenHash] != nil {
            UserDefaultsManager.selectedNEP5Token?.removeValue(forKey: token.tokenHash)
            NotificationCenter.default.post(name: Notification.Name("AddedNewToken"), object: nil)
            Answers.logCustomEvent(withName: "Added New Token",
                                   customAttributes: ["Token Name": token.name,
                                                      "Num Tokens": UserDefaultsManager.selectedNEP5Token?.keys.count,
                                                      "Which Tokens": UserDefaultsManager.selectedNEP5Token?.description])
            cell.accessoryType = .none
        } else {
            UserDefaultsManager.selectedNEP5Token![token.tokenHash] = token
            NotificationCenter.default.post(name: Notification.Name("AddedNewToken"), object: nil)
            Answers.logCustomEvent(withName: "Removed Token",
                                   customAttributes: ["Token Name": token.name,
                                                      "Num Tokens": UserDefaultsManager.selectedNEP5Token?.keys.count,
                                                      "Which Tokens": UserDefaultsManager.selectedNEP5Token?.description])
            cell.accessoryType = .checkmark

        }
    }
}
