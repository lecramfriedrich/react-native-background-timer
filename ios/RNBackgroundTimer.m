//
//  RNBackgroundTimer.m
//  react-native-background-timer
//
//  Created by IjzerenHein on 06-09-2016.
//  Copyright (c) ATO Gear. All rights reserved.
//

@import UIKit;
#import "RNBackgroundTimer.h"
#import <AVFoundation/AVFoundation.h>

@implementation RNBackgroundTimer {
    UIBackgroundTaskIdentifier bgTask;
    int delay;
}

AVAudioPlayer *audioPlayer;
UIBackgroundTaskIdentifier backgroundTask;
NSTimer *timer;

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents { return @[@"backgroundTimer", @"backgroundTimer.timeout"]; }

- (void) _start
{
    AVAudioSession *aSession = [AVAudioSession sharedInstance];
    [aSession setCategory:AVAudioSessionCategoryPlayback
              withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                    error:nil];
    [aSession setMode:AVAudioSessionModeDefault error:nil];
    [aSession setActive: YES error: nil];
    playAudio();
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleAudioSessionInterruption:)
                                               name:AVAudioSessionInterruptionNotification
                                             object:aSession];
  backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"bgTask" expirationHandler:^{
    // Clean up any unfinished task business by marking where you
    // stopped or ending the task outright.
      [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
      backgroundTask = UIBackgroundTaskInvalid;
  }];
  timer = [NSTimer scheduledTimerWithTimeInterval: 100.0
                                           target: self
                                         selector:@selector(onTick:)
                                         userInfo: nil repeats:YES];
}

-(void)onTick:(NSTimer *)timer {
  playAudio();

  [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
  backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"bgTask" expirationHandler:^{
    // Clean up any unfinished task business by marking where you
    // stopped or ending the task outright.
      [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
      backgroundTask = UIBackgroundTaskInvalid;
  }];
}

- (void) handleAudioSessionInterruption:(NSNotification *) notification
{
    NSNumber *interruptionType = [[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey];
    NSNumber *interruptionOption = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
      switch (interruptionType.unsignedIntegerValue) {
          case AVAudioSessionInterruptionTypeBegan:{
              // • Audio has stopped, already inactive
              // • Change state of UI, etc., to reflect non-playing state
          } break;
          case AVAudioSessionInterruptionTypeEnded:{
              // • Make session active
              // • Update user interface
              // • AVAudioSessionInterruptionOptionShouldResume option
              if (interruptionOption.unsignedIntegerValue == AVAudioSessionInterruptionOptionShouldResume) {
                  // Here you should continue playback.
                  playAudio();
              }
          } break;
          default:
              break;
      }
}

void playAudio() {
  NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"blank"  ofType:@"wav"];
  NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
  AVAudioSession *session = [AVAudioSession sharedInstance];
  [session setCategory: AVAudioSessionCategoryPlayback
           withOptions:AVAudioSessionCategoryOptionMixWithOthers error: nil];
  [session setActive: YES error: nil];
  audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
  audioPlayer.numberOfLoops = -1;
  audioPlayer.prepareToPlay;
  [audioPlayer play];
}

- (void) _stop
{
  //[[NSNotificationCenter defaultCenter] removeObserver:self];
    if (timer != nil) {
        timer.invalidate;
    }
    
    if (audioPlayer != nil) {
        audioPlayer.stop;
    }
  timer = nil;
    audioPlayer = nil;
}

RCT_EXPORT_METHOD(start:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self _start];
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(stop:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self _stop];
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(setTimeout:(int)timeoutId
                     timeout:(int)timeout
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if ([self bridge] != nil) {
            [self sendEventWithName:@"backgroundTimer.timeout" body:[NSNumber numberWithInt:timeoutId]];
        }
    });
    resolve([NSNumber numberWithBool:YES]);
}

@end
