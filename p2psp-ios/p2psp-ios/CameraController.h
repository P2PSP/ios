//
//  CameraController.h
//  p2psp-ios
//
//  Created by Jorge on 17/3/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "VideoRecorder.h"

@interface CameraController : UIViewController<VideoRecorderDelegate>

- (void)setServerAddress:(NSString*)address;

@end
