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
@property(weak, nonatomic) IBOutlet UIToolbar *tbRecord;
@end

@implementation CameraController

- (void)viewDidLoad {
  // Set toolbars transparent
  [self.tbClose setBackgroundImage:[UIImage new]
                forToolbarPosition:UIBarPositionAny
                        barMetrics:UIBarMetricsDefault];
  [self.tbClose setShadowImage:[UIImage new]
            forToolbarPosition:UIToolbarPositionAny];

  [self.tbRecord setBackgroundImage:[UIImage new]
                 forToolbarPosition:UIBarPositionAny
                         barMetrics:UIBarMetricsDefault];
  [self.tbRecord setShadowImage:[UIImage new]
             forToolbarPosition:UIToolbarPositionAny];

  // Hide navigation bar
  [self.navigationController setNavigationBarHidden:YES];
}

/**
 *  System override function to specify when should the status bar be hidden
 *
 *  @return Whether it should be hidden or not
 */
- (BOOL)prefersStatusBarHidden {
  return YES;
}

@end
