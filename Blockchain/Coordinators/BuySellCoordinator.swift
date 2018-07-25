//
//  BuySellCoordinator.swift
//  Blockchain
//
//  Created by kevinwu on 6/6/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import RxSwift

@objc class BuySellCoordinator: NSObject, Coordinator {
    static let shared = BuySellCoordinator()

    @objc private(set) var buyBitcoinViewController: BuyBitcoinViewController?

    private let walletManager: WalletManager

    private let walletService: WalletService

    private var disposable: Disposable?

    // class function declared so that the BuySellCoordinator singleton can be accessed from obj-C
    @objc class func sharedInstance() -> BuySellCoordinator {
        return BuySellCoordinator.shared
    }

    private init(
        walletManager: WalletManager = WalletManager.shared,
        walletService: WalletService = WalletService.shared
    ) {
        self.walletManager = walletManager
        self.walletService = walletService
        super.init()
        self.walletManager.buySellDelegate = self
    }

    func start() {
        disposable = walletService.walletOptions
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { walletOptions in
                guard let rootURL = walletOptions.mobile?.walletRoot else {
                    Logger.shared.warning("Error with wallet options response when starting buy sell webview")
                    return
                }
                self.initializeWebView(rootURL: rootURL)
            }, onError: { _ in
                Logger.shared.error("Error getting wallet options to start buy sell webview")
            })
    }

    private func initializeWebView(rootURL: String?) {
        buyBitcoinViewController = BuyBitcoinViewController(rootURL: rootURL)
    }

    @objc func showBuyBitcoinView() {
        guard let buyBitcoinViewController = buyBitcoinViewController else {
            Logger.shared.warning("buyBitcoinViewController not yet initialized")
            return
        }

        // TODO convert this dictionary into a model
        guard let loginDataDict = walletManager.wallet.executeJSSynchronous(
            "MyWalletPhone.getWebViewLoginData()"
            ).toDictionary() else {
                Logger.shared.warning("loginData from wallet is empty")
                return
        }

        guard let walletJson = loginDataDict["walletJson"] as? String else {
            Logger.shared.warning("walletJson is nil")
            return
        }

        guard let externalJson = loginDataDict["externalJson"] is NSNull ? "" : loginDataDict["externalJson"] as? String else {
            Logger.shared.warning("externalJson is nil")
            return
        }

        guard let magicHash = loginDataDict["magicHash"] is NSNull ? "" : loginDataDict["magicHash"] as? String else {
            Logger.shared.warning("magicHash is nil")
            return
        }

        buyBitcoinViewController.login(
            withJson: walletJson,
            externalJson: externalJson,
            magicHash: magicHash,
            password: walletManager.wallet.password
        )
        buyBitcoinViewController.delegate = walletManager.wallet // TODO fix this

        guard let navigationController = BuyBitcoinNavigationController(
            rootViewController: buyBitcoinViewController,
            title: LocalizationConstants.SideMenu.buySellBitcoin
            ) else {
                return
        }

        UIApplication.shared.keyWindow?.rootViewController?.topMostViewController?.present(
            navigationController,
            animated: true
        )
    }
}

extension BuySellCoordinator: WalletBuySellDelegate {
    func didCompleteTrade(trade: Trade) {
        let actions = [UIAlertAction(title: LocalizationConstants.okString, style: .cancel, handler: nil),
                       UIAlertAction(title: LocalizationConstants.BuySell.viewDetails, style: .default, handler: { _ in
                        AppCoordinator.shared.tabControllerManager.showTransactionDetail(forHash: trade.hash)
                       })]
        AlertViewPresenter.shared.standardNotify(message: String(format: LocalizationConstants.BuySell.tradeCompletedDetailArg, trade.date),
                                                 title: LocalizationConstants.BuySell.tradeCompleted,
                                                 actions: actions)
    }

    func showCompletedTrade(tradeHash: String) {
        AppCoordinator.shared.closeSideMenu()
        AppCoordinator.shared.tabControllerManager.showTransactions(animated: true)
        AppCoordinator.shared.tabControllerManager.showTransactionDetail(forHash: tradeHash)
    }
}
