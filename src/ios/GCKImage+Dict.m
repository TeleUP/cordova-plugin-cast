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

#import "GCKImage+Dict.h"

@implementation GCKImage (dict)

- (NSDictionary *) dictValue {
  NSDictionary *result =  @{
    @"url"    : [self.URL absoluteString],
    @"width"  : [NSNumber numberWithInteger:self.width],
    @"height" : [NSNumber numberWithInteger:self.height]
  };
  return result;
}

@end
