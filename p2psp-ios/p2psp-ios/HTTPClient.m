//
//  HTTPClient.m
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 17/03/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import "HTTPClient.h"

@interface HTTPClient ()

@property(nonatomic) NSMutableURLRequest *request;

@end

@implementation HTTPClient

- (instancetype)initWithServerAddress:(NSURL *)serverAddress {
  self = [super init];
  if (self) {
    self.request = [NSMutableURLRequest requestWithURL:serverAddress];
    [self.request setHTTPMethod:@"POST"];

    [self.request addValue:@"application/octet-stream"
        forHTTPHeaderField:@"Content-Type"];

    [self.request addValue:@"0" forHTTPHeaderField:@"Content-Length"];
  }
  return self;
}

- (void)postVideo:(NSURL *)localFilelURL {
  NSData *localFile = [NSData dataWithContentsOfURL:localFilelURL];

  if ([localFile length] < 1) {
    return;
  }

  [self.request setValue:[NSString stringWithFormat:@"%lu",
                                                    (u_long)[localFile length]]
      forHTTPHeaderField:@"Content-Length"];

  [self.request setHTTPBody:localFile];

  NSURLConnection *conn =
      [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
  // A response has been received, this is where we initialize the instance var
  // you created
  // so that we can append data to it in the didReceiveData method
  // Furthermore, this method is called each time there is a redirect so
  // reinitializing it
  // also serves to clear it
  NSLog(@"Response");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  // Append the new data to the instance variable you declared
  NSLog(@"Data");
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
  // Return nil to indicate not necessary to store a cached response for this
  // connection
  return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  // The request is complete and data has been received
  // You can parse the stuff in your instance variable now
  NSLog(@"Finish loading");
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
  // The request has failed for some reason!
  // Check the error var
  NSLog(@"Error");
}

- (void)connection:(NSURLConnection *)connection
              didSendBodyData:(NSInteger)bytesWritten
            totalBytesWritten:(NSInteger)totalBytesWritten
    totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
  NSLog(@"-----------------DATA");
}

@end
