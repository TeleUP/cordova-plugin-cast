/**
 * Exposes the Chromecast Cordova plugin as an Angular service with a
 * simplified promise-based API.  Configure the logging verbosity
 * using the provider method 'logLevel(level)'. Use the 'scan' and
 * 'connect' service methods to scan for and connect to a cast device.
 */
angular.module('cast', [])
    .provider('$cast', function CastProvider() {

	var LOG_LEVEL = 0;

	/**
	 * Sets the logging level for the cast service.  0 (default)
	 * logs nothing. 1 enables logging in Cordova plugin. 2 also
	 * enables logging within the (Google-provided) Cast library.
	 */
	this.logLevel = function (logLevel) {
	    LOG_LEVEL = parseInt(logLevel, 10);
	};

	this.$get = ['$q', function castFactory($q) {

	    var cast = null;
	    var session = null;

	    // initialize the plugin, if loaded
	    if (window.Cast) {
		cast = new Cast(LOG_LEVEL);
		cast.initialize(null, null);
	    } else {
		console.log("ngCast: Cast cordova plugin was not loaded.");
	    }

	    /**
	     * Represents a connection to an instance of the receiver application running on
	     * a Cast device.
	     *
	     * @constructor
	     *
	     * @param {Promise} q the promise to resolve with the
	     *                    session once first connected.
	     * @param {string} appId the id of the receiver
	     *                       application to join.
	     * @param {string} namespace the namespace for the cast
	     *                           channel to create.
	     */
	    var CastSession = function (q, appId, namespace) {
	    
		var self = this;

		var _q = q;
		var _appId = appId;
		var _namespace = namespace;

		var _sessionId = sessionId;

		var _onReceivedMessage;
		var _onDisconnected;

		/**
		 * Gets the id of the receiver application for this session.
		 * 
		 * @return {string} the id of the connected receiver application
		 */
		this.appId = function () {
		    return _appId;
		};

		/**
		 * Gets the channel namespace for this session.
		 * 
		 * @return {string} the channel namespace for this session
		 */
		this.namespace = function () {
		    return _namespace;
		};

		/**
		 * Gets the id of this session.
		 *
		 * @return {string} the id of this session
		 */
		this.sessionId = function () {
		    return _sessionId;
		};

		/**
		 * Sets the callbacks for received messages and disconnected events.
		 *
		 * @param {Function} onReceivedMessage callback for a
		 *                                     received
		 *                                     message. Passed
		 *                                     as a string.
		 * @param {Function} onDisconnected callback when the
		 *                                  session has ended
		 *                                  due to an
		 *                                  error. Pass as a
		 *                                  string.
		 */
		this.setListeners = function (onReceivedMessage, onDisconnected) {
		    _onReceivedMessage = onReceivedMessage;
		    _onDisconnected = onDisconnected;
		    cast.setReceivedMessageListener(_onReceivedMessage);
		};

		/**
		 * Sends a message to the receiver application.
		 *
		 * @param {string} message the message to send to the
		 *                         receiver.
		 */
		this.sendMessage = function (message) {
		    cast.sendMessage(message);
		};

		var _connectionListener = {
		    connected: function () {
			cast.launchApplication(_appId, false, null, null);
		    },

		    connectedToApplication: function (metadata, sessionId) {
			_sessionId = sessionId;
			_q.resolve(self);
		    },

		    failedToConnect: function (error) {
			_q.reject(error);
		    },

		    failedToConnectToApplication: function (error) {
			cast.disconnect();
			_q.reject(error);
		    },

		    disconnected : function (error) {
			cast.disconnect();
			_onDisconnected(error);
		    },

		    disconnectedFromApplication : function (error) {
			cast.disconnect();
			_onDisconnected(error);
		    },

		    failedToStopApplication : function (error) {
			// ignore, because never stop the application
		    },

		    volumeChanged : function (volumeLevel, isMuted) {
			// ignore
		    },

		    activeInputStatusReceived : function (activeInputStatus) {
			// ignore
		    }
		};
	    };

	    return {
		/**
		 * Starts scanning for available cast devices that
		 * support the specified receiver application.  The
		 * scanning process is effectively a singleton;
		 * starting a new scan will implicitly stop a prior
		 * scan.
		 * 
		 * @param {string} appId the id of the receiver application
		 * @param {Function} onDeviceOnline a callback taking a CastDevice param that is
                 *                                  invoked when the device becomes available.
		 * @param {Function} onDeviceOffline a callback taking a CastDevice param that is
		 *                                   invoked when the device becomes unavailable.
		 * @return {Function} a function that when invoked will stop the scan
		 */
		scan: function (appId, onDeviceOnline, onDeviceOffline) {
		    cast.setScanListener(onDeviceOnline, onDeviceOffline);
		    cast.startScan(appId);
		    return cast.stopScan;
		},

		/**
		 * Connects to the specified device and joins,
		 * launching if needed, the specified receiver
		 * application.
		 *
		 * @param {CastDevice} device the cast device,
		 *                            obtained from the scan
		 *                            callback, to which to
		 *                            connect.
		 * @param {string} appId the id of the receiver
		 *                       application to join.
		 * @param {string} namespace the namespace for the cast channel
		 *                           to create.
		 *
		 * @return {Promise} a promise that resolves with a
		 *                   CastSession object if the
		 *                   application is successfully
		 *                   launched.  On an error, a string
		 *                   message is returned.
		 */
		connect: function (device, appId, namespace) {
		    var q = $q.defer();
		    session = new CastSession(q, appId, namespace);
		    return q.promise;
		}
	    };

	}];
    });
