//
//  VideoRecorder.h
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 17/03/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

#define MAX_RECORDING_SECOND 86400

@protocol VideoRecorderDelegate;

@interface VideoRecorder
    : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,
               AVCaptureAudioDataOutputSampleBufferDelegate>

@property(nonatomic) BOOL isRecording;
@property(nonatomic) UIView* preview;
@property(nonatomic, weak) id<VideoRecorderDelegate> delegate;

- (id)initWithWidth:(uint)width andHeight:(uint)height;

- (BOOL)startRecording;
- (BOOL)startRecordingForDropFileWithSeconds:(uint)sec
                                   frameRate:(uint)frameRate
                                captureWidth:(uint)width
                               captureHeight:(uint)height;
- (BOOL)stopRecording;
- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation;

@end

@protocol VideoRecorderDelegate
@required
- (void)videoRecorder:(VideoRecorder*)videoRecorder
    recoringDidFinishToOutputFileURL:(NSURL*)fileURL
                               error:(NSError*)error;
@end