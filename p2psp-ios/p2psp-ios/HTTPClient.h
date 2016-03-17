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

- (void)createConnection:(NSURL*)serverAddress;
- (void)postVideo:(NSURL*)locaFilelURL;
- (void)closeConnetion;

@end
