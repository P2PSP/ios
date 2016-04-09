//
//  Server.h
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 09/04/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Server : NSObject

/**
 *  Initializes a new Server object with the url of the server
 *
 *  @param serverURLURL The url of the server
 *
 *  @return The string containing the url
 */
- (instancetype)initWithServerURL:(NSString *)serverURLURL;

/**
 *  Make an HTTP GET to /api/channels/:id
 *
 *  @param channelID The channel id
 *  @param handler   The handler function
 */
- (void)getChannel:(NSString *)channelID
       withHandler:(void (^)(NSDictionary *, NSError *))handler;
/**
 *  Make an HTTP GET to /api/channels
 *
 *  @param handler The handler function
 */
- (void)getChannelsWithHandler:(void (^)(NSArray<Channel *> *,
                                         NSError *))handler;

/**
 *  Make an HTTP POST to /api/channels
 *
 *  @param title       The title of the channel
 *  @param description The description of the channel
 *  @param handler     The handler function
 */
- (void)createChannelwithTitle:(NSString *)title
                andDescription:(NSString *)description
                   withHandler:(void (^)(NSString *, NSError *))handler;

/**
 *  Make an HTTP POST to /api/channels/:id
 *
 *  @param channelID   The channel id
 *  @param title       The title of the channel
 *  @param description The description of the channel
 *  @param handler     The handler function
 */
- (void)updateChannel:(NSString *)channelID
            withTitle:(NSString *)title
       andDescription:(NSString *)description
          withHandler:(void (^)(NSError *))handler;

/**
 *  Make an HTTP POST to /api/emit/:id
 *
 *  @param localFileURL The local video file path
 *  @param handler      The handler function
 *
 *  @return YES if the conditions before making the connection are satified, NO
 * otherwise
 */
- (BOOL)emit:(NSURL *)localFileURL withHandler:(void (^)(NSError *))handler;

@end
