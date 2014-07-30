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

/**
 * The url, width, and height of an icon representing a particular
 * cast device.
 */
var CastIcon = function (spec) {
    "use strict";
    var self = this;
	
    var _url    = spec.url,
    _width  = spec.width,
    _height = spec.height;

    this.url = function() {
	return _url;
    };
	
    this.width = function() {
	return _width;
    };
	
    this.height = function() {
	return _height;
    };
};

module.exports = CastIcon;
