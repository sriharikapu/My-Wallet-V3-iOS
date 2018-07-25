//
//  AssetAddressRepository.swift
//  Blockchain
//
//  Created by Chris Arriola on 5/22/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

/// Repository for asset addresses
@objc class AssetAddressRepository: NSObject {

    static let shared = AssetAddressRepository()

    /// Accessor for obj-c compatibility
    @objc class func sharedInstance() -> AssetAddressRepository { return shared }

    private let walletManager: WalletManager

    init(walletManager: WalletManager = WalletManager.shared) {
        self.walletManager = walletManager
        super.init()
        self.walletManager.swipeAddressDelegate = self
    }

    // TODO: move latest multiaddress response here

    /// Fetches the swipe to receive addresses for all assets if possible
    func fetchSwipeToReceiveAddressesIfNeeded() {

        // Perform guard checks
        let appSettings = BlockchainSettings.App.shared
        guard appSettings.swipeToReceiveEnabled else {
            Logger.shared.info("Swipe to receive is disabled.")
            return
        }

        let wallet = walletManager.wallet

        guard wallet.isInitialized() else {
            Logger.shared.warning("Wallet is not yet initialized.")
            return
        }

        guard wallet.didUpgradeToHd() else {
            Logger.shared.warning("Wallet has not yet been upgraded to HD.")
            return
        }

        // Only one address for ethereum
        appSettings.swipeAddressForEther = wallet.getEtherAddress()

        // Retrieve swipe addresses for bitcoin and bitcoin cash
        let assetTypesWithHDAddresses = [AssetType.bitcoin, AssetType.bitcoinCash]
        assetTypesWithHDAddresses.forEach {
            let swipeAddresses = swipeToReceiveAddresses(for: $0)
            let numberOfAddressesToDerive = Constants.Wallet.swipeToReceiveAddressCount - swipeAddresses.count
            if numberOfAddressesToDerive > 0 {
                wallet.getSwipeAddresses(Int32(numberOfAddressesToDerive), assetType: $0.legacy)
            }
        }
    }

    /// Gets the swipe addresses for the provided asset type
    ///
    /// - Parameter assetType: the AssetType
    /// - Returns: the swipe addresses
    @objc func swipeToReceiveAddresses(for assetType: AssetType) -> [AssetAddress] {
        if assetType == .ethereum {
            guard let swipeAddressForEther = BlockchainSettings.App.shared.swipeAddressForEther else {
                return []
            }
            return [EthereumAddress(string: swipeAddressForEther)]
        }

        let swipeAddresses = KeychainItemWrapper.getSwipeAddresses(for: assetType.legacy) as? [String] ?? []
        return AssetAddressFactory.create(fromAddressStringArray: swipeAddresses, assetType: assetType)
    }

    /// Removes the first swipe address for assetType.
    ///
    /// - Parameter assetType: the AssetType
    @objc func removeFirstSwipeAddress(for assetType: AssetType) {
        KeychainItemWrapper.removeFirstSwipeAddress(for: assetType.legacy)
    }

    /// Removes all swipe addresses for all assets
    @objc func removeAllSwipeAddresses() {
        KeychainItemWrapper.removeAllSwipeAddresses()
    }

    /// removes all swipe addresses for the provided AssetType
    ///
    /// - Parameter assetType: the AssetType
    @objc func removeAllSwipeAddresses(for assetType: AssetType) {
        KeychainItemWrapper.removeAllSwipeAddresses(for: assetType.legacy)
    }
}

extension AssetAddressRepository: WalletSwipeAddressDelegate {
    func onRetrievedSwipeToReceive(addresses: [String], assetType: AssetType) {
        addresses.forEach {
            KeychainItemWrapper.addSwipeAddress($0, assetType: assetType.legacy)
        }
    }
}

extension AssetAddressRepository {
    /// Checks whether an address has been used (has ever had a transaction)
    ///
    /// - Parameters:
    ///   - address: address to be checked with network request
    ///   - displayAddress: address to be shown to the user in text and in QR code
    /// (usually the same as address unless checking for corresponding BTC address for BCH
    ///   - assetType: asset type for the address. Currently only supports BTC and BCH.
    ///   - successHandler: success handler to do something with the display address and whether the address has ever had a transaction
    ///   - errorHandler: error handler
    @objc func checkForUnusedAddress(
        _ address: String,
        displayAddress: String,
        assetType: AssetType,
        successHandler: @escaping ((_ displayAddress: String, _ isUnused: Bool) -> Void),
        errorHandler: @escaping (() -> Void)
    ) {
        guard assetType != .ethereum else {
            Logger.shared.info("Ethereum addresses not supported for checking if it is unused.")
            return
        }

        var assetAddress = AssetAddressFactory.create(fromAddressString: address, assetType: assetType)
        if let bchAddress = assetAddress as? BitcoinCashAddress,
            let transformedBtcAddress = bchAddress.toBitcoinAddress(wallet: walletManager.wallet) {
            assetAddress = transformedBtcAddress
        }

        guard let urlString = BlockchainAPI.shared.assetInfoURL(for: assetAddress), let url = URL(string: urlString) else {
            Logger.shared.warning("Cannot construct URL to check if the address '\(address)' is unused.")
            return
        }

        NetworkManager.shared.session.sessionDescription = url.host
        let task = NetworkManager.shared.session.dataTask(with: url, completionHandler: { data, _, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    errorHandler()
                }
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: AnyObject],
                let transactions = json!["txs"] as? [NSDictionary] else {
                    // TODO: call error handler
                    return
            }
            DispatchQueue.main.async {
                let isUnused = transactions.count == 0
                successHandler(displayAddress, isUnused)
            }
        })
        task.resume()
    }
}
