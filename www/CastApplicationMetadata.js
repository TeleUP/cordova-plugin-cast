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

var CastIcon = require('./CastIcon');
var CastSenderApplicationInfo = require('./CastSenderApplicationInfo');

/**
 * Metadata about the first-screen application.
 */
var CastApplicationMetadata = function (spec) {
    "use strict";

    spec = spec || null;
    spec.icons = spec.icons || [];
    var self = this;
    
    var _senderAppIdentifier = spec.senderAppIdentifier || null,
    _senderAppLaunchUrl = spec.senderAppLaunchUrl || null,
    _senderApplicationInfo = new CastSenderApplicationInfo(spec.senderApplicationInfo),
    _applicationId = spec.applicationId || null,
    _applicationName = spec.applicationName || null,
    _images = spec.icons.map(function(spec)
			     {
				 return new CastIcon(spec);			     
			     }),
    _namespaces = spec.namespaces || null;
    
    this.senderAppIdentifier = function () {
	return _senderAppIdentifier;
    };
    
    this.senderAppLaunchUrl = function () {
	return _senderAppLaunchUrl;
    };
    
    this.senderApplicationInfo = function () {
	return _senderApplicationInfo;
    };
    
    this.applicationId = function () {
	return _applicationId;
    };
    
    this.applicationName = function () {
	return _applicationName;
    };
    
    this.images = function () {
	return _images;
    };
    
    this.namespaces = function () {
	return _namespaces;
    };
};

module.exports = CastApplicationMetadata;
