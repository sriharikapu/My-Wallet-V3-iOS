//
//  BuySellPresenter.swift
//  Blockchain
//
//  Created by kevinwu on 5/8/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

final class BuySellPresenter: WalletTradeDelegate {

    static let shared = BuySellPresenter()
    // MARK: Initialization

    private let walletManager: WalletManager

    init(walletManager: WalletManager = WalletManager.shared) {
        self.walletManager = walletManager
        self.walletManager.tradeDelegate = self
    }

    func didCompleteTrade(trade: [String: String?]) {
        guard let date = trade[Constants.TradeKeys.created] as? String else {
            print("No trade date found")
            return
        }
        guard let hash = trade[Constants.TradeKeys.tradeHash] as? String else {
            print("No trade hash found")
            return
        }
        let alert = UIAlertController(title: LocalizationConstants.BuySell.tradeCompleted,
                                      message: String(format: LocalizationConstants.BuySell.tradeCompletedDetailArg, date),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizationConstants.okString, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: LocalizationConstants.BuySell.viewDetails, style: .default, handler: { _ in
            AppCoordinator.shared.tabControllerManager.showTransactionDetail(forHash: hash)
        }))
        UIApplication.shared.keyWindow?.rootViewController?.topMostViewController?.present(alert, animated: true, completion: nil)
    }

    func showCompletedTrade(tradeHash: String) {
        AppCoordinator.shared.closeSideMenu()
        AppCoordinator.shared.tabControllerManager.showTransactions(animated: true)
        AppCoordinator.shared.tabControllerManager.showTransactionDetail(forHash: tradeHash)
    }
}
