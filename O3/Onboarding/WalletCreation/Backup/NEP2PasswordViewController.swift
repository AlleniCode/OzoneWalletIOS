//
//  NEP2PasswordViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/6/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class NEP2PasswordViewController: UITableViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var showButton: UIButton!
    var wif = ""

    lazy var inputToolbar: UIToolbar = {
        var toolbar = UIToolbar(frame: CGRect.zero)
        toolbar.barStyle = .default
        toolbar.barTintColor = .white
        toolbar.isTranslucent = true
        toolbar.sizeToFit()

        let flexibleButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: Theme.light.primaryColor,
                                                         NSAttributedString.Key.font: UIFont(name: "Avenir-Medium", size: 17)!]
        let disabledAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: Theme.light.disabledColor,
                                                                 NSAttributedString.Key.font: UIFont(name: "Avenir-Medium", size: 17)!]
        doneButton.setTitleTextAttributes(attributes, for: UIControl.State.normal)
        doneButton.setTitleTextAttributes(disabledAttributes, for: UIControl.State.disabled)

        toolbar.setItems([flexibleButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true

        return toolbar
    }()

    var passwordIsSecure = true
    var doneButton = UIBarButtonItem(title: OnboardingStrings.continueButton, style: .plain, target: self, action: #selector(continueTapped(_:)))

    var allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.~`!@#$%^&*()+=-/;:\"\'{}[]<>^?,")

    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.isEnabled = false
        passwordTextField.inputAccessoryView = inputToolbar
        passwordTextField.setLeftPaddingPoints(CGFloat(10.0))
        passwordTextField.setRightPaddingPoints(CGFloat(10.0))
        passwordTextField.becomeFirstResponder()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        setLocalizedStrings()
    }

    @IBAction func continueTapped(_ sender: Any) {
        if validatePassword() {
            self.performSegue(withIdentifier: "segueToConfirmPassword", sender: nil)
        } else {
            OzoneAlert.alertDialog(message: OnboardingStrings.invalidPasswordLength, dismissTitle: OzoneAlert.okPositiveConfirmString) {
                self.passwordTextField.text = ""
            }
        }
    }

    func validatePassword() -> Bool {
        let passwordText = passwordTextField.text?.trim() ?? ""
        if !(passwordText.count >= 8) {
            return false
        }

        if passwordText.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            return false
        }

        return true
    }

    @IBAction func showButtonTapped(_ sender: Any) {
        passwordIsSecure = !passwordIsSecure
        passwordTextField.isSecureTextEntry = passwordIsSecure
        let tmp = passwordTextField.text
        passwordTextField.text = ""
        passwordTextField.text = tmp
        if passwordIsSecure {
            showButton.alpha = CGFloat(0.3)
        } else {
            showButton.alpha = CGFloat(1.0)
        }
    }

    @IBAction func textfieldChanged(_ sender: Any) {
        if passwordTextField.text == "" {
            doneButton.isEnabled = false
        } else {
            doneButton.isEnabled = true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? NEP2PasswordConfirmViewController else {
            fatalError("Unknown segue has been triggered")
        }
        dest.previousPassword = passwordTextField.text?.trim()
        dest.wif = wif
    }

    func setLocalizedStrings() {
        title = OnboardingStrings.createPassword
        descriptionLabel.text = OnboardingStrings.createPasswordDescription
        passwordTextField.placeholder = OnboardingStrings.createPasswordHint
    }
}
