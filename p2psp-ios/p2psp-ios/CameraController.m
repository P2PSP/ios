//
//  CameraController.m
//  p2psp-ios
//
//  Created by Jorge on 17/3/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "CameraController.h"
#import "HTTPClient.h"
#import "Server.h"

@interface CameraController ()
@property(weak, nonatomic) IBOutlet UIToolbar *tbTop;
@property(weak, nonatomic) IBOutlet UIToolbar *tbRecord;
@property(nonatomic) IBOutlet UIBarButtonItem *bbiRecord;
@property(nonatomic) IBOutlet UIBarButtonItem *bbiStop;
@property(weak, nonatomic) IBOutlet UIView *vCameraPreviewContainer;
@property(weak, nonatomic) IBOutlet UITextField *tfChannelTitle;
@property(weak, nonatomic) IBOutlet UITextView *tvChannelDescription;
@property(weak, nonatomic) IBOutlet UIScrollView *svChannelFormWrapper;
@property(weak, nonatomic) IBOutlet UIView *vChannelFormContainer;
@property(weak, nonatomic)
    IBOutlet UIActivityIndicatorView *aivHTTPLoadingIndicator;
@property(weak, nonatomic) IBOutlet UIButton *bChannelOK;

@property(nonatomic) HTTPClient *mediaSender;
@property(nonatomic) VideoRecorder *videoRecorder;
@property(nonatomic, weak) IBOutlet UIView *preview;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *bbiChannelTitle;

@property(nonatomic) NSString *address;
@property(nonatomic) NSString *channelID;
@property(nonatomic) Server *server;

@end

@implementation CameraController

- (void)viewDidLoad {
  [[UIDevice currentDevice]
      setValue:[NSNumber numberWithInt:UIInterfaceOrientationPortrait]
        forKey:@"orientation"];

  [self registerForKeyboardNotifications];

  // Set toolbars transparent
  [self.tbTop setBackgroundImage:[UIImage new]
              forToolbarPosition:UIBarPositionAny
                      barMetrics:UIBarMetricsDefault];
  [self.tbTop setShadowImage:[UIImage new]
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

  self.server = [[Server alloc] initWithServerURL:self.address];

  // Setup video recorder and http client
  self.mediaSender = [[HTTPClient alloc]
      initWithServerAddress:
          [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/emit",
                                                          self.address]]];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewDidAppear:(BOOL)animated {
  self.videoRecorder =
      [[VideoRecorder alloc] initWithWidth:self.view.bounds.size.width
                                 andHeight:self.view.bounds.size.height];
  [self.videoRecorder setDelegate:self];
  self.videoRecorder.preview.frame = self.vCameraPreviewContainer.bounds;
  [self.vCameraPreviewContainer addSubview:[_videoRecorder preview]];
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

  [self deleteTempDirFile];

  [_videoRecorder
      startRecordingForDropFileWithSeconds:1
                                 frameRate:30
                              captureWidth:self.vCameraPreviewContainer.bounds
                                               .size.width
                             captureHeight:self.vCameraPreviewContainer.bounds
                                               .size.height];
}

- (IBAction)onStop:(id)sender {
  NSLog(@"Stop");
  [self updateBarButtonItem:self.bbiRecord inToolbar:self.tbRecord];
  [self.videoRecorder stopRecording];
}

- (IBAction)deleteTempDirFile {
  NSError *err = nil;
  NSArray *filesArray = [[NSFileManager defaultManager]
      contentsOfDirectoryAtPath:NSTemporaryDirectory()
                          error:&err];
  for (NSString *str in filesArray) {
    NSString *path =
        [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), str];
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&err]) {
      NSLog(@"Error deleting existing file");
    }
  }
}

#pragma mark VideoRecorderDelegate

- (void)videoRecorder:(VideoRecorder *)videoRecorder
    recoringDidFinishToOutputFileURL:(NSURL *)outputFileURL
                               error:(NSError *)error {
  // NSLog(@"recording finished URL: %@", outputFileURL);

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.server emit:outputFileURL
              withHandler:^(NSError *error) {
                if (!error) {
                  [[NSFileManager defaultManager] removeItemAtURL:outputFileURL
                                                            error:nil];
                }
              }];

        /*[self.mediaSender postVideo:outputFileURL];
        [[NSFileManager defaultManager] removeItemAtPath:outputFileURL
                                                   error:nil];*/
      });

  // [self saveToCameraRoll:outputFileURL];
}

// TODO: This selector is to be able to watch recorded videos
- (void)saveToCameraRoll:(NSURL *)srcURL {
  NSLog(@"srcURL: %@", srcURL);

  ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
  ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock = ^(
      NSURL *newURL, NSError *error) {
    if (error) {
      NSLog(@"Error writing image with metadata to Photo Library: %@", error);
    } else {
      NSLog(@"Wrote image with metadata to Photo Library %@",
            newURL.absoluteString);
    }
  };

  if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:srcURL]) {
    [library writeVideoAtPathToSavedPhotosAlbum:srcURL
                                completionBlock:videoWriteCompletionBlock];
  }
}

- (void)setServerAddress:(NSString *)address {
  self.address = address;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // TODO: Remove channel from server before leaving this scene
  [self.videoRecorder stopRecording];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

/**
 *  Trigered when OK button is pressed. Make an HTTP POST to server to add a new
 * channel, and wait the response channel id
 *
 *  @param sender The OK button
 */
- (IBAction)onChannelOK:(id)sender {
  // TODO: Read and validate inputs views (title and description)

  if ([self.tfChannelTitle.text isEqualToString:@""]) {
    return;
  }

  self.bbiChannelTitle.title = self.tfChannelTitle.text;

  // Display and animate activity indicator, disable inputs
  [self.tfChannelTitle setEnabled:NO];
  [self.tvChannelDescription setEditable:NO];
  [self.tvChannelDescription setSelectable:NO];
  [self.tvChannelDescription setSelectable:NO];
  [self.bChannelOK setEnabled:NO];
  [self.view endEditing:YES];
  [self.aivHTTPLoadingIndicator startAnimating];

  // Common handler callback for both create and update channel info
  void (^completionHandler)(NSError *error) = ^(NSError *error) {

    dispatch_async(dispatch_get_main_queue(), ^{
      // TODO: Handle errors

      [self.tfChannelTitle setEnabled:YES];
      [self.tvChannelDescription setEditable:YES];
      [self.tvChannelDescription setSelectable:YES];
      [self.tvChannelDescription setSelectable:YES];
      [self.bChannelOK setEnabled:YES];
      [self.aivHTTPLoadingIndicator stopAnimating];

      // Hide wrapper form view
      CATransition *animation = [CATransition animation];
      animation.type = kCATransitionFade;
      animation.duration = 0.2;
      [self.svChannelFormWrapper.layer addAnimation:animation forKey:nil];
      [self.svChannelFormWrapper setHidden:YES];
    });

  };

  if (!self.channelID) {
    // Make http post with data
    [self.server createChannelwithTitle:self.tfChannelTitle.text
                         andDescription:self.tvChannelDescription.text
                            withHandler:^(NSString *channelID, NSError *error) {

                              // Store the channel supplied by server
                              self.channelID = channelID;
                              NSLog(@"ID: %@", channelID);

                              completionHandler(error);

                            }];

  } else {
    // Make http post with data
    [self.server updateChannel:self.channelID
                     withTitle:self.tfChannelTitle.text
                andDescription:self.tvChannelDescription.text
                   withHandler:^(NSError *error) {

                     completionHandler(error);

                   }];
  }
}

- (IBAction)onChannelEdit:(id)sender {
  // Show wrapper form view
  CATransition *animation = [CATransition animation];
  animation.type = kCATransitionFade;
  animation.duration = 0.2;
  [self.svChannelFormWrapper.layer addAnimation:animation forKey:nil];
  [self.svChannelFormWrapper setHidden:NO];
}

/**
 *  Dismiss the kyeboard when user taps outside a textinput
 *
 *  @param sender The gesture input
 */
- (IBAction)onKeyboardDismiss:(id)sender {
  [self.view endEditing:YES];
}

/**
 *  This functions help us to deal with keyboard overlapping
 */
- (void)registerForKeyboardNotifications {
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWasShown:)
             name:UIKeyboardWillShowNotification
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillBeHidden:)
             name:UIKeyboardWillHideNotification
           object:nil];
}

/**
 *  Called when the UIKeyboardWillShowNotification is sent.
 *
 *  @param aNotification A NSNotification object
 */
- (void)keyboardWasShown:(NSNotification *)aNotification {
  NSDictionary *info = [aNotification userInfo];
  CGSize kbSize =
      [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
  self.svChannelFormWrapper.contentInset = contentInsets;
  self.svChannelFormWrapper.scrollIndicatorInsets = contentInsets;

  // If active text field is hidden by keyboard, scroll it so it's visible
  // Your application might not need or want this behavior.
  CGRect aRect = self.view.frame;
  aRect.size.height -= kbSize.height;
  if (aRect.size.height < (self.vChannelFormContainer.frame.origin.y +
                           self.vChannelFormContainer.frame.size.height)) {
    CGPoint scrollPoint =
        CGPointMake(0.0, ((self.vChannelFormContainer.frame.origin.y +
                           self.vChannelFormContainer.frame.size.height)) -
                             aRect.size.height);
    [self.svChannelFormWrapper setContentOffset:scrollPoint animated:YES];
  }
}

/**
 *  Called when the UIKeyboardWillHideNotification is sent
 *
 *  @param aNotification A NSNotification object
 */
- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  self.svChannelFormWrapper.contentInset = contentInsets;
  self.svChannelFormWrapper.scrollIndicatorInsets = contentInsets;
}

@end
