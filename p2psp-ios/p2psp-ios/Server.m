//
//  Server.m
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 09/04/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import "Server.h"

@interface Server ()

@property(nonatomic) NSString *channelID;
@property(nonatomic) NSString *serverURL;

@end

@implementation Server

- (instancetype)initWithServerURL:(NSString *)serverURL {
  self = [super init];
  if (self) {
    self.serverURL = [NSString stringWithString:serverURL];
  }
  return self;
}

- (void)getChannel:(NSString *)channelID
       withHandler:(void (^)(NSDictionary *, NSError *))handler {
  // Path to channel
  const NSString *path = @"/api/channels/";
  NSString *fullURL =
      [NSString stringWithFormat:@"%@%@%@", self.serverURL, path, channelID];

  NSURLRequest *urlRequest =
      [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:fullURL]];

  [NSURLConnection
      sendAsynchronousRequest:urlRequest
                        queue:[[NSOperationQueue alloc] init]
            completionHandler:^(NSURLResponse *response, NSData *data,
                                NSError *error) {
              // TODO: Handle errors

              // Call the callback
              handler([NSJSONSerialization
                          JSONObjectWithData:data
                                     options:NSJSONReadingMutableContainers
                                       error:nil],
                      error);
            }];
}

- (void)getChannelsWithHandler:(void (^)(NSArray *, NSError *))handler {
}

- (void)createChannelwithTitle:(NSString *)title
                andDescription:(NSString *)description
                   withHandler:(void (^)(NSString *, NSError *))handler {
  // Path to channel
  const NSString *path = @"/api/channels";
  NSString *fullURL =
      [NSString stringWithFormat:@"%@%@%@", @"http://", self.serverURL, path];

  NSMutableURLRequest *urlRequest =
      [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:fullURL]];

  // Prepare data
  NSMutableDictionary *jsonData = [[NSMutableDictionary alloc] init];
  [jsonData setObject:title forKey:@"title"];
  [jsonData setObject:description forKey:@"description"];

  // Seth headersand body
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [urlRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:jsonData
                                                          options:0
                                                            error:nil]];

  // Make HTTP request
  [NSURLConnection sendAsynchronousRequest:urlRequest
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response,
                                             NSData *data, NSError *error) {

                           self.channelID = nil;

                           if (!error) {
                             NSDictionary *json = [NSJSONSerialization
                                 JSONObjectWithData:data
                                            options:0
                                              error:&error];
                             if (!error) {
                               self.channelID = [json valueForKey:@"id"];
                             }
                           }

                           // Call the callback
                           handler(self.channelID, error);
                         }];
}

- (void)updateChannel:(NSString *)channelID
            withTitle:(NSString *)title
       andDescription:(NSString *)description
          withHandler:(void (^)(NSError *))handler {
}

- (void)emit:(NSURL *)localFileURL withHandler:(void (^)(NSError *))handler {
}

@end
