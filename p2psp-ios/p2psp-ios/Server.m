//
//  Server.m
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 09/04/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import "Channel.h"
#import "Server.h"

@interface Server ()

@property(nonatomic) NSString *channelID;
@property(nonatomic) NSString *serverURL;

@end

@implementation Server

- (instancetype)initWithServerURL:(NSString *)serverURL {
  self = [super init];
  if (self) {
    self.serverURL = [NSString stringWithFormat:@"http://%@", serverURL];
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

- (void)getChannelsWithHandler:(void (^)(NSArray<Channel *> *,
                                         NSError *))handler {
  const NSString *path = @"/api/channels";
  NSString *fullURL = [NSString stringWithFormat:@"%@%@", self.serverURL, path];

  NSMutableURLRequest *urlRequest =
      [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:fullURL]];

  [NSURLConnection sendAsynchronousRequest:urlRequest
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response,
                                             NSData *data, NSError *error) {

                           NSArray<Channel *> *channelList;
                           // TODO: Handle errors
                           if (!error) {
                             channelList =
                                 [self getChannelsList:data withError:&error];
                           }

                           handler(channelList, error);
                         }];
}

- (void)createChannelwithTitle:(NSString *)title
                andDescription:(NSString *)description
                   withHandler:(void (^)(NSString *, NSError *))handler {
  // Path to channel
  const NSString *path = @"/api/channels";
  NSString *fullURL = [NSString stringWithFormat:@"%@%@", self.serverURL, path];

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
  // TODO: Implement channel update in server
}

- (BOOL)emit:(NSURL *)localFileURL withHandler:(void (^)(NSError *))handler {
  // Load file to memory
  NSData *localFile = [NSData dataWithContentsOfURL:localFileURL];

  if ([localFile length] < 1) {
    return NO;
  }

  // Path to channel
  const NSString *path = @"/api/emit/";
  NSString *fullURL = [NSString
      stringWithFormat:@"%@%@%@", self.serverURL, path, self.channelID];

  NSMutableURLRequest *urlRequest =
      [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:fullURL]];

  // Seth headers and body
  [urlRequest setHTTPMethod:@"POST"];
  [urlRequest setValue:@"video/mp4" forHTTPHeaderField:@"Content-Type"];
  [urlRequest setValue:[NSString
                           stringWithFormat:@"%lu", (u_long)[localFile length]]
      forHTTPHeaderField:@"Content-Length"];
  [urlRequest setHTTPBody:localFile];

  // Make HTTP request
  [NSURLConnection sendAsynchronousRequest:urlRequest
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:^(NSURLResponse *response,
                                             NSData *data, NSError *error) {

                           // Call the callback
                           handler(error);
                         }];

  return YES;
}

/**
 *  Builds the objects in memory for the received JSON
 *
 *  @param data The JSON data
 */
- (NSArray<Channel *> *)getChannelsList:(NSData *)data
                              withError:(NSError **)error {
  *error = nil;

  NSArray *parsedObject =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:error];

  // Handle error within JSON
  if (*error) {
    return nil;
  }

  NSMutableArray *channelsList = [[NSMutableArray alloc] init];

  for (NSDictionary *jsonChannel in parsedObject) {
    Channel *channel = [[Channel alloc] init];

    // TODO: Find a way to automate this
    if ([channel respondsToSelector:NSSelectorFromString(@"title")]) {
      channel.title = [jsonChannel valueForKey:@"title"];
    }

    if ([channel respondsToSelector:NSSelectorFromString(@"desc")]) {
      channel.desc = [jsonChannel valueForKey:@"desc"];
    }

    if ([channel respondsToSelector:NSSelectorFromString(@"ip")]) {
      channel.ip = [jsonChannel valueForKey:@"ip"];
    }

    if ([channel respondsToSelector:NSSelectorFromString(@"port")]) {
      channel.port = [jsonChannel valueForKey:@"port"];
    }

    [channelsList addObject:channel];
  }

  return [[NSArray<Channel *> alloc] initWithArray:channelsList];
}

@end
