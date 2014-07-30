/*
 * Copyright 2014 David R. Bild
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "CDVCast.h"
#import "GCKImage+Dict.h"
#import "GCKDevice+Dict.h"

static const NSInteger DEBUG = 1;
static const NSInteger TRACE = 2;

static NSInteger LOG_LEVEL = 0;

static void logDebug(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  if (LOG_LEVEL >= DEBUG)
    NSLogv(format, args);
  va_end(args);
}

static void logTrace(NSString *format, ...) {
  va_list args;
  va_start(args, format);
  if (LOG_LEVEL >= TRACE)
    NSLogv(format, args);
  va_end(args);
}

@interface CDVCast ()

@property(nonatomic) NSString* appId;

@property(nonatomic) GCKDeviceScanner* scanner;
@property(nonatomic) GCKDeviceFilter* filter;

@property(nonatomic) NSString* scanListenerCallbackId;

@end

@implementation CDVCast

- (void) initialize:(CDVInvokedUrlCommand*)command {
  LOG_LEVEL = [[command.arguments objectAtIndex:1] integerValue];
  [GCKLogger sharedInstance].delegate = self;

  logDebug(@"CDVCast: [->] initialize()");

  self.appId = [command.arguments objectAtIndex:0];

  // Create scanner and filter
  self.scanner = [[GCKDeviceScanner alloc] init];
  GCKFilterCriteria *criteria = [GCKFilterCriteria criteriaForAvailableApplicationWithID:self.appId];
  self.filter = [[GCKDeviceFilter alloc] initWithDeviceScanner:self.scanner criteria:criteria];
  [self.filter addDeviceFilterListener:self];

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

  logDebug(@"CDVCast: [<-] initialize()");
}

- (void) startScan:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] startScan()");

  self.scanListenerCallbackId = command.callbackId;
  [self.scanner startScan];

  logDebug(@"CDVCast: [<-] startScan()");
}

- (void) stopScan:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] stopScan()");

  [self.scanner stopScan];
  self.scanListenerCallbackId = nil;

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

  logDebug(@"CDVCast: [<-] stopScan()");
}

#pragma mark - GCKDeviceFilterListener
- (void)deviceDidComeOnline:(GCKDevice *)device forDeviceFilter:(GCKDeviceFilter *)deviceFilter {
  logDebug(@"CDVCast: [->] deviceDidComeOnline()");

  if (self.scanListenerCallbackId != nil) {
    NSDictionary *message = @{
      @"type"   : @"online",
      @"device" : [device dictValue]
    };

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [result setKeepCallbackAsBool: YES];
    [self.commandDelegate sendPluginResult:result callbackId:self.scanListenerCallbackId];
  }

  logDebug(@"CDVCast: [<-] deviceDidComeOnline()");
}

- (void)deviceDidGoOffline:(GCKDevice *)device forDeviceFilter:(GCKDeviceFilter *)deviceFilter {
  logDebug(@"CDVCast: [->] deviceDidGoOffline()");

  if (self.scanListenerCallbackId != nil) {
    NSDictionary *message = @{
      @"type"   : @"offline",
      @"device" : [device dictValue]
    };

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
    [result setKeepCallbackAsBool: YES];
    [self.commandDelegate sendPluginResult:result callbackId:self.scanListenerCallbackId];
  }

  logDebug(@"CDVCast: [<-] deviceDidGoOffline()");
}

#pragma mark - GCKLoggerDelegate
- (void) logFromFunction:(const char *)function message:(NSString *)message {
    logTrace(@"GCKLogger: %@", message);
}

@end
