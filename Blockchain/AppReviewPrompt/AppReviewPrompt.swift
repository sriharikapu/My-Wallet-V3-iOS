//
//  AppReviewPrompt.swift
//  Blockchain
//
//  Created by Maurice A. on 6/29/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import StoreKit

/**
 App Review Prompt
 Used to prompt the user to review the application.
 */
@objc
final class AppReviewPrompt: NSObject {

    // MARK: - Properties

    private let numberOfTransactionsBeforePrompt = 3

    static let shared = AppReviewPrompt()

    @objc class func sharedInstance() -> AppReviewPrompt {
        return AppReviewPrompt.shared
    }

    override private init() {
        super.init()
    }

    /// Ask to show the prompt, else handle failure silently
    @objc func showIfNeeded() {
        let transactionsCount = WalletManager.shared.wallet.getAllTransactionsCount()
        if transactionsCount < numberOfTransactionsBeforePrompt {
            Logger.shared.info("App review prompt will not show because the user needs at least \(numberOfTransactionsBeforePrompt) transactions.")
            return
        }
        // TODO: support overriding appBecameActiveCount for debugging
        let count = BlockchainSettings.App.shared.appBecameActiveCount
        switch count {
        case 10, 50,
             _ where (count >= 100) && (count % 100 == 0),
             _ where transactionsCount == numberOfTransactionsBeforePrompt: requestReview()
        default:
            Logger.shared.info("App review prompt will not show because the application open count is too low (\(count)).")
            return
        }
    }

    private func requestReview() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
            return
        }
        let settings = BlockchainSettings.App.shared
        if settings.dontAskUserToShowAppReviewPrompt {
            Logger.shared.info("App review prompt will not show because the user does not want to be asked.")
            return
        }
        let affirmativeAction = UIAlertAction(
            title: LocalizationConstants.AppReviewFallbackPrompt.affirmativeActionTitle,
            style: .default,
            handler: { _ in
                settings.dontAskUserToShowAppReviewPrompt = true
                UIApplication.shared.rateApp()
        })
        let secondaryAction = UIAlertAction(
            title: LocalizationConstants.AppReviewFallbackPrompt.secondaryActionTitle,
            style: .cancel,
            handler: nil)
        let tertiaryAction = UIAlertAction(title: LocalizationConstants.dontShowAgain, style: .cancel, handler: { _ in
            settings.dontAskUserToShowAppReviewPrompt = true
        })
        AlertViewPresenter.shared.standardNotify(
            message: LocalizationConstants.AppReviewFallbackPrompt.message,
            title: LocalizationConstants.AppReviewFallbackPrompt.title,
            actions: [affirmativeAction, secondaryAction, tertiaryAction]
        )
    }
}
