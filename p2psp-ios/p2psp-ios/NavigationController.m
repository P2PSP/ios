//
//  NavigationController.m
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 21/03/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import "NavigationController.h"

@implementation NavigationController

- (BOOL)shouldAutorotate {
  return [self.visibleViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return [self.visibleViewController supportedInterfaceOrientations];
}

@end
