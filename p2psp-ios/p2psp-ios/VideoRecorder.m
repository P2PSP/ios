//
//  VideoRecorder.m
//  p2psp-ios
//
//  Created by Antonio Vicente Martín on 17/03/16.
//  Copyright © 2016 P2PSP. All rights reserved.
//

#import "VideoRecorder.h"

@interface VideoRecorder ()

@property(nonatomic) AVCaptureSession* captureSession;
@property(nonatomic) AVCaptureVideoDataOutput* videoOutput;
@property(nonatomic) AVCaptureAudioDataOutput* audioOutput;
@property(nonatomic) AVCaptureVideoPreviewLayer* prevLayer;

@property(nonatomic) uint frameRate;
@property(nonatomic) uint64_t secondsForFileCut;
@property(nonatomic) uint captureWidth;
@property(nonatomic) uint captureHeight;

@property(nonatomic) NSDictionary* videoCompressionProps;
@property(nonatomic) NSDictionary* videoSettings;
@property(nonatomic) NSDictionary* audioSettings;

@property(nonatomic) AVCaptureConnection* videoConnection;
@property(nonatomic) AVCaptureConnection* audioConnection;

@property(nonatomic) AVAssetWriter* currentVideoWriter;
@property(nonatomic) AVAssetWriterInput* currentVideoWriterInput;
@property(nonatomic) AVAssetWriterInput* currentAudioWriterInput;
@property(nonatomic) AVAssetWriter* standbyVideoWriter;
@property(nonatomic) AVAssetWriterInput* standbyVideoWriterInput;
@property(nonatomic) AVAssetWriterInput* standbyAudioWriterInput;

@property(nonatomic) CMTime lastVideoFileWriteSampleTime;
@property(nonatomic) CMTime lastAudioFileWriteSampleTime;

@property(nonatomic) AVCaptureVideoOrientation videoOrientation;
@property(nonatomic) AVCaptureVideoOrientation referenceOrientation;

@end

@implementation VideoRecorder

- (id)init {
  self = [super init];
  
  if (self != nil) {
    self.referenceOrientation = UIDeviceOrientationPortrait;
    
    [self initCaptureSession];
  }
  
  return self;
}

- (void)initCaptureSession {
  NSError* error;
  // Setup the video input
  AVCaptureDevice* videoDevice =
  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  // Create a device input with the device and add it to the session.
  AVCaptureDeviceInput* videoInput =
  [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
  // Setup the video output
  self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  self.videoOutput.alwaysDiscardsLateVideoFrames = NO;
  self.videoOutput.videoSettings = [NSDictionary
                                    dictionaryWithObject:
                                    [NSNumber
                                     numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                                    forKey:(id)kCVPixelBufferPixelFormatTypeKey];
  
  // Setup the audio input
  AVCaptureDevice* audioDevice =
  [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  AVCaptureDeviceInput* audioInput =
  [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
  // Setup the audio output
  self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
  
  // Create the session
  self.captureSession = [[AVCaptureSession alloc] init];
  [self.captureSession addInput:videoInput];
  [self.captureSession addInput:audioInput];
  [self.captureSession addOutput:self.videoOutput];
  [self.captureSession addOutput:self.audioOutput];
  self.videoConnection =
  [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
  self.audioConnection =
  [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
  
  self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
  
  // Setup the queue
  dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
  [self.videoOutput setSampleBufferDelegate:self queue:queue];
  [self.audioOutput setSampleBufferDelegate:self queue:queue];
  
  self.videoOrientation = [self.videoConnection videoOrientation];
  
  /*We start the capture*/
  [self.captureSession startRunning];
}

- (void)initVideoSettings {
  // Add video input
  float bitsPerPixel = 11.4;  // This bitrate matches the quality produced by
                              // AVCaptureSessionPresetHigh.
  int bitPerSecond = self.captureWidth * self.captureHeight * bitsPerPixel;
  self.videoCompressionProps = [[NSDictionary alloc]
                                initWithObjectsAndKeys:[NSNumber numberWithDouble:bitPerSecond],
                                AVVideoAverageBitRateKey,
                                [NSNumber numberWithInteger:self.frameRate],
                                AVVideoMaxKeyFrameIntervalKey, nil];
  
  self.videoSettings = [NSDictionary
                        dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                        [NSNumber numberWithInt:self.captureWidth],
                        AVVideoWidthKey,
                        [NSNumber numberWithInt:self.captureHeight],
                        AVVideoHeightKey, self.videoCompressionProps,
                        AVVideoCompressionPropertiesKey, nil];
}

- (void)initAudioSettings {
  // Add the audio input
  AudioChannelLayout acl;
  bzero(&acl, sizeof(acl));
  // acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
  acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
  
  self.audioSettings = nil;
  self.audioSettings = [[NSDictionary alloc]
                        initWithObjectsAndKeys:[NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                        AVFormatIDKey, [NSNumber numberWithInt:2],
                        AVNumberOfChannelsKey,
                        [NSNumber numberWithFloat:44100.0],
                        AVSampleRateKey, [NSNumber numberWithInt:64000],
                        AVEncoderBitRateKey,
                        [NSData dataWithBytes:&acl length:sizeof(acl)],
                        AVChannelLayoutKey, nil];
}

- (NSURL*)outputVideoURL {
  static int index = 0;
  
  return
  [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@video_%d%@",
                          NSTemporaryDirectory(),
                          index++, @".mp4"]];
}

- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:
(AVCaptureVideoOrientation)orientation {
  switch (orientation) {
    case AVCaptureVideoOrientationPortrait:
      return 0.0;
    case AVCaptureVideoOrientationPortraitUpsideDown:
      return M_PI;
    case AVCaptureVideoOrientationLandscapeRight:
      return -M_PI_2;
    case AVCaptureVideoOrientationLandscapeLeft:
      return M_PI_2;
    default:
      break;
  }
  
  return 0.0;
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:
(AVCaptureVideoOrientation)orientation {
  CGAffineTransform transform = CGAffineTransformIdentity;
  
  // Calculate offsets from an arbitrary reference orientation (portrait)
  CGFloat orientationAngleOffset =
  [self angleOffsetFromPortraitOrientationToOrientation:orientation];
  CGFloat videoOrientationAngleOffset = [self
                                         angleOffsetFromPortraitOrientationToOrientation:self.videoOrientation];
  
  // Find the difference in angle between the passed in orientation and the
  // current video orientation
  CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
  transform = CGAffineTransformMakeRotation(angleOffset);
  
  return transform;
}

- (BOOL)setupCurrentVideoWriter {
  NSError* error = nil;
  NSURL* outputVideoURL = [self outputVideoURL];
  
  self.currentVideoWriter = [[AVAssetWriter alloc] initWithURL:outputVideoURL
                                                      fileType:AVFileTypeMPEG4
                                                         error:&error];
  NSParameterAssert(self.currentVideoWriter);
  [self.currentVideoWriter setMovieTimeScale:0];
  [self.currentVideoWriter setShouldOptimizeForNetworkUse:YES];
  
  self.currentVideoWriterInput =
  [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                 outputSettings:self.videoSettings];
  NSParameterAssert(self.currentVideoWriterInput);
  [self.currentVideoWriterInput setMediaTimeScale:0];
  self.currentVideoWriterInput.expectsMediaDataInRealTime = YES;
  self.currentVideoWriterInput.transform =
  [self transformFromCurrentVideoOrientationToOrientation:
   self.referenceOrientation];
  
  self.currentAudioWriterInput =
  [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                 outputSettings:self.audioSettings];
  self.currentAudioWriterInput.expectsMediaDataInRealTime = YES;
  
  // add input
  [self.currentVideoWriter addInput:self.currentVideoWriterInput];
  [self.currentVideoWriter addInput:self.currentAudioWriterInput];
  
  return YES;
}

- (BOOL)setupStandbyVideoWriter {
  NSError* error = nil;
  NSURL* outputVideoURL = [self outputVideoURL];
  self.standbyVideoWriter = [[AVAssetWriter alloc] initWithURL:outputVideoURL
                                                      fileType:AVFileTypeMPEG4
                                                         error:&error];
  NSParameterAssert(self.standbyVideoWriter);
  [self.standbyVideoWriter setMovieTimeScale:0];
  [self.standbyVideoWriter setShouldOptimizeForNetworkUse:YES];
  
  self.standbyVideoWriterInput =
  [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                 outputSettings:self.videoSettings];
  NSParameterAssert(self.standbyVideoWriterInput);
  
  self.standbyVideoWriterInput.expectsMediaDataInRealTime = YES;
  self.standbyVideoWriterInput.transform =
  [self transformFromCurrentVideoOrientationToOrientation:
   self.referenceOrientation];
  
  self.standbyAudioWriterInput =
  [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                 outputSettings:self.audioSettings];
  self.standbyAudioWriterInput.expectsMediaDataInRealTime = YES;
  
  // add input
  [self.standbyVideoWriter addInput:self.standbyVideoWriterInput];
  [self.standbyVideoWriter addInput:self.standbyAudioWriterInput];
  
  return YES;
}

- (void)switchVideoWriter {
  self.currentVideoWriter = self.standbyVideoWriter;
  self.currentVideoWriterInput = self.standbyVideoWriterInput;
  self.currentAudioWriterInput = self.standbyAudioWriterInput;
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{
                   [self setupStandbyVideoWriter];
                 });
}

- (void)onVideoSample:(CMSampleBufferRef)sampleBuffer {
  if (self.isRecording) {
    if (self.currentVideoWriter.status > AVAssetWriterStatusWriting) {
      NSLog(@"Warning: writer status is %d", self.currentVideoWriter.status);
      if (self.currentVideoWriter.status == AVAssetWriterStatusFailed)
        NSLog(@"Error: %@", self.currentVideoWriter.error);
      return;
    }
    
    if (self.currentVideoWriterInput.readyForMoreMediaData == YES) {
      if (![self.currentVideoWriterInput appendSampleBuffer:sampleBuffer])
        NSLog(@"Unable to write to video input");
    } else {
      NSLog(@"readyForMoreMediaData(video) == NO");
    }
  }
}

- (void)onAudioSample:(CMSampleBufferRef)sampleBuffer {
  if (self.isRecording) {
    if (self.currentVideoWriter.status > AVAssetWriterStatusWriting) {
      NSLog(@"Warning: writer status is %d", self.currentVideoWriter.status);
      if (self.currentVideoWriter.status == AVAssetWriterStatusFailed)
        NSLog(@"Error: %@", self.currentVideoWriter.error);
      return;
    }
    
    if (self.currentAudioWriterInput.readyForMoreMediaData == YES) {
      if (![self.currentAudioWriterInput appendSampleBuffer:sampleBuffer])
        NSLog(@"Unable to write to audio input");
    } else {
      NSLog(@"readyForMoreMediaData(audio) == NO");
    }
  }
}

- (void)captureOutput:(AVCaptureOutput*)captureOutput
didVideoOutputSampleBuffer:(CMSampleBufferRef)sampleBufferOrg
       fromConnection:(AVCaptureConnection*)connection {
  if (!CMSampleBufferDataIsReady(sampleBufferOrg)) {
    NSLog(@"sample buffer is not ready. Skipping sample");
    return;
  }
  
  CMSampleBufferRef sampleBuffer;
  CMSampleTimingInfo timingInfo;
  CMSampleBufferGetSampleTimingInfo(sampleBufferOrg, 0, &timingInfo);
  
  CMTime pts = timingInfo.presentationTimeStamp;
  timingInfo.duration = CMTimeMake(pts.timescale / 30, pts.timescale);
  CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBufferOrg, 1,
                                        &timingInfo, &sampleBuffer);
  
  CMTime videoSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  
  if ((videoSampleTime.value - self.lastVideoFileWriteSampleTime.value) <
      (videoSampleTime.timescale * self.secondsForFileCut) ||
      self.lastVideoFileWriteSampleTime.value == 0 /*first sample write*/) {
    if (self.currentVideoWriter.status != AVAssetWriterStatusWriting &&
        self.currentVideoWriter.status != AVAssetWriterStatusFailed) {
      if ([self.currentVideoWriter startWriting]) {
        self.lastVideoFileWriteSampleTime = videoSampleTime;
        
        // Start new video
        [self.currentVideoWriter startSessionAtSourceTime:pts];
      }
    }
    // write sample
    if (self.currentVideoWriter.status == AVAssetWriterStatusWriting)
      [self onVideoSample:sampleBuffer];
  } else {
    [self.currentVideoWriter finishWriting];
    [self.delegate videoRecorder:self
recoringDidFinishToOutputFileURL:self.currentVideoWriter.outputURL
                           error:nil];
    
    // Prepare new video file
    [self switchVideoWriter];
    
    if (self.currentVideoWriter.status != AVAssetWriterStatusWriting &&
        self.currentVideoWriter.status != AVAssetWriterStatusFailed) {
      if ([self.currentVideoWriter startWriting]) {
        self.lastVideoFileWriteSampleTime = videoSampleTime;
        
        // Start new video
        [self.currentVideoWriter startSessionAtSourceTime:pts];
      }
    }
    
    // write sample
    if (self.currentVideoWriter.status == AVAssetWriterStatusWriting)
      [self onVideoSample:sampleBuffer];
  }
  
  CFRelease(sampleBuffer);
}

- (void)captureOutput:(AVCaptureOutput*)captureOutput
didAudioOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection*)connection {
  if (!CMSampleBufferDataIsReady(sampleBuffer)) {
    NSLog(@"sample buffer is not ready. Skipping sample");
    return;
  }
  
  CMTime audioSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
  
  if ((audioSampleTime.value - self.lastAudioFileWriteSampleTime.value) <
      (audioSampleTime.timescale * self.secondsForFileCut) ||
      self.lastAudioFileWriteSampleTime.value == 0 /*first sample write*/) {
    // write sample
    if (self.currentVideoWriter.status == AVAssetWriterStatusWriting)
      [self onAudioSample:sampleBuffer];
  } else {
    // write sample
    if (self.currentVideoWriter.status == AVAssetWriterStatusWriting)
      [self onAudioSample:sampleBuffer];
  }
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput*)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection*)connection {
  if (self.isRecording) {
    if (captureOutput == self.videoOutput) {
      [self captureOutput:captureOutput
didVideoOutputSampleBuffer:sampleBuffer
           fromConnection:connection];
    } else if (captureOutput == self.audioOutput) {
      [self captureOutput:captureOutput
didAudioOutputSampleBuffer:sampleBuffer
           fromConnection:connection];
    }
  }
}

#pragma mark -
#pragma mark Camcorder interface
- (BOOL)startRecording {
  if (self.isRecording) {
    return NO;
  }
  [self startRecordingForDropFileWithSeconds:MAX_RECORDING_SECOND
                                   frameRate:30
                                captureWidth:480
                               captureHeight:320];
  return YES;
}

- (BOOL)startRecordingForDropFileWithSeconds:(uint)sec
                                   frameRate:(uint)fRate
                                captureWidth:(uint)width
                               captureHeight:(uint)height {
  if (self.isRecording) {
    return NO;
  }
  
  self.secondsForFileCut = sec;
  self.frameRate = fRate;
  self.captureWidth = width;
  self.captureHeight = height;
  
  self.videoConnection.videoMinFrameDuration = CMTimeMake(1, self.frameRate);
  self.videoConnection.videoMaxFrameDuration = CMTimeMake(1, self.frameRate);
  
  self.preview = [[UIView alloc]
                  initWithFrame:CGRectMake(0, 0, self.captureWidth, self.captureHeight)];
  
  [self initVideoSettings];
  [self initAudioSettings];
  
  [self setupCurrentVideoWriter];
  [self setupStandbyVideoWriter];
  
  // set preview
  self.prevLayer =
  [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
  self.prevLayer.frame = self.preview.layer.bounds;
  self.prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [self.preview.layer addSublayer:self.prevLayer];
  
  self.isRecording = YES;
  return YES;
}

- (BOOL)stopRecording {
  if (!self.isRecording) {
    return NO;
  }
  self.isRecording = NO;
  _lastVideoFileWriteSampleTime.value = 0;
  _lastAudioFileWriteSampleTime.value = 0;
  
  [self.delegate videoRecorder:self
recoringDidFinishToOutputFileURL:self.currentVideoWriter.outputURL
                         error:self.currentVideoWriter.error];
  
  return YES;
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)orientation {
  self.referenceOrientation = orientation;
}

@end
