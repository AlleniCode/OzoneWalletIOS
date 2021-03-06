//
//  WalletGeneratedViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 6/8/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class WalletGeneratedViewController: UIViewController {
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var alertContainer: UIView!
    @IBOutlet weak var animationContainer: UIView!

    let animationView = LOTAnimationView(name: "wallet_generated")

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        view.backgroundColor = UIColor.clear
        view.isOpaque = false

        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = view.bounds
        view.addSubview(visualEffectView)
        view.bringSubviewToFront(alertContainer)
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(doneButtonTapped(_:))))
        animationContainer.embed(animationView)
        animationView.loopAnimation = true
        animationView.play()
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
        DispatchQueue.main.async { self.dismiss(animated: true, completion: nil) }
    }

    func setLocalizedStrings() {
        titleView.text = OnboardingStrings.walletGenerated
        subtitleLabel.text = OnboardingStrings.pleaseTakeAMoment
        doneButton.setTitle(OnboardingStrings.gotIt, for: UIControl.State())
    }

}
