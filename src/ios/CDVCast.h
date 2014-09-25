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

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <GoogleCast/GoogleCast.h>

@interface CDVCast : CDVPlugin<GCKDeviceScannerListener,
                               GCKLoggerDelegate,
                               GCKDeviceManagerDelegate>

- (void) initialize:(CDVInvokedUrlCommand*)command;
- (void) startScan:(CDVInvokedUrlCommand*)command;
- (void) stopScan:(CDVInvokedUrlCommand*)command; 
- (void) setConnectionListener:(CDVInvokedUrlCommand*)command;
- (void) connect:(CDVInvokedUrlCommand*)command;
- (void) disconnect:(CDVInvokedUrlCommand*)command;
- (void) receiveTextMessage:(CDVInvokedUrlCommand*)command;
- (void) sendTextMessage:(CDVInvokedUrlCommand*)command;
- (void) launchApplication:(CDVInvokedUrlCommand*)command;
- (void) joinApplication:(CDVInvokedUrlCommand*)command;
- (void) leaveApplication:(CDVInvokedUrlCommand*)command;
- (void) stopApplication:(CDVInvokedUrlCommand*)command;
- (void) stopApplicationWithSessionId:(CDVInvokedUrlCommand*)command;
- (void) setVolume:(CDVInvokedUrlCommand*)command;
- (void) setMuted:(CDVInvokedUrlCommand*)command;
- (void) requestDeviceStatus:(CDVInvokedUrlCommand*)command;
- (void) isConnected:(CDVInvokedUrlCommand*)command;
- (void) isConnectedToApp:(CDVInvokedUrlCommand*)command;
- (void) isReconnecting:(CDVInvokedUrlCommand*)command;
- (void) getReconnectTimeout:(CDVInvokedUrlCommand*)command;
- (void) setReconnectTimeout:(CDVInvokedUrlCommand*)command;
- (void) didReceiveTextMessage:(NSString*)message;

@end
