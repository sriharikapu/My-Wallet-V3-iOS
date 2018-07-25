//
//  WalletManager.swift
//  Blockchain
//
//  Created by Chris Arriola on 4/23/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import JavaScriptCore

/**
 Manager object for operations to the Blockchain Wallet.
 */
@objc
class WalletManager: NSObject {
    static let shared = WalletManager()

    @objc class func sharedInstance() -> WalletManager {
        return shared
    }

    // TODO: Replace this with asset-specific wallet architecture
    @objc let wallet: Wallet

    // TODO: make this private(set) once other methods in RootService have been migrated in here
    @objc var latestMultiAddressResponse: MultiAddressResponse?

    @objc var didChangePassword: Bool = false

    @objc weak var settingsDelegate: WalletSettingsDelegate?
    weak var authDelegate: WalletAuthDelegate?
    weak var pinEntryDelegate: WalletPinEntryDelegate?
    weak var buySellDelegate: WalletBuySellDelegate?
    weak var accountInfoDelegate: WalletAccountInfoDelegate?
    @objc weak var addressesDelegate: WalletAddressesDelegate?
    @objc weak var recoveryDelegate: WalletRecoveryDelegate?
    @objc weak var historyDelegate: WalletHistoryDelegate?
    @objc weak var accountInfoAndExchangeRatesDelegate: WalletAccountInfoAndExchangeRatesDelegate?
    @objc weak var backupDelegate: WalletBackupDelegate?
    @objc weak var sendBitcoinDelegate: WalletSendBitcoinDelegate?
    @objc weak var sendEtherDelegate: WalletSendEtherDelegate?
    @objc weak var exchangeDelegate: WalletExchangeDelegate?
    @objc weak var exchangeIntermediateDelegate: WalletExchangeIntermediateDelegate?
    @objc weak var fiatAtTimeDelegate: WalletFiatAtTimeDelegate?
    @objc weak var transactionDelegate: WalletTransactionDelegate?
    @objc weak var transferAllDelegate: WalletTransferAllDelegate?
    @objc weak var watchOnlyDelegate: WalletWatchOnlyDelegate?
    @objc weak var upgradeWalletDelegate: WalletUpgradeDelegate?
    weak var swipeAddressDelegate: WalletSwipeAddressDelegate?
    weak var keyImportDelegate: WalletKeyImportDelegate?
    weak var secondPasswordDelegate: WalletSecondPasswordDelegate?

    init(wallet: Wallet = Wallet()!) {
        self.wallet = wallet
        super.init()
        self.wallet.delegate = self
        self.wallet.loadJS()
    }

    /// Performs closing operations on the wallet. This should be called on logout and
    /// when the app is backgrounded
    func close() {
        latestMultiAddressResponse = nil
        closeWebSockets(withCloseCode: .loggedOut)

        wallet.resetSyncStatus()
        wallet.loadBlankWallet()
        wallet.hasLoadedAccountInfo = false

        beginBackgroundUpdateTask()
    }

    /// Closes all wallet websockets with the provided WebSocketCloseCode
    ///
    /// - Parameter closeCode: the WebSocketCloseCode
    @objc func closeWebSockets(withCloseCode closeCode: WebSocketCloseCode) {
        [wallet.ethSocket, wallet.bchSocket, wallet.btcSocket].forEach {
            $0?.close(withCode: closeCode.rawValue, reason: closeCode.reason)
        }
    }

    @objc func forgetWallet() {
        BlockchainSettings.App.shared.clearPin()

        // Clear all cookies (important one is the server session id SID)
        HTTPCookieStorage.shared.deleteAllCookies()

        wallet.sessionToken = nil

        AssetAddressRepository.shared.removeAllSwipeAddresses()
        BlockchainSettings.App.shared.guid = nil
        BlockchainSettings.App.shared.sharedKey = nil

        wallet.loadBlankWallet()

        latestMultiAddressResponse = nil

        AppCoordinator.shared.tabControllerManager.forgetWallet()

        AppCoordinator.shared.reload()

        BlockchainSettings.App.shared.biometryEnabled = false

        AppCoordinator.shared.tabControllerManager.transition(to: 1)

        BuySellCoordinator.shared.start()
    }

    private var backgroundUpdateTaskIdentifer: UIBackgroundTaskIdentifier?

    private func beginBackgroundUpdateTask() {
        // We're using a background task to ensure we get enough time to sync. The bg task has to be ended before or when the timer expires,
        // otherwise the app gets killed by the system. Always kill the old handler before starting a new one. In case the system starts a bg
        // task when the app goes into background, comes to foreground and goes to background before the first background task was ended.
        // In that case the first background task is never killed and the system kills the app when the maximum time is up.
        endBackgroundUpdateTask()

        backgroundUpdateTaskIdentifer = UIApplication.shared.beginBackgroundTask { [unowned self] in
            self.endBackgroundUpdateTask()
        }
    }

    private func endBackgroundUpdateTask() {
        guard let backgroundUpdateTaskIdentifer = backgroundUpdateTaskIdentifer else { return }
        UIApplication.shared.endBackgroundTask(backgroundUpdateTaskIdentifer)
    }

    fileprivate func updateSymbols() {
        updateFiatSymbols()
        updateBtcSymbols()
    }

    private func updateFiatSymbols() {
        guard let fiatCode = self.wallet.accountInfo["currency"] as? String else {
            Logger.shared.warning("Could not get fiat code")
            return
        }
        guard let currencySymbols = self.wallet.btcRates[fiatCode] as? [AnyHashable: Any] else {
            Logger.shared.warning("Currency symbols dictionary is nil")
            return
        }
        let symbolLocalDict = NSMutableDictionary(dictionary: currencySymbols)
        symbolLocalDict.setObject(fiatCode, forKey: "code" as NSString)
        self.latestMultiAddressResponse?.symbol_local = CurrencySymbol(fromDict: symbolLocalDict as? [AnyHashable: Any])
    }

    private func updateBtcSymbols() {
        guard let code = self.wallet.accountInfo["btc_currency"] as? String else {
            Logger.shared.warning("Could not get btc code")
            return
        }
        self.latestMultiAddressResponse?.symbol_btc = CurrencySymbol.btcSymbol(fromCode: code)
    }

    private func reloadAfterMultiaddressResponse() {
        AppCoordinator.shared.reloadAfterMultiAddressResponse()
    }
}

extension WalletManager: WalletDelegate {

    // MARK: - Auth

    func walletDidLoad() {
        Logger.shared.info("walletDidLoad()")
        endBackgroundUpdateTask()
    }

    func walletDidDecrypt() {
        Logger.shared.info("walletDidDecrypt()")

        DispatchQueue.main.async { [unowned self] in
            self.authDelegate?.didDecryptWallet(
                guid: self.wallet.guid,
                sharedKey: self.wallet.sharedKey,
                password: self.wallet.password
            )
        }

        didChangePassword = false
    }

    func walletDidFinishLoad() {
        Logger.shared.info("walletDidFinishLoad()")

        wallet.btcSwipeAddressToSubscribe = nil
        wallet.bchSwipeAddressToSubscribe = nil
        wallet.twoFactorInput = nil

        DispatchQueue.main.async { [unowned self] in
            self.authDelegate?.authenticationCompleted()
        }
    }

    func walletFailedToDecrypt() {
        Logger.shared.info("walletFailedToDecrypt()")
        DispatchQueue.main.async { [unowned self] in
            self.authDelegate?.authenticationError(error:
                AuthenticationError(code: AuthenticationError.ErrorCode.errorDecryptingWallet.rawValue)
            )
        }
    }

    func walletFailedToLoad() {
        Logger.shared.info("walletFailedToLoad()")
        DispatchQueue.main.async { [unowned self] in
            self.authDelegate?.authenticationError(error: AuthenticationError(
                code: AuthenticationError.ErrorCode.failedToLoadWallet.rawValue
            ))
        }
    }

    func walletDidRequireEmailAuthorization(_ wallet: Wallet!) {
        DispatchQueue.main.async { [unowned self] in
            self.authDelegate?.emailAuthorizationRequired()
        }
    }

    func wallet(_ wallet: Wallet!, didRequireTwoFactorAuthentication type: Int) {
        DispatchQueue.main.async { [unowned self] in
            guard let twoFactorType = AuthenticationTwoFactorType(rawValue: type) else {
                self.authDelegate?.authenticationError(error: AuthenticationError(
                    code: AuthenticationError.ErrorCode.invalidTwoFactorType.rawValue,
                    description: LocalizationConstants.Authentication.invalidTwoFactorAuthenticationType
                ))
                return
            }
            self.authDelegate?.didRequireTwoFactorAuth(withType: twoFactorType)
        }
    }

    func walletDidResendTwoFactorSMS(_ wallet: Wallet!) {
        DispatchQueue.main.async { [unowned self] in
            self.authDelegate?.didResendTwoFactorSMSCode()
        }
    }

    // MARK: - Buy/Sell

    func didCompleteTrade(_ tradeDict: [AnyHashable: Any]!) {
        guard let trade = Trade(dict: tradeDict as! [String: String]) else {
            Logger.shared.warning("Failed to create Trade object.")
            return
        }
        DispatchQueue.main.async { [unowned self] in
            self.buySellDelegate?.didCompleteTrade(trade: trade)
        }
    }

    func showCompletedTrade(_ txHash: String) {
        DispatchQueue.main.async { [unowned self] in
            self.buySellDelegate?.showCompletedTrade(tradeHash: txHash)
        }
    }

    // MARK: - Pin Entry

    func didFailPutPin(_ value: String!) {
        DispatchQueue.main.async { [unowned self] in
            self.pinEntryDelegate?.errorDidFailPutPin(errorMessage: value)
        }
    }

    func didPutPinSuccess(_ dictionary: [AnyHashable: Any]!) {
        let response = PutPinResponse(response: dictionary)
        DispatchQueue.main.async { [unowned self] in
            self.pinEntryDelegate?.putPinSuccess(response: response)
        }
    }

    // MARK: - Send Bitcoin/Bitcoin Cash
    func didCheck(forOverSpending amount: NSNumber!, fee: NSNumber!) {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.didCheckForOverSpending(amount: amount, fee: fee)
        }
    }

    func didGetMaxFee(_ fee: NSNumber!, amount: NSNumber!, dust: NSNumber?, willConfirm: Bool) {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.didGetMaxFee(fee: fee, amount: amount, dust: dust, willConfirm: willConfirm)
        }
    }

    func didUpdateTotalAvailable(_ sweepAmount: NSNumber!, finalFee: NSNumber!) {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.didUpdateTotalAvailable(sweepAmount: sweepAmount, finalFee: finalFee)
        }
    }

    func didGetFee(_ fee: NSNumber!, dust: NSNumber?, txSize: NSNumber!) {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.didGetFee(fee: fee, dust: dust, txSize: txSize)
        }
    }

    func didChangeSatoshiPerByte(_ sweepAmount: NSNumber!, fee: NSNumber!, dust: NSNumber?, updateType: FeeUpdateType) {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.didChangeSatoshiPerByte(
                sweepAmount: sweepAmount,
                fee: fee,
                dust: dust,
                updateType: updateType
            )
        }
    }

    func enableSendPaymentButtons() {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.enableSendPaymentButtons()
        }
    }

    func updateSendBalance(_ balance: NSNumber!, fees: [AnyHashable: Any]!) {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.updateSendBalance(balance: balance, fees: fees as NSDictionary)
        }
    }

    func didReceivePaymentNotice(_ notice: String?) {
        DispatchQueue.main.async { [unowned self] in
            self.sendBitcoinDelegate?.didReceivePaymentNotice(notice: notice)
        }
    }

    // MARK: - Send Ether
    func didUpdateEthPayment(_ payment: [AnyHashable: Any]!) {
        DispatchQueue.main.async { [unowned self] in
            self.sendEtherDelegate?.didUpdateEthPayment(payment: payment as NSDictionary)
        }
    }

    func didSendEther() {
        DispatchQueue.main.async { [unowned self] in
            self.sendEtherDelegate?.didSendEther()
        }
    }

    func didErrorDuringEtherSend(_ error: String!) {
        DispatchQueue.main.async { [unowned self] in
            self.sendEtherDelegate?.didErrorDuringEtherSend(error: error)
        }
    }

    func didGetEtherAddressWithSecondPassword() {
        DispatchQueue.main.async { [unowned self] in
            self.sendEtherDelegate?.didGetEtherAddressWithSecondPassword()
        }
    }

    // MARK: - Addresses

    func didGenerateNewAddress() {
        DispatchQueue.main.async { [unowned self] in
            self.addressesDelegate?.didGenerateNewAddress()
        }
    }

    func returnToAddressesScreen() {
        DispatchQueue.main.async { [unowned self] in
            self.addressesDelegate?.didGenerateNewAddress()
        }
    }

    func didSetDefaultAccount() {
        DispatchQueue.main.async { [unowned self] in
            self.addressesDelegate?.didSetDefaultAccount()
        }
    }

    // MARK: - Account Info

    func walletDidGetAccountInfo(_ wallet: Wallet!) {
        DispatchQueue.main.async { [unowned self] in
            self.accountInfoDelegate?.didGetAccountInfo()
        }
    }

    // MARK: - Currency Symbols

    func walletDidGetBtcExchangeRates(_ wallet: Wallet!) {
        DispatchQueue.main.async { [unowned self] in
            self.updateSymbols()
        }
    }

    // MARK: - BTC Multiaddress
    func didSetLatestBlock(_ block: LatestBlock!) {
        AppCoordinator.shared.tabControllerManager.didSetLatestBlock(block)
    }

    func didGet(_ response: MultiAddressResponse) {
        latestMultiAddressResponse = response
        AppCoordinator.shared.tabControllerManager.updateTransactionsViewControllerData(response)
        if self.wallet.isFilteringTransactions {
            self.wallet.isFilteringTransactions = false
            updateSymbols()
            reloadAfterMultiaddressResponse()
        } else {
            self.wallet.getAccountInfoAndExchangeRates()
        }

        let newDefaultAccountLabeledAddressesCount = self.wallet.getDefaultAccountLabelledAddressesCount()
        if BlockchainSettings.App.shared.defaultAccountLabelledAddressesCount != newDefaultAccountLabeledAddressesCount {
            AssetAddressRepository.shared.removeAllSwipeAddresses(for: .bitcoin)
        }
        let newCount = newDefaultAccountLabeledAddressesCount
        BlockchainSettings.App.shared.defaultAccountLabelledAddressesCount = Int(newCount)
    }

    // MARK: ETH Exchange Rate

    func didFetchEthExchangeRate(_ rate: NSNumber!) {
        AppCoordinator.shared.tabControllerManager.didFetchEthExchangeRate(rate)
    }

    // MARK: - Backup

    func didBackupWallet() {
        DispatchQueue.main.async { [unowned self] in
            self.backupDelegate?.didBackupWallet()
        }
    }

    func didFailBackupWallet() {
        DispatchQueue.main.async { [unowned self] in
            self.backupDelegate?.didFailBackupWallet()
        }
    }

    // MARK: - Account Info and Exchange Rates on startup

    func walletDidGetAccountInfoAndExchangeRates(_ wallet: Wallet!) {
        DispatchQueue.main.async { [unowned self] in
            self.accountInfoAndExchangeRatesDelegate?.didGetAccountInfoAndExchangeRates()
        }
    }

    // MARK: - Recovery

    func didRecoverWallet() {
        DispatchQueue.main.async { [unowned self] in
            self.recoveryDelegate?.didRecoverWallet()
        }
    }

    func didFailRecovery() {
        DispatchQueue.main.async { [unowned self] in
            self.recoveryDelegate?.didFailRecovery()
        }
    }

    // MARK: - Exchange

    func didGetExchangeTrades(_ trades: [Any]!) {
        DispatchQueue.main.async { [unowned self] in
            self.exchangeDelegate?.didGetExchangeTrades(trades: trades as NSArray)
        }
    }

    func didGet(_ rate: ExchangeRate!) {
        DispatchQueue.main.async { [unowned self] in
            self.exchangeDelegate?.didGetExchangeRate(rate: rate)
        }
    }

    func didGetAvailableBtcBalance(_ result: [AnyHashable: Any]?) {
        DispatchQueue.main.async { [unowned self] in
            self.exchangeDelegate?.didGetAvailableBtcBalance(result: result as NSDictionary?)
        }
    }

    func didGetAvailableEthBalance(_ result: [AnyHashable: Any]!) {
        DispatchQueue.main.async { [unowned self] in
            self.exchangeDelegate?.didGetAvailableEthBalance(result: result as NSDictionary)
        }
    }

    func didBuildExchangeTrade(_ tradeInfo: [AnyHashable: Any]!) {
        DispatchQueue.main.async { [unowned self] in
            self.exchangeDelegate?.didBuildExchangeTrade(tradeInfo: tradeInfo as NSDictionary)
        }
    }

    func didShiftPayment() {
        DispatchQueue.main.async { [unowned self] in
            self.exchangeDelegate?.didShiftPayment()
        }
    }

    func didCreateEthAccountForExchange() {
        DispatchQueue.main.async { [unowned self] in
            self.exchangeIntermediateDelegate?.didCreateEthAccountForExchange()
        }
    }

    // MARK: - History
    func didFailGetHistory(_ error: String?) {
        DispatchQueue.main.async { [unowned self] in
            self.historyDelegate?.didFailGetHistory(error: error)
        }
    }

    func didFetchEthHistory() {
        DispatchQueue.main.async { [unowned self] in
            self.historyDelegate?.didFetchEthHistory()
        }
    }

    func didFetchBitcoinCashHistory() {
        DispatchQueue.main.async { [unowned self] in
            self.historyDelegate?.didFetchBitcoinCashHistory()
        }
    }

    // MARK: - Watch Only Send
    func sendFromWatchOnlyAddress() {
        DispatchQueue.main.async { [unowned self] in
            self.watchOnlyDelegate?.sendFromWatchOnlyAddress()
        }
    }

    // MARK: - Transaction

    func didPushTransaction() {
        DispatchQueue.main.async { [unowned self] in
            self.transactionDelegate?.didPushTransaction()
        }
    }

    func receivedTransactionMessage() {
        DispatchQueue.main.async { [unowned self] in
            self.transactionDelegate?.onTransactionReceived()
        }
    }

    func paymentReceived(onPINScreen amount: String!, assetType: LegacyAssetType) {
        DispatchQueue.main.async { [unowned self] in
            self.transactionDelegate?.onPaymentReceived(amount: amount, assetType: AssetType.from(legacyAssetType: assetType))
        }
    }

    func updateLoadedAllTransactions(_ loadedAll: Bool) {
        DispatchQueue.main.async { [unowned self] in
            self.transactionDelegate?.updateLoadedAllTransactions(loadedAll: loadedAll)
        }
    }

    // MARK: - Transfer all
    func updateTransferAllAmount(_ amount: NSNumber!, fee: NSNumber!, addressesUsed: [Any]!) {
        DispatchQueue.main.async { [unowned self] in
            self.transferAllDelegate?.updateTransferAll(
                amount: amount,
                fee: fee,
                addressesUsed: addressesUsed as NSArray
            )
        }
    }

    func showSummaryForTransferAll() {
        DispatchQueue.main.async { [unowned self] in
            self.transferAllDelegate?.showSummaryForTransferAll()
        }
    }

    func sendDuringTransferAll(_ secondPassword: String?) {
        DispatchQueue.main.async { [unowned self] in
            self.transferAllDelegate?.sendDuringTransferAll(secondPassword: secondPassword)
        }
    }

    func didErrorDuringTransferAll(_ error: String!, secondPassword: String?) {
        DispatchQueue.main.async { [unowned self] in
            self.transferAllDelegate?.didErrorDuringTransferAll(error: error, secondPassword: secondPassword)
        }
    }

    // MARK: - Fiat at Time
    func didGetFiat(atTime fiatAmount: NSNumber!, currencyCode: String!, assetType: LegacyAssetType) {
        DispatchQueue.main.async { [unowned self] in
            self.fiatAtTimeDelegate?.didGetFiatAtTime(
                fiatAmount: fiatAmount,
                currencyCode: currencyCode,
                assetType: AssetType.from(legacyAssetType: assetType)
            )
        }
    }

    func didErrorWhenGettingFiat(atTime error: String?) {
        DispatchQueue.main.async { [unowned self] in
            self.fiatAtTimeDelegate?.didErrorWhenGettingFiatAtTime(error: error)
        }
    }

    // MARK: - Swipe Address

    func didGetSwipeAddresses(_ newSwipeAddresses: [Any]!, assetType: LegacyAssetType) {
        DispatchQueue.main.async { [unowned self] in
            self.swipeAddressDelegate?.onRetrievedSwipeToReceive(
                addresses: newSwipeAddresses as! [String],
                assetType: AssetType.from(legacyAssetType: assetType)
            )
        }
    }

    // MARK: - Key Importing

    func askUserToAddWatchOnlyAddress(_ address: AssetAddress, then: @escaping () -> Void) {
        DispatchQueue.main.async { [unowned self] in
            self.keyImportDelegate?.askUserToAddWatchOnlyAddress(address, then: then)
        }
    }

    @objc func scanPrivateKeyForWatchOnlyAddress(_ address: String) {
        let address = BitcoinAddress(string: address)
        DispatchQueue.main.async { [unowned self] in
            self.keyImportDelegate?.scanPrivateKeyForWatchOnlyAddress(address)
        }
    }

    // MARK: - Second Password
    @objc func getSecondPassword(withSuccess success: WalletSuccessCallback) {
        secondPasswordDelegate?.getSecondPassword(success: success)
    }

    @objc func getPrivateKeyPassword(withSuccess success: WalletSuccessCallback) {
        secondPasswordDelegate?.getPrivateKeyPassword(success: success)
    }

    // MARK: - Upgrade

    func walletUpgraded(_ wallet: Wallet!) {
        DispatchQueue.main.async {
            self.upgradeWalletDelegate?.onWalletUpgraded()
        }
    }
}
