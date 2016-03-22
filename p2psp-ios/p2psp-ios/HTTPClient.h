//
//  HTTPClient.h
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 17/03/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTTPClient
    : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (instancetype)initWithServerAddress:(NSURL *)serverAddress;
- (void)postVideo:(NSURL *)localFilelURL;
- (void)closeConnetion;

@end
