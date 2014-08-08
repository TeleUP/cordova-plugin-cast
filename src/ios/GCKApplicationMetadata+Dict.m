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

#import "GCKApplicationMetadata+Dict.h"
#import "GCKSenderApplicationInfo+Dict.h"
#import "GCKImage+Dict.h"

static id nullable(id arg) {
  return arg ? arg : [NSNull null];
}

@implementation GCKApplicationMetadata (dict)

- (NSDictionary *) dictValue {
  NSMutableArray *images = [[NSMutableArray alloc] init];
  for (id image in self.images) {
    [images addObject:[image dictValue]];
  }

  NSDictionary *result = @{
    @"senderAppIdentifier"   : nullable([self senderAppIdentifier]),
    @"senderAppLaunchUrl"    : nullable([[self senderAppLaunchURL] absoluteString]),
    @"senderApplicationInfo" : nullable([[self senderApplicationInfo] dictValue]),
    @"applicationId"         : nullable(self.applicationID),
    @"applicationName"       : nullable(self.applicationName),
    @"images"                : images,
    @"namespaces"            : self.namespaces
  };
  return result;
}

@end
