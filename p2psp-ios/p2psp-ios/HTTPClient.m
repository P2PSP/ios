//
//  HTTPClient.m
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 17/03/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import "HTTPClient.h"

@implementation HTTPClient

NSInputStream *inputStream;
NSOutputStream *outputStream;

- (void)createConnection:(NSURL *)serverAddress {
  NSMutableURLRequest *request =
      [NSMutableURLRequest requestWithURL:serverAddress];

  [request setHTTPMethod:@"POST"];

  [request addValue:@"application/octet-stream"
      forHTTPHeaderField:@"Content-Type"];
  [request addValue:@"chunked" forHTTPHeaderField:@"Transfer-Encoding"];

  // Input/output stream binding
  CFReadStreamRef readStream = NULL;
  CFWriteStreamRef writeStream = NULL;
  CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 524288);
  inputStream = CFBridgingRelease(readStream);
  outputStream = CFBridgingRelease(writeStream);
  [request setHTTPBodyStream:inputStream];

  [outputStream open];

  NSURLConnection *conn =
      [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)postVideo:(NSURL *)locaFilelURL {
  NSData *videoData = [NSData dataWithContentsOfURL:locaFilelURL];
  [outputStream write:[videoData bytes] maxLength:[videoData length]];
}

- (void)closeConnetion {
  uint8_t eof = EOF;
  [outputStream write:&eof maxLength:sizeof(eof)];
  [outputStream close];
  [inputStream close];
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
