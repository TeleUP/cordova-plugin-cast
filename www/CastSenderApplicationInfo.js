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
 * Info about the sender application.
 */
var CastSenderApplicationInfo = function (spec) {
    "use strict";

    spec = spec || {};
    var self = this;
    
    var _platform = spec.platform || null;
    var _appIdentifier = spec.appIdentifier || null;
    var _launchUrl = spec.launchUrl || null;

    this.platform = function () {
	return _platform;
    };
    
    this.appIdentifier = function () {
	return _appIdentifier;
    };
    
    this.launchUrl = function() {
	return _launchUrl;
    };
};

module.exports = CastSenderApplicationInfo;
