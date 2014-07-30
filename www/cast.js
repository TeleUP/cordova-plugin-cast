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
 * Provides access to the Google Chomecast Cast SDK.
 */
(function () {
    "use strict";

    var exec = require('cordova/exec'),
    CastDevice = require('./CastDevice');

    var DEBUG = 1;
    var TRACE = 2;
    var LOG_LEVEL = 0;

    function logd(msg) {
	if (LOG_LEVEL > DEBUG)
	    console.log("cast: " + msg);
    }

    function logd(msg) {
	if (LOG_LEVEL > TRACE)
	    console.log("cast: " + msg);
    }

    /**
     * Creates a new Cast instance for interacting with the native
     * Cast APIs.
     * 
     * @constructor
     * @this {Cast}
     * @param {string} appId The id of the Chromecast receiver app.
     * @param {number} logLevel The level (0 for debug, 1 for trace) at which to log.
     */
    var Cast = function (appId, logLevel) {
	if (logLevel == undefined)
	    logLevel = 0;

	LOG_LEVEL = logLevel;

	var self = this;

	var _appId = appId;
	var _onDeviceOnline;
	var _onDeviceOffline;

	/**
	 * Retreives the id of the Chromecast receiver app.
	 *
	 * @return {string} The id of the Chromecast receiver app.
	 */
	this.appId = function () {
	    return _appId;
	};

	this.initialize = function (onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "initialize",
		 [_appId,
		  LOG_LEVEL]);
	};

	/**
	 * Sets the listeners to be notified of changed scan results.
	 * 
	 * @param {Function} onDeviceOnline A function taking a CastDevice param
	 *                   that is called when the device becomes available.
	 * @param {Function} onDeviceOffline A function taking a CastDevice param
	 *                   that is called when the device becomes unavailable.
	 */
	this.setScanListener = function (onDeviceOnline, onDeviceOffline) {
	    _onDeviceOnline = onDeviceOnline;
	    _onDeviceOffline = onDeviceOffline;
	};

	/**
	 * Enables scanning for available cast devices.
	 */
	this.startScan = function () {
	    exec(function (msg) 
		 {
		     var device = new CastDevice(msg.device);
		     msg.type == "online" ?  _onDeviceOnline(device) :  _onDeviceOffline(device);
		 },
		 null,
		 "Cast",
		 "startScan",
		 []);
	};

	/**
	 * Disables scanning for available cast devices.
	 */
	this.stopScan = function () {
	    exec(null,
		 null,
		 "Cast",
		 "stopScan",
		 []);
	};
    }

    /*
     * Export the public API
     */
    module.exports = Cast;

})();
