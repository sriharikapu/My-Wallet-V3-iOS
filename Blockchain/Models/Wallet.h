/*
 *
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import "MultiAddressResponse.h"
#import "SRWebSocket.h"
#import "FeeTypes.h"
#import "Assets.h"

@interface transactionProgressListeners : NSObject
@property(nonatomic, copy) void (^ _Nonnull on_start)(void);
@property(nonatomic, copy) void (^ _Nullable on_begin_signing)(NSString*);
@property(nonatomic, copy) void (^ _Nullable on_sign_progress)(int input);
@property(nonatomic, copy) void (^ _Nullable on_finish_signing)(NSString*);
@property(nonatomic, copy) void (^ _Nullable on_success)(NSString* _Nullable secondPassword, NSString* _Nullable transactionHash);
@property(nonatomic, copy) void (^ _Nonnull on_error)(NSString* _Nullable error, NSString* _Nullable secondPassword);
@end

@interface Key : NSObject {
    int tag;
}
@property(nonatomic, strong) NSString * _Nullable addr;
@property(nonatomic, strong) NSString * _Nullable priv;
@property(nonatomic, strong) NSString * _Nullable label;
@property(nonatomic, assign) int tag;
@end

@class Wallet, Transaction, JSValue, JSContext, ExchangeRate;

@protocol WalletSuccessCallback;

@protocol ExchangeAccountDelegate
- (void)watchPendingTrades:(BOOL)shouldSync;
- (void)showCompletedTrade:(NSString *_Nullable)txHash;
@end

@protocol WalletDelegate <NSObject>
@optional
- (void)didSetLatestBlock:(LatestBlock*)block;
- (void)didGetMultiAddressResponse:(MultiAddressResponse*)response;
- (void)didFilterTransactions:(NSArray *)transactions;
- (void)walletDidDecrypt;
- (void)walletFailedToDecrypt;
- (void)walletDidLoad;
- (void)walletFailedToLoad;
- (void)walletDidFinishLoad;
- (void)didBackupWallet;
- (void)didFailBackupWallet;
- (void)walletJSReady;
- (void)didGenerateNewAddress;
- (void)didParsePairingCode:(NSDictionary *)dict;
- (void)errorParsingPairingCode:(NSString *)message;
- (void)didMakePairingCode:(NSString *)code;
- (void)errorMakingPairingCode:(NSString *)message;
- (void)didCreateNewAccount:(NSString *)guid sharedKey:(NSString *)sharedKey password:(NSString *)password;
- (void)errorCreatingNewAccount:(NSString *)message;
- (void)didImportKey:(NSString *)address;
- (void)didImportIncorrectPrivateKey:(NSString *)address;
- (void)didImportPrivateKeyToLegacyAddress;
- (void)didFailToImportPrivateKey:(NSString *)error;
- (void)didFailRecovery;
- (void)didRecoverWallet;
- (void)didFailGetHistory:(NSString *_Nullable)error;
- (void)resendTwoFactorSuccess;
- (void)resendTwoFactorError:(NSString *)error;
- (void)returnToAddressesScreen;
- (void)sendFromWatchOnlyAddress;
- (void)estimateTransactionSize:(uint64_t)size;
- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee;
- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount dust:(NSNumber *_Nullable)dust willConfirm:(BOOL)willConfirm;
- (void)didUpdateTotalAvailable:(NSNumber *)sweepAmount finalFee:(NSNumber *)finalFee;
- (void)didGetFee:(NSNumber *)fee dust:(NSNumber *_Nullable)dust txSize:(NSNumber *)txSize;
- (void)didChangeSatoshiPerByte:(NSNumber *)sweepAmount fee:(NSNumber *)fee dust:(NSNumber *_Nullable)dust updateType:(FeeUpdateType)updateType;
- (void)enableSendPaymentButtons;
- (void)didGetSurgeStatus:(BOOL)surgeStatus;
- (void)updateSendBalance:(NSNumber *)balance fees:(NSDictionary *)fees;
- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed;
- (void)showSummaryForTransferAll;
- (void)sendDuringTransferAll:(NSString *_Nullable)secondPassword;
- (void)didErrorDuringTransferAll:(NSString *)error secondPassword:(NSString *_Nullable)secondPassword;
- (void)updateLoadedAllTransactions:(BOOL)loadedAll;
- (void)receivedTransactionMessage;
- (void)paymentReceivedOnPINScreen:(NSString *)amount assetType:(LegacyAssetType)assetType;
- (void)didReceivePaymentNotice:(NSString *_Nullable)notice;
- (void)didGetFiatAtTime:(NSNumber *)fiatAmount currencyCode:(NSString *)currencyCode assetType:(LegacyAssetType)assetType;
- (void)didErrorWhenGettingFiatAtTime:(NSString *_Nullable)error;
- (void)didSetDefaultAccount;
- (void)didChangeLocalCurrency;
- (void)setupBackupTransferAll:(id)transferAllController;
- (void)didCreateInvitation:(NSDictionary *)invitation;
- (void)didReadInvitation:(NSDictionary *)invitation identifier:(NSString *)identifier;
- (void)didCompleteRelation;
- (void)didFailCompleteRelation;
- (void)didFailAcceptRelation:(NSString *)name;
- (void)didAcceptRelation:(NSString *)invitation name:(NSString *)name;
- (void)didFetchExtendedPublicKey;
- (void)didGetNewMessages:(NSArray *)newMessages;
- (void)didGetMessagesOnFirstLoad;
- (void)didSendPaymentRequest:(NSDictionary *)info amount:(uint64_t)amount name:(NSString *)name requestId:(NSString *)requestId;
- (void)didRequestPaymentRequest:(NSDictionary *)info name:(NSString *)name;
- (void)didSendPaymentRequestResponse;
- (void)didCompleteTrade:(NSDictionary *)trade;
- (void)didPushTransaction;
- (void)showCompletedTrade:(NSString *)txHash;
- (void)didGetSwipeAddresses:(NSArray *)newSwipeAddresses assetType:(LegacyAssetType)assetType;
- (void)didFetchEthHistory;
- (void)didUpdateEthPayment:(NSDictionary *)payment;
- (void)didFetchEthExchangeRate:(NSNumber *)rate;
- (void)didSendEther;
- (void)didErrorDuringEtherSend:(NSString *)error;
- (void)didGetEtherAddressWithSecondPassword;
- (void)didGetExchangeTrades:(NSArray *)trades;
- (void)didGetExchangeRate:(ExchangeRate *)result;
- (void)didGetAvailableEthBalance:(NSDictionary *)result;
- (void)didGetAvailableBtcBalance:(NSDictionary *)result;
- (void)didBuildExchangeTrade:(NSDictionary *)tradeInfo;
- (void)didShiftPayment;
- (void)didCreateEthAccountForExchange;
- (void)didFetchBitcoinCashHistory;
- (void)wallet:(Wallet *)wallet didRequireTwoFactorAuthentication:(NSInteger)type;
- (void)walletDidResendTwoFactorSMS:(Wallet *)wallet;
- (void)walletDidRequireEmailAuthorization:(Wallet *)wallet;
- (void)walletDidGetAccountInfo:(Wallet *)wallet;
- (void)walletDidGetBtcExchangeRates:(Wallet *)wallet;
- (void)walletDidGetAccountInfoAndExchangeRates:(Wallet *)wallet;
- (void)getSecondPasswordWithSuccess:(id<WalletSuccessCallback>)success;
- (void)getPrivateKeyPasswordWithSuccess:(id<WalletSuccessCallback>)success;
- (void)walletUpgraded:(Wallet *)wallet;
@end

@interface Wallet : NSObject <UIWebViewDelegate, SRWebSocketDelegate, ExchangeAccountDelegate> {
}

// Core Wallet Init Properties
@property (readonly, nonatomic) JSContext *context;

@property(nonatomic, strong) NSString *guid;
@property(nonatomic, strong) NSString *sharedKey;
@property(nonatomic, strong) NSString *password;

@property(nonatomic, strong) NSString *sessionToken;

@property(nonatomic, strong) id<WalletDelegate> delegate;

@property(nonatomic) uint64_t final_balance;
@property(nonatomic) uint64_t total_sent;
@property(nonatomic) uint64_t total_received;

@property(nonatomic, strong) NSMutableDictionary *transactionProgressListeners;

@property(nonatomic) NSDictionary *accountInfo;
@property(nonatomic) BOOL hasLoadedAccountInfo;

@property(nonatomic) BOOL shouldLoadMetadata;

@property(nonatomic) NSString *lastScannedWatchOnlyAddress;
@property(nonatomic) NSString *lastImportedAddress;
@property(nonatomic) BOOL didReceiveMessageForLastTransaction;

// HD properties:
@property NSString *recoveryPhrase;
@property int emptyAccountIndex;
@property int recoveredAccountIndex;

@property BOOL didPairAutomatically;
@property BOOL isFilteringTransactions;
@property BOOL isFetchingTransactions;
@property BOOL isSyncing;
@property BOOL isNew;
@property NSString *twoFactorInput;
@property (nonatomic) NSDictionary *btcRates;

@property (nonatomic) SRWebSocket *btcSocket;
@property (nonatomic) SRWebSocket *bchSocket;
@property (nonatomic) SRWebSocket *ethSocket;
@property (nonatomic) NSMutableArray *pendingEthSocketMessages;

@property (nonatomic) NSTimer *btcSocketTimer;
@property (nonatomic) NSTimer *bchSocketTimer;
@property (nonatomic) NSString *btcSwipeAddressToSubscribe;
@property (nonatomic) NSString *bchSwipeAddressToSubscribe;

@property (nonatomic) int lastLabelledAddressesCount;

@property (nonatomic) NSArray *bitcoinCashTransactions;

@property (nonatomic) NSArray *etherTransactions;
@property (nonatomic) NSDecimalNumber *latestEthExchangeRate;

- (id)init;

- (void)login;

- (void)loadJS;

- (void)loadWalletWithGuid:(NSString *)_guid sharedKey:(NSString *)_sharedKey password:(NSString *)_password;
- (void)loadBlankWallet;

- (void)resetSyncStatus;

- (NSDictionary *)addressBook;

- (void)setLabel:(NSString *)label forLegacyAddress:(NSString *)address;

- (void)loadWalletLogin;

- (void)toggleArchiveLegacyAddress:(NSString *)address;
- (void)toggleArchiveAccount:(int)account assetType:(LegacyAssetType)assetType;
- (void)archiveTransferredAddresses:(NSArray *)transferredAddresses;

- (void)sendPaymentWithListener:(transactionProgressListeners*)listener secondPassword:(NSString *)secondPassword;
- (void)sendFromWatchOnlyAddress:(NSString *)watchOnlyAddress privateKey:(NSString *)privateKeyString;

- (NSString *)labelForLegacyAddress:(NSString *)address assetType:(LegacyAssetType)assetType;

- (Boolean)isAddressArchived:(NSString *)address;

- (void)subscribeToSwipeAddress:(NSString *)address assetType:(LegacyAssetType)assetType;
- (void)subscribeToAddress:(NSString *)address assetType:(LegacyAssetType)assetType;

- (void)addToAddressBook:(NSString *)address label:(NSString *)label;

- (BOOL)isValidAddress:(NSString *)string assetType:(LegacyAssetType)assetType;
- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address;

- (BOOL)addKey:(NSString *)privateKeyString;
- (BOOL)addKey:(NSString*)privateKeyString toWatchOnlyAddress:(NSString *)watchOnlyAddress;

// Fetch String Array Of Addresses
- (NSArray *)activeLegacyAddresses:(LegacyAssetType)assetType;
- (NSArray *)spendableActiveLegacyAddresses;
- (NSArray *)allLegacyAddresses:(LegacyAssetType)assetType;
- (NSArray *)archivedLegacyAddresses;

- (BOOL)isInitialized;
- (BOOL)hasEncryptedWalletData;

- (float)getStrengthForPassword:(NSString *)password;

- (BOOL)needsSecondPassword;
- (BOOL)validateSecondPassword:(NSString *)secondPassword;

- (void)getHistory;
- (void)getHistoryWithoutBusyView;
- (void)getHistoryIfNoTransactionMessage;
- (void)getBitcoinCashHistoryIfNoTransactionMessage;
- (void)getWalletAndHistory;

- (id)getLegacyAddressBalance:(NSString *)address assetType:(LegacyAssetType)assetType;
- (uint64_t)parseBitcoinValueFromTextField:(UITextField *)textField;
- (uint64_t)parseBitcoinValueFromString:(NSString *)inputString;
- (void)changeLocalCurrency:(NSString *)currencyCode;
- (void)changeBtcCurrency:(NSString *)btcCode;
- (uint64_t)conversionForBitcoinAssetType:(LegacyAssetType)assetType;

- (void)parsePairingCode:(NSString *)code;
- (void)makePairingCode;
- (void)resendTwoFactorSMS;

- (NSString *)detectPrivateKeyFormat:(NSString *)privateKeyString;

- (void)newAccount:(NSString *)password email:(NSString *)email;

- (NSString *)encrypt:(NSString *)data password:(NSString *)password pbkdf2_iterations:(int)pbkdf2_iterations;
- (NSString *)decrypt:(NSString *)data password:(NSString *)password pbkdf2_iterations:(int)pbkdf2_iterations;

- (BOOL)isAddressAvailable:(NSString *)address;
- (BOOL)isAccountAvailable:(int)account;
- (int)getIndexOfActiveAccount:(int)account assetType:(LegacyAssetType)assetType;

- (void)fetchMoreTransactions;
- (void)reloadFilter;

- (int)getAllTransactionsCount;

// HD Wallet
- (void)upgradeToV3Wallet;
- (Boolean)hasAccount;
- (Boolean)didUpgradeToHd;
- (void)getRecoveryPhrase:(NSString *)secondPassword;
- (BOOL)isRecoveryPhraseVerified;
- (void)markRecoveryPhraseVerified;
- (int)getDefaultAccountIndexForAssetType:(LegacyAssetType)assetType;
- (void)setDefaultAccount:(int)index assetType:(LegacyAssetType)assetType;
- (int)getActiveAccountsCount:(LegacyAssetType)assetType;
- (int)getAllAccountsCount:(LegacyAssetType)assetType;
- (BOOL)hasLegacyAddresses:(LegacyAssetType)assetType;
- (BOOL)isAccountArchived:(int)account assetType:(LegacyAssetType)assetType;
- (BOOL)isAccountNameValid:(NSString *)name;

- (uint64_t)getTotalActiveBalance;
- (uint64_t)getWatchOnlyBalance;
- (uint64_t)getTotalBalanceForActiveLegacyAddresses:(LegacyAssetType)assetType;
- (uint64_t)getTotalBalanceForSpendableActiveLegacyAddresses;
- (id)getBalanceForAccount:(int)account assetType:(LegacyAssetType)assetType;

- (NSString *)getLabelForAccount:(int)account assetType:(LegacyAssetType)assetType;
- (void)setLabelForAccount:(int)account label:(NSString *)label assetType:(LegacyAssetType)assetType;

- (void)createAccountWithLabel:(NSString *)label;
- (void)generateNewKey;

- (NSString *)getReceiveAddressOfDefaultAccount:(LegacyAssetType)assetType;
- (NSString *)getReceiveAddressForAccount:(int)account assetType:(LegacyAssetType)assetType;

- (NSString *)getXpubForAccount:(int)accountIndex assetType:(LegacyAssetType)assetType;

- (void)setPbkdf2Iterations:(int)iterations;

- (void)loading_start_get_history;
- (void)loading_start_recover_wallet;
- (void)loading_stop;
- (void)upgrade_success;

- (BOOL)checkIfWalletHasAddress:(NSString *)address;

- (NSDictionary *)filteredWalletJSON;

- (int)getDefaultAccountLabelledAddressesCount;

- (BOOL)isBuyEnabled;
- (BOOL)canUseSfox;

// Settings
- (void)getAccountInfo;
- (NSString *)getEmail;
- (NSString *)getSMSNumber;
- (BOOL)getSMSVerifiedStatus;
- (NSDictionary *)getFiatCurrencies;
- (NSDictionary *)getBtcCurrencies;
- (int)getTwoStepType;
- (BOOL)getEmailVerifiedStatus;

- (void)getAccountInfoAndExchangeRates;

- (void)changeEmail:(NSString *)newEmail;
- (void)resendVerificationEmail:(NSString *)email;
- (void)getBtcExchangeRates;
- (void)changeMobileNumber:(NSString *)newMobileNumber;
- (void)verifyMobileNumber:(NSString *)code;
- (void)enableTwoStepVerificationForSMS;
- (void)disableTwoStepVerification;
- (void)changePassword:(NSString *)changedPassword;
- (BOOL)isCorrectPassword:(NSString *)inputedPassword;
- (void)enableEmailNotifications;
- (void)disableEmailNotifications;
- (BOOL)emailNotificationsEnabled;

// Security Center
- (BOOL)hasVerifiedEmail;
- (BOOL)hasVerifiedMobileNumber;
- (BOOL)hasEnabledTwoStep;
- (int)securityCenterScore;
- (int)securityCenterCompletedItemsCount;

// Payment Spender
- (void)createNewPayment:(LegacyAssetType)assetType;
- (void)changePaymentFromAddress:(NSString *)fromString isAdvanced:(BOOL)isAdvanced assetType:(LegacyAssetType)assetType;
- (void)changePaymentFromAccount:(int)fromInt isAdvanced:(BOOL)isAdvanced assetType:(LegacyAssetType)assetType;
- (void)changePaymentToAccount:(int)toInt assetType:(LegacyAssetType)assetType;
- (void)changePaymentToAddress:(NSString *)toString assetType:(LegacyAssetType)assetType;
- (void)changePaymentAmount:(id)amount assetType:(LegacyAssetType)assetType;
- (void)sweepPaymentRegular;
- (void)sweepPaymentRegularThenConfirm;
- (void)sweepPaymentAdvanced;
- (void)sweepPaymentAdvancedThenConfirm:(uint64_t)fee;
- (void)setupBackupTransferAll:(id)transferAllController;
- (void)getInfoForTransferAllFundsToAccount;
- (void)setupFirstTransferForAllFundsToAccount:(int)account address:(NSString *)address secondPassword:(NSString *)secondPassword useSendPayment:(BOOL)useSendPayment;
- (void)setupFollowingTransferForAllFundsToAccount:(int)account address:(NSString *)address secondPassword:(NSString *)secondPassword useSendPayment:(BOOL)useSendPayment;
- (void)transferFundsBackupWithListener:(transactionProgressListeners*)listener secondPassword:(NSString *)secondPassword;
- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address;
- (void)changeLastUsedReceiveIndexOfDefaultAccount;
- (void)checkIfOverspending;
- (void)changeSatoshiPerByte:(uint64_t)satoshiPerByte updateType:(FeeUpdateType)updateType;
- (void)getTransactionFeeWithUpdateType:(FeeUpdateType)updateType;
- (void)getSurgeStatus;
- (uint64_t)dust;
- (void)getSwipeAddresses:(int)numberOfAddresses assetType:(LegacyAssetType)assetType;

// Recover with passphrase
- (void)recoverWithEmail:(NSString *)email password:(NSString *)recoveryPassword passphrase:(NSString *)passphrase;

- (void)updateServerURL:(NSString *)newURL;

// Transaction Details
- (void)saveNote:(NSString *)note forTransaction:(NSString *)hash;
- (void)saveEtherNote:(NSString *)note forTransaction:(NSString *)hash;
- (void)getFiatAtTime:(uint64_t)time value:(NSDecimalNumber *)value currencyCode:(NSString *)currencyCode assetType:(LegacyAssetType)assetType;
- (NSString *)getNotePlaceholderForTransactionHash:(NSString *)myHash;

- (JSValue *)executeJSSynchronous:(NSString *)command;

// Ethereum
- (NSString *)getEthBalance;
- (NSString *)getEthBalanceTruncated;
- (NSArray *)getEthTransactions;
- (void)getEthHistory;
- (void)getEthExchangeRate;

// Ether send
- (void)sendEtherPaymentWithNote:(NSString *)note;
- (NSString *)getEtherAddress;
- (void)isEtherContractAddress:(NSString *)address completion:(void (^ __nullable)(NSData *data, NSURLResponse *response, NSError *error))completion;
- (void)sweepEtherPayment;
- (BOOL)hasEthAccount;
- (BOOL)isWaitingOnEtherTransaction;

// Bitcoin Cash
- (NSString *)fromBitcoinCash:(NSString *)address;
- (NSString *)toBitcoinCash:(NSString *)address includePrefix:(BOOL)includePrefix;
- (void)getBitcoinCashHistoryAndRates;
- (void)fetchBitcoinCashExchangeRates;
- (NSString *)getLabelForBitcoinCashAccount:(int)account;
- (void)buildBitcoinCashPaymentTo:(id)to amount:(uint64_t)amount;
- (void)sendBitcoinCashPaymentWithListener:(transactionProgressListeners*)listener;
- (BOOL)hasBchAccount;
- (uint64_t)getBchBalance;
- (NSString *)bitcoinCashExchangeRate;
- (uint64_t)getBitcoinCashConversion;
- (NSArray *)getBitcoinCashTransactions:(NSInteger)filterType;
- (NSString *_Nullable)getLabelForDefaultBchAccount;

// Exchange
- (void)createEthAccountForExchange:(NSString *)secondPassword;
- (BOOL)isExchangeEnabled;
- (NSArray *)availableUSStates;
- (BOOL)isStateWhitelistedForShapeshift:(NSString *)stateCode;
- (void)selectState:(NSString *)name code:(NSString *)code;
- (void)getExchangeTrades;
- (void)getRate:(NSString *)coinPair;
- (NSURLSessionDataTask *)getApproximateQuote:(NSString *)coinPair usingFromField:(BOOL)usingFromField amount:(NSString *)amount completion:(void (^)(NSDictionary *, NSURLResponse *, NSError *))completion;
- (void)getAvailableBtcBalanceForAccount:(int)account;
- (void)getAvailableBchBalanceForAccount:(int)account;
- (void)getAvailableEthBalance;
- (void)buildExchangeTradeFromAccount:(int)fromAccount toAccount:(int)toAccount coinPair:(NSString *)coinPair amount:(NSString *)amount fee:(NSString *)fee;
- (void)shiftPayment;
- (BOOL)isDepositTransaction:(NSString *)txHash;
- (BOOL)isWithdrawalTransaction:(NSString *)txHash;

// Top Bar Display
- (NSDecimalNumber *)btcDecimalBalance;
- (NSDecimalNumber *)ethDecimalBalance;

- (NSString *)getMobileMessage;
@end
