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

#import "GCKDevice+Dict.h"
#import "GCKImage+Dict.h"

static id nullable(id arg) {
  return arg ? arg : [NSNull null];
}

@implementation GCKDevice (dict)

- (NSDictionary *) dictValue {
  NSMutableArray *icons = [[NSMutableArray alloc] init];
  for (id icon in self.icons) {
    [icons addObject:[icon dictValue]];
  }

  NSDictionary *result = @{
      @"ipAddress"    : self.ipAddress,
      @"servicePort"  : [@(self.servicePort) stringValue],
      @"deviceId"     : self.deviceID,
      @"friendlyName" : nullable(self.friendlyName),
      @"manufacturer" : nullable(self.manufacturer),
      @"modelName"    : nullable(self.modelName),
      @"icons"        : icons,
      @"status"       : [NSNumber numberWithInteger:self.status]
    };
    return result;
}

@end
