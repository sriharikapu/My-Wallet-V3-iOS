//
//  BCSwipeAddressViewModel.m
//  Blockchain
//
//  Created by kevinwu on 3/12/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCSwipeAddressViewModel.h"

@implementation BCSwipeAddressViewModel

- (id)initWithAssetType:(AssetType)assetType
{
    if (self == [super init]) {
        self.assetType = assetType;
        NSString *suffix;
        NSString *assetImageViewName;
        if (assetType == AssetTypeBitcoin) {
            suffix = BC_STRING_BITCOIN;
            assetImageViewName = @"bitcoin_large";
        } else if (assetType == AssetTypeEther) {
            suffix = BC_STRING_ETHER;
            assetImageViewName = @"ether_large";
        } else if (assetType == AssetTypeBitcoinCash) {
            suffix = BC_STRING_BITCOIN_CASH;
            assetImageViewName = @"bitcoin_cash_large";
        }
        self.assetImageViewName = assetImageViewName;
        self.action = [[[BC_STRING_REQUEST stringByAppendingString:@" "] stringByAppendingString:suffix] uppercaseString];
    }
    return self;
}

- (void)setAddress:(NSString *)address
{
    _address = address;
    
    self.textAddress = self.assetType == AssetTypeBitcoinCash ? [address substringFromIndex:[PREFIX_BITCOIN_CASH length]] : address;
}

@end
