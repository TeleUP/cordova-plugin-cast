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
	if (LOG_LEVEL >= DEBUG)
	    console.log("cast: " + msg);
    }

    function logt(msg) {
	if (LOG_LEVEL >= TRACE)
	    console.log("cast: " + msg);
    }

    function throwe(msg) {
	throw new Error(msg);
    }

    /**
     * Creates a new Cast instance for interacting with the native
     * Cast APIs.
     * 
     * @constructor
     * @this {Cast}
     * @param {number} logLevel The level (0 for debug, 1 for trace) at which to log.
     */
    var Cast = function (logLevel) {
	if (logLevel == undefined)
	    logLevel = 0;

	LOG_LEVEL = logLevel;

	var self = this;

	var _onDeviceOnline;
	var _onDeviceOffline;
	var _connectionListener;

	/**
	 * Initializes the Cast library.
	 *
	 * @param {Function} onSuccess callback for successful initialization
	 * @param {Function} onError   callback for a failed initialization
	 */
	this.initialize = function (onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "initialize",
		 [LOG_LEVEL]);
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

	var dispatchConnectionCallback = function (msg) {
	    var type = msg.type;
	    var args = msg.args;
	    
	    // deserialize application metadata
	    if (type == 'connectedToApplication')
		args[0] = new CastApplicationMetadata(args[0]);
	    if (type == 'applicationStatusReceived')
		args[0] = new CastApplicationMetadata(args[0]);

	    var cb = _connectionListener[type];
	    if (cb) {
		cb.apply(_connectionListener, args);
	    } else {
		logd("Missing connection callback for " + type + ".");
	    }
	}

	/**
	 * Sets the listener to be notified of connection 
	 */
	this.setConnectionListener = function(connectionListener) {
	    _connectionListener = connectionListener;
	    exec(dispatchConnectionCallback,
		 throwe,
		 "Cast",
		 "setConnectionListener",
		 []);
	}

	/**
	 * Enables scanning for available cast devices.
	 */
	this.startScan = function (appId) {
	    exec(function (msg) 
		 {
		     var device = new CastDevice(msg.device);
		     msg.type == "online" ?  _onDeviceOnline(device) :  _onDeviceOffline(device);
		 },
		 throwe,
		 "Cast",
		 "startScan",
		 [appId]);
	};

	/**
	 * Disables scanning for available cast devices.
	 */
	this.stopScan = function () {
	    exec(null,
		 throwe,
		 "Cast",
		 "stopScan",
		 []);
	};

	/**
	 * Connects to the specified device.
	 *
	 * @param {CastDevice} device the device to which to connect.
	 * @param {onSuccess} callback if the connection attempt starts successfully. The
	 *                             success or failure of the actual connection is indicated
	 *                             by the connectionListener callbacks.
	 * @param {onError} callback if the connection attempt cannot be started.
	 */
	this.connect = function (device, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "connect",
		 [device.deviceId()]);
	};

	/**
	 * Disconnects from the current device, if any.
	 */
	this.disconnect = function () {
	    exec(null,
		 throwe,
		 "Cast",
		 "disconnect",
		 []);
	};

	/**
	 *
	 */
	this.setReceivedMessageListener = function (namespace, onMessageReceived) {
	    exec(onMessageReceived,
		 throwe,
		 "Cast",
		 "receiveTextMessage",
		 [namespace]);
	};

	/**
	 *
	 */
	this.sendMessage = function (msg) {
	    exec(null,
		 throwe,
		 "Cast",
		 "sendTextMessage",
		 [msg]);
	};

	/**
	 *
	 */
	this.launchApplication = function (appId, relaunchIfRunning, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "launchApplication",
		 [appId, relaunchIfRunning]); 
	};

	/**
	 *
	 */
	this.joinApplication = function (appId, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "joinApplication",
		 [appId]);
	};

	/**
	 *
	 */
	this.joinApplicationWithSessionId = function (appId, sessionId, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "joinApplication",
		 [appId, sessionId]);
	};

	/**
	 *
	 */
	this.leaveApplication = function (onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "leaveApplication",
		 []);
	};

	/**
	 *
	 */
	this.stopApplication = function (onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "stopApplication",
		 []);
	};

	/**
	 *
	 */
	this.stopApplicationWithSessionId = function (sessionId, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "stopApplicationWithSessionId",
		 [sessionId]);
	};

	/**
	 *
	 */
	this.setVolume = function (volume, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "setVolume",
		 [volume]);
	};

	/**
	 *
	 */
	this.setMuted = function (muted, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "setMuted",
		 [muted]);
	};

	/**
	 *
	 */
	this.requestDeviceStatus = function (onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "requestDeviceStatus",
		 []);
	};

	/**
	 *
	 */
	this.isConnected = function (onResult, onError) {
	    exec(onResult,
		 onError,
		 "Cast",
		 "isConnected",
		[]);
	};

	/**
	 *
	 */
	this.isConnectedToApp = function (onResult, onError) {
	    exec(onResult,
		 onError,
		 "Cast",
		 "isConnectedToApp",
		 []);
	};

	/**
	 *
	 */
	this.isReconnecting = function (onResult, onError) {
	    exec(onResult,
		 onError,
		 "Cast",
		 "isReconnecting",
		 []);
	};

	/**
	 *
	 */
	this.reconnectTimeout = function (onResult, onError) {
	    exec(onResult,
		 onError,
		 "Cast",
		 "getReconnectTimeout",
		 []);
	};

	/**
	 *
	 */
	this.setReconnectTimeout = function (timeout, onSuccess, onError) {
	    exec(onSuccess,
		 onError,
		 "Cast",
		 "setReconnectTimeout",
		 []);
	};
    };

    /*
     * Export the public API
     */
    module.exports = Cast;

})();
