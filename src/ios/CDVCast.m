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
#import "CDVCastChannel.h"
#import "GCKImage+Dict.h"
#import "GCKDevice+Dict.h"
#import "GCKSenderApplicationInfo+Dict.h"
#import "GCKApplicationMetadata+Dict.h"

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
@property(nonatomic) NSString* connectionListenerCallbackId;
@property(nonatomic) NSString* receiveMessageCallbackId;

@property(nonatomic) GCKDevice* device;
@property(nonatomic) GCKDeviceManager *deviceManager;
@property(nonatomic) CDVCastChannel *channel;

@end

@implementation CDVCast

- (void) sendIllegalAccessException:(NSString *)message command:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION
					      messageAsString:message];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) sendSuccess:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) sendError:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (BOOL) isScanning {
  return (self.scanner != nil) && self.scanner.scanning;
}

- (BOOL) isConnected {
  return (self.deviceManager != nil);
}

- (void) deviceDisconnected {
  logDebug(@"CDVCast: device disconnected");
  self.channel = nil;
  self.device = nil;
  self.deviceManager = nil;
}

- (void) connectToDevice {
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  self.deviceManager = [[GCKDeviceManager alloc] initWithDevice:self.device
					      clientPackageName:[info objectForKey:@"CFBundleIdentifier"]];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];
}

- (void) disconnectFromDevice {
  if (self.deviceManager != nil) {
    [self.deviceManager leaveApplication];
    [self.deviceManager disconnect];
    [self deviceDisconnected];
  }
}

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

  [self sendSuccess:command];

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

  [self sendSuccess:command];
  logDebug(@"CDVCast: [<-] stopScan()");
}

- (void) setConnectionListener:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] setConnectionListener()");
  
  self.connectionListenerCallbackId = command.callbackId;

  logDebug(@"CDVCast: [<-] setConnectionListener()");
}

- (void) connect:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] connect()");
  
  NSString *deviceId = [command.arguments objectAtIndex:0];

  // must not be already connected
  if (self.deviceManager != nil && [self isConnected]) {
    [self sendIllegalAccessException:@"Must disconnect from current device before connecting." command:command];
    goto ret;
  }

  // must be scanning so we can lookup device by id
  if (![self isScanning]) {
    [self sendIllegalAccessException:@"Must enable scanning before connecting to device." command:command];
    goto ret;
  }

  // lookup the device
  self.device = nil;
  self.deviceManager = nil;
  for (GCKDevice *device in self.scanner.devices) {
    if ([device.deviceID isEqualToString:deviceId]) {
      self.device = device;
      break;
    }
  }

  if (self.device == nil) {
    [self sendIllegalAccessException:@"Device not found." command:command];
    goto ret;
  }

  // connect to the device
  [self connectToDevice];
  [self sendSuccess:command];

 ret:
  logDebug(@"CDVCast: [<-] connect()");
}

- (void) disconnect:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] disconnect()");
  
  [self disconnectFromDevice];
  [self sendSuccess:command];

  logDebug(@"CDVCast: [<-] disconnect()");
}

- (void) receiveTextMessage:(CDVInvokedUrlCommand*)command {
  NSString *namespace = [command.arguments objectAtIndex:0];
  logDebug(@"CDVCast: [->] receiveTextMessage(%@)", namespace);

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  self.channel = [[CDVCastChannel alloc] initWithNamespace:namespace cast:self];
  [self.deviceManager addChannel:self.channel];
  self.receiveMessageCallbackId = command.callbackId;

 ret:
  logDebug(@"CDVCast: [<-] receiveTextMessage(%@)", namespace);
}

- (void) sendTextMessage:(CDVInvokedUrlCommand*)command {
  NSString *message = [command.arguments objectAtIndex:0];
  logDebug(@"CDVCast: [->] sendTextMessage(%@)", message);
  
  if (!self.channel) {
    [self sendIllegalAccessException:@"Must register received message listener first.." command:command];
    goto ret;
  }

  if ([self.channel sendTextMessage:message])
    [self sendSuccess:command];
  else
    [self sendError:command];

 ret:
  logDebug(@"CDVCast: [<-] sendTextMessage(%@)", message);
}

- (void) didReceiveTextMessage:(NSString *)message {
  logDebug(@"CDVCast: [->] didReceiveTextMessage(%@)", message);

  if (!(self.receiveMessageCallbackId == nil)) {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [result setKeepCallbackAsBool: YES];
    [self.commandDelegate sendPluginResult:result callbackId:self.receiveMessageCallbackId];
  } else {
    logDebug(@"CDVCast: Dropping received message because no listener registered.");
  }

  logDebug(@"CDVCast: [<-] didReceiveTextMessage(%@)", message);
}

- (void) launchApplication:(CDVInvokedUrlCommand*)command {
  BOOL relaunchIfRunning = [[command.arguments objectAtIndex:0] boolValue];
  logDebug(@"CDVCast: [->] launchApplication(%hhd)", relaunchIfRunning);

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if ([self.deviceManager launchApplication:self.appId relaunchIfRunning:relaunchIfRunning])
    [self sendSuccess:command];
  else
    [self sendError:command];
  
 ret:
  logDebug(@"CDVCast: [<-] launchApplication(%hhd)", relaunchIfRunning);
}

- (void) joinApplication:(CDVInvokedUrlCommand*)command {
  NSString *sessionId = nil;
  if ([command.arguments count] == 1) sessionId = [command.arguments objectAtIndex:0];
  logDebug(@"CDVCast: [->] joinApplication(%@)", sessionId);
  
  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if (sessionId == nil) {
    if ([self.deviceManager joinApplication:self.appId sessionID:sessionId])
      [self sendSuccess:command];
    else
      [self sendError:command];
  } else {
    if ([self.deviceManager joinApplication:self.appId])
      [self sendSuccess:command];
    else
      [self sendError:command];
  }

 ret:
  logDebug(@"CDVCast: [<-] joinApplication(%@)", sessionId);
}

- (void) leaveApplication:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] leaveApplication()");

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if ([self.deviceManager leaveApplication])
    [self sendSuccess:command];
  else
    [self sendError:command];

 ret:
  logDebug(@"CDVCast: [<-] leaveApplication()");
}

- (void) stopApplication:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] stopApplication()");
  
  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if ([self.deviceManager stopApplication])
    [self sendSuccess:command];
  else
    [self sendError:command];

 ret:
  logDebug(@"CDVCast: [<-] stopApplication()");
}

- (void) stopApplicationWithSessionId:(CDVInvokedUrlCommand*)command {
  NSString* sessionId = [command.arguments objectAtIndex:0];
  logDebug(@"CDVCast: [->] stopApplicationWithSessionId(%@)", sessionId);

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if ([self.deviceManager stopApplicationWithSessionID:sessionId])
    [self sendSuccess:command];
  else
    [self sendError:command];

 ret:
  logDebug(@"CDVCast: [<-] stopApplicationWithSessionId(%@)", sessionId);
}

- (void) setVolume:(CDVInvokedUrlCommand*)command {
  float volume = [[command.arguments objectAtIndex:0] floatValue];
  logDebug(@"CDVCast: [->] setVolume(%f)", volume);

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if ([self.deviceManager setVolume:volume])
    [self sendSuccess:command];
  else
    [self sendError:command];

 ret:
  logDebug(@"CDVCast: [<-] setVolume(%f)", volume);
}

- (void) setMuted:(CDVInvokedUrlCommand*)command {
  BOOL muted = [[command.arguments objectAtIndex:0] boolValue];
  logDebug(@"CDVCast: [->] setMuted(%hhd)", muted);

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if ([self.deviceManager setMuted:muted])
    [self sendSuccess:command];
  else
    [self sendError:command];

 ret:
  logDebug(@"CDVCast: [<-] setMuted(%hhd)", muted);
}

- (void) requestDeviceStatus:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] requestDeviceStatus()");

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  if ([self.deviceManager requestDeviceStatus])
    [self sendSuccess:command];
  else
    [self sendError:command];

 ret:
  logDebug(@"CDVCast: [<-] requestDeviceStatus()");
}

- (void) isConnected:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] isConnected()");

  BOOL ret = (self.deviceManager != nil)  && self.deviceManager.isConnected;
  CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:ret];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

  logDebug(@"CDVCast: [<-] isConnected()");
}

- (void) isConnectedToApp:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] isConnectedToApp()");
  
  BOOL ret = (self.deviceManager != nil) && self.deviceManager.isConnectedToApp;
  CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:ret];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

  logDebug(@"CDVCast: [<-] isConnectedToApp()");
}

- (void) isReconnecting:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] isReconnecting");
  
  BOOL ret = (self.deviceManager != nil) && self.deviceManager.isReconnecting;
  CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:ret];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

  logDebug(@"CDVCast: [<-] isReconnecting");
}

- (void) getReconnectTimeout:(CDVInvokedUrlCommand*)command {
  logDebug(@"CDVCast: [->] getReconnectTimeout");

  CDVPluginResult *result;

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  NSTimeInterval timeout = self.deviceManager.reconnectTimeout;
  result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble: timeout];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

 ret:
  logDebug(@"CDVCast: [<-] getReconnectTimeout");
}

- (void) setReconnectTimeout:(CDVInvokedUrlCommand*)command {
  NSTimeInterval timeout = [[command.arguments objectAtIndex:0] doubleValue];
  logDebug(@"CDVCast: [->] setReconnectTimeout(%f)", timeout);

  if (![self isConnected]) {
    [self sendIllegalAccessException:@"Must connect to device first." command:command];
    goto ret;
  }

  self.deviceManager.reconnectTimeout = timeout;
  [self sendSuccess:command];

 ret:
  logDebug(@"CDVCast: [<-] setReconnectTimeout");
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

#pragma mark - GCKDeviceManagerDelegate
- (void) deviceManagerDidConnect:(GCKDeviceManager*)deviceManager {
  logDebug(@"CDVCast: deviceManagerDidConnect()");
  
  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"connected",
    @"args" : @[]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager didFailToConnectWithError:(NSError*)error {
  logDebug(@"CDVCast: didFailToConnectWithError: %@", error);
  
  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"failedToConnect",
    @"args" : @[error.description]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager didDisconnectWithError:(NSError*)error {
  logDebug(@"CDVCast: didDisconnectWithError: %@", error);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"disconnected",
    @"args" : @[error.description]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager
         didConnectToCastApplication:(GCKApplicationMetadata*)applicationMetadata
         sessionID:(NSString*)sessionID
         launchedApplication:(BOOL)launchedApplication {
  logDebug(@"CDVCast: didConnectToCastApplication: %@ %@ %hhd", applicationMetadata, sessionID, launchedApplication);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"connectedToApplication",
    @"args" : @[[applicationMetadata dictValue], sessionID]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager didFailToConnectToApplicationWithError:(NSError*)error {
  logDebug(@"CDVCast: didFailToConnectToApplicationWithError: %@", error);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"failToConnectToApplication",
    @"args" : @[error.description]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager didDisconnectFromApplicationWithError:(NSError*)error {
  logDebug(@"CDVCast: didDisconnectFromApplicationWithError: %@", error);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"diconnectedFromApplication",
    @"args" : @[error.description]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager didFailToStopApplicationWithError:(NSError*)error {
  logDebug(@"CDVCast: didFailToStopApplicationWithError: %@", error);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: ropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"failedToStopApplication",
    @"args" : @[error.description]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager
         didReceiveStatusForApplication:(GCKApplicationMetadata*)applicationMetadata {
  logDebug(@"CDVCast: didReceiveStatusForApplication: %@", applicationMetadata);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"applicationStatusReceived",
    @"args" : @[[applicationMetadata dictValue]]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager 
         volumeDidChangeToLevel:(float)volumeLevel 
	 isMuted:(BOOL)isMuted {
  logDebug(@"CDVCast: volumeDidChangeToLevel: %f %hhd", volumeLevel, isMuted);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"volumeChanged",
    @"args" : @[[NSNumber numberWithFloat: volumeLevel], [NSNumber numberWithBool:isMuted]]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

- (void) deviceManager:(GCKDeviceManager*)deviceManager 
         didReceiveActiveInputStatus:(GCKActiveInputStatus)activeInputStatus {
  logDebug(@"CDVCast: didReceiveActiveInputStatus: %d", activeInputStatus);

  if (self.connectionListenerCallbackId == nil) {
    logDebug(@"CDVCast: Dropping callback because no connection listener was set.");
    return;
  }
  
  NSDictionary *message = @{
    @"type" : @"ActiveInputStatusReceived",
    @"args" : @[[NSNumber numberWithInteger:activeInputStatus]]
  };

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:message];
  [result setKeepCallbackAsBool: YES];
  [self.commandDelegate sendPluginResult:result callbackId:self.connectionListenerCallbackId];
}

#pragma mark - GCKLoggerDelegate
- (void) logFromFunction:(const char *)function message:(NSString *)message {
    logTrace(@"GCKLogger: %@", message);
}

@end