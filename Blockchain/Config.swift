//
//  Config.swift
//  Blockchain
//
//  Created by Maurice A. on 3/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

@objc
extension Bundle {
    static var apiUrl: String? {
        guard let host = Bundle.main.infoDictionary!["API_URL"] as? String else {
            return nil
        }
        return "https://\(host)"
    }
    static var walletUrl: String? {
        guard let host = Bundle.main.infoDictionary!["WALLET_SERVER"] as? String else {
            return nil
        }
        return "https://\(host)"
    }
    static var webSocketUri: String? {
        guard let hostAndPath = Bundle.main.infoDictionary!["WEBSOCKET_SERVER"] as? String else {
            return nil
        }
        return "wss://\(hostAndPath)"
    }
    static var ethereumWebSocketUri: String? {
        guard let hostAndPath = Bundle.main.infoDictionary!["WEBSOCKET_SERVER_ETH"] as? String else {
            return nil
        }
        return "wss://\(hostAndPath)"
    }
    static var bitcoinCashWebSocketUri: String? {
        guard let hostAndPath = Bundle.main.infoDictionary!["WEBSOCKET_SERVER_BCH"] as? String else {
            return nil
        }
        return "wss://\(hostAndPath)"
    }
    static var buyWebViewUrl: String? {
        guard let hostAndPath = Bundle.main.infoDictionary!["BUY_WEBVIEW_URL"] as? String else {
            return nil
        }
        return "https://\(hostAndPath)"
    }
    static var localCertificatePath: String? {
        guard let certificateFile = Bundle.main.infoDictionary!["LOCAL_CERTIFICATE_FILE"] as? String else {
            return nil
        }
        guard let path = Bundle.main.path(forResource: certificateFile, ofType: "der", inDirectory: "Cert") else {
            return nil
        }
        return path
    }
}
