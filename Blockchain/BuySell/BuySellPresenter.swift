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

    func didCompleteTrade(trade: Trade) {
        let alert = UIAlertController(title: LocalizationConstants.BuySell.tradeCompleted,
                                      message: String(format: LocalizationConstants.BuySell.tradeCompletedDetailArg, trade.date),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizationConstants.okString, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: LocalizationConstants.BuySell.viewDetails, style: .default, handler: { _ in
            AppCoordinator.shared.tabControllerManager.showTransactionDetail(forHash: trade.hash)
        }))
        UIApplication.shared.keyWindow?.rootViewController?.topMostViewController?.present(alert, animated: true, completion: nil)
    }

    func showCompletedTrade(tradeHash: String) {
        AppCoordinator.shared.closeSideMenu()
        AppCoordinator.shared.tabControllerManager.showTransactions(animated: true)
        AppCoordinator.shared.tabControllerManager.showTransactionDetail(forHash: tradeHash)
    }
}
