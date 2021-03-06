//
//  WalletService.swift
//  Blockchain
//
//  Created by Chris Arriola on 5/31/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import RxSwift

/// Service that interacts with the Blockchain API
@objc class WalletService: NSObject {
    static let shared = WalletService()

    @objc class func sharedInstance() -> WalletService { return shared }

    private let networkManager: NetworkManager

    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }

    // MARK: - Public

    /// A Single returning the WalletOptions which contains dynamic flags for configuring the app.
    var walletOptions: Single<WalletOptions> {
        return networkManager.requestJsonOrString(
            BlockchainAPI.shared.walletOptionsUrl,
            method: .get
        ).map {
            guard $0.statusCode == 200 else {
                throw WalletServiceError.generic(message: nil)
            }
            guard let json = $1 as? JSON else {
                throw WalletServiceError.jsonParseError
            }
            return WalletOptions(json: json)
        }
    }

    /// Validates if the provided pin payload (i.e. pin code and pin key combination) is correct.
    ///
    /// - Parameter pinPayload: the PinPayload
    /// - Returns: an Single returning the response
    func validatePin(_ pinPayload: PinPayload) -> Single<GetPinResponse> {
        return pinStore(pinPayload: pinPayload, method: "get").map {
            guard let responseJson = $1 as? JSON else {
                let errorMessage = $1 as? String
                throw WalletServiceError.generic(message: errorMessage)
            }
            return GetPinResponse(response: responseJson)
        }
    }

    // MARK: - Private

    private func pinStore(
        pinPayload: PinPayload,
        method: String,
        value: String? = nil
    ) -> Single<(HTTPURLResponse, Any)> {
        var parameters = [
            "format": "json",
            "method": method,
            "pin": pinPayload.pinCode,
            "key": pinPayload.pinKey,
            "api_code": BlockchainAPI.Parameters.apiCode
        ]
        if let value = value {
            parameters[value] = value
        }
        return networkManager.requestJsonOrString(
            BlockchainAPI.shared.pinStore,
            method: .post,
            parameters: parameters
        )
    }
}
