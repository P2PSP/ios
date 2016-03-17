//
//  CameraController.m
//  p2psp-ios
//
//  Created by Jorge on 17/3/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import "CameraController.h"

@interface CameraController ()
@property(weak, nonatomic) IBOutlet UIToolbar *tbClose;
@end

@implementation CameraController

- (void)viewDidLoad {
  [self.tbClose setBackgroundImage:[UIImage new]
                forToolbarPosition:UIBarPositionAny
                        barMetrics:UIBarMetricsDefault];
  [self.tbClose setShadowImage:[UIImage new]
            forToolbarPosition:UIToolbarPositionAny];
}

@end
