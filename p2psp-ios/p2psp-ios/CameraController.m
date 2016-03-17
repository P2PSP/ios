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
@property(nonatomic) IBOutlet UIBarButtonItem *bbiRecord;
@property(nonatomic) IBOutlet UIBarButtonItem *bbiStop;
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

  self.bbiStop = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                           target:self
                           action:@selector(onStop:)];

  [self.bbiStop setTintColor:[UIColor redColor]];

  self.bbiRecord = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                           target:self
                           action:@selector(onRecord:)];

  [self.bbiRecord setTintColor:[UIColor whiteColor]];

  [self updateBarButtonItem:self.bbiRecord inToolbar:self.tbRecord];
}

/**
 *  System override function to specify when should the status bar be hidden
 *
 *  @return Whether it should be hidden or not
 */
- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (void)updateBarButtonItem:(UIBarButtonItem *)bbi
                  inToolbar:(UIToolbar *)toolbar {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableArray *tbItems =
        [[NSMutableArray alloc] initWithArray:[toolbar items]];
    [tbItems replaceObjectAtIndex:1 withObject:bbi];

    [toolbar setItems:tbItems];
  });
}

- (IBAction)onRecord:(id)sender {
  NSLog(@"Recording...");
  [self updateBarButtonItem:self.bbiStop inToolbar:self.tbRecord];
}

- (IBAction)onStop:(id)sender {
  NSLog(@"Stop");
  [self updateBarButtonItem:self.bbiRecord inToolbar:self.tbRecord];
}

@end
