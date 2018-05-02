//
//  KeychainItemWrapper+SwipeAddresses.h
//  Blockchain
//
//  Created by Kevin Wu on 10/21/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "KeychainItemWrapper.h"
#import "Assets.h"

@interface KeychainItemWrapper (SwipeAddresses)
+ (NSArray *)getSwipeAddressesForAssetType:(AssetType)assetType;
+ (void)addSwipeAddress:(NSString *)swipeAddress assetType:(AssetType)assetType;
+ (void)removeFirstSwipeAddressForAssetType:(AssetType)assetType;
+ (void)removeAllSwipeAddressesForAssetType:(AssetType)assetType;
+ (void)removeAllSwipeAddresses;
+ (void)setSwipeEtherAddress:(NSString *)swipeAddress;
+ (NSString *)getSwipeEtherAddress;
+ (void)removeSwipeEtherAddress;
@end
