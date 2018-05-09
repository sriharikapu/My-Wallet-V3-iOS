//
//  WalletTradeDelegate.swift
//  Blockchain
//
//  Created by kevinwu on 5/8/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

protocol WalletTradeDelegate: class {

    /// Method invoked when trade initiated from buy is completed
    func didCompleteTrade(trade: [String: String?])

    /// Method invoked when a user requests from inside the web view to see trade details
    func showCompletedTrade(tradeHash: String)
}
