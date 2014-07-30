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

/**
 * Metadata about a particular cast device.
 */
var CastDevice = function (spec) {
    "use strict";
    
    var STATUS = { "-1" : "unknown",
		   "0" : "idle",
		   "1" : "busy"
		 };
    
    var self = this;
    var _ipAddress    = spec.ipAddress,
    _servicePort  = spec.servicePort,
    _deviceId     = spec.deviceId,
    _friendlyName = spec.friendlyName,
    _manufacturer = spec.manufacturer,
    _modelName    = spec.modelName,
    _icons        = spec.icons.map(function(spec)
				   {
				       return new CastIcon(spec);
				   }),
    _status       = STATUS[spec.status.toString()];
    
    this.ipAddress = function () {
	return _ipAddress;
    };
    
    this.servicePort = function () {
	return _servicePort;
    };
    
    this.deviceId = function () {
	return _deviceId;
    };
    
    this.friendlyName = function () {
	return _friendlyName;
    };
    
    this.manufacturer = function () {
	return _manufacturer;
    };
    
    this.modelName = function () {
	    return _modelName;
    };
    
    this.icons = function () {
	return _icons;
    };

    this.status = function () {
	return _status;
    };
};

module.exports = CastDevice;
