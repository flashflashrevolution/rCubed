package it.gotoandplay.smartfoxserver
{
	import flash.net.Socket;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.events.IOErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.events.SecurityErrorEvent;
	import flash.utils.setTimeout;
	import flash.net.URLLoader;
	import flash.utils.getTimer;
	
	import it.gotoandplay.smartfoxserver.handlers.IMessageHandler;
	import it.gotoandplay.smartfoxserver.handlers.SysHandler;
	import it.gotoandplay.smartfoxserver.handlers.ExtHandler;
	import it.gotoandplay.smartfoxserver.data.Room;
	import it.gotoandplay.smartfoxserver.data.User;
	import it.gotoandplay.smartfoxserver.util.ObjectSerializer;
	import it.gotoandplay.smartfoxserver.util.Entities;
	import it.gotoandplay.smartfoxserver.http.HttpConnection;
	import it.gotoandplay.smartfoxserver.http.HttpEvent;

	
	
	/**
	 * SmartFoxClient is the main class in the SmartFoxServer API.
	 * This class is responsible for connecting to the server and handling all related events.
	 *
	 * <b>NOTE</b>: in the provided examples, {@code smartFox} always indicates a SmartFoxClient instance.
	 *
	 * @sends	SFSEvent#onAdminMessage
	 * @sends	SFSEvent#onDebugMessage
	 * @sends	SFSEvent#onExtensionResponse
	 * @sends	SFSEvent#onRoomDeleted
	 * @sends	SFSEvent#onUserEnterRoom
	 * @sends	SFSEvent#onUserLeaveRoom
	 * @sends	SFSEvent#onUserCountChange
	 *
	 * @version	1.5.8
	 *
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 */
	public class SmartFoxClient extends EventDispatcher
	{
		// -------------------------------------------------------
		// Constants
		// -------------------------------------------------------
		
		private static const EOM:int = 0x00
		private static const MSG_XML:String  = "<"
		private static const MSG_JSON:String = "{"
		private static var MSG_STR:String  = "%"
		
		private static var MIN_POLL_SPEED:Number = 0
		private static var DEFAULT_POLL_SPEED:Number = 750
		private static var MAX_POLL_SPEED:Number = 10000
		private static var HTTP_POLL_REQUEST:String = "poll"
		
		/**
		 * Moderator message type: "to user".
		 * The Moderator message is sent to a single user.
		 *
		 * @see	#sendModeratorMessage
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const MODMSG_TO_USER:String = "u"
		
		/**
		 * Moderator message type: "to room".
		 * The Moderator message is sent to all the users in a room.
		 *
		 * @see	#sendModeratorMessage
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const MODMSG_TO_ROOM:String = "r"
		
		/**
		 * Moderator message type: "to zone".
		 * The Moderator message is sent to all the users in a zone.
		 *
		 * @see	#sendModeratorMessage
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const MODMSG_TO_ZONE:String = "z"
		
		/**
		 * Server-side extension request/response protocol: XML.
		 *
		 * @see	#sendXtMessage
		 * @see SFSEvent#onExtensionResponse
		 *
		 * @version	SmartFoxServer Pro
		 */
		public static const XTMSG_TYPE_XML:String = "xml"
		
		/**
		 * Server-side extension request/response protocol: String (aka "raw protocol").
		 *
		 * @see	#sendXtMessage
		 * @see SFSEvent#onExtensionResponse
		 *
		 * @version	SmartFoxServer Pro
		 */
		public static const XTMSG_TYPE_STR:String = "str"
		
		/**
		 * Server-side extension request/response protocol: JSON.
		 *
		 * @see	#sendXtMessage
		 * @see SFSEvent#onExtensionResponse
		 *
		 * @version	SmartFoxServer Pro
		 */
		public static const XTMSG_TYPE_JSON:String = "json"
		
		/**
		 * Connection mode: "disconnected".
		 * The client is currently disconnected from SmartFoxServer.
		 *
		 * @see	#getConnectionMode
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public static const CONNECTION_MODE_DISCONNECTED:String = "disconnected"
		
		/**
		 * Connection mode: "socket".
		 * The client is currently connected to SmartFoxServer via socket.
		 *
		 * @see	#getConnectionMode
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public static const CONNECTION_MODE_SOCKET:String = "socket"
		
		/**
		 * Connection mode: "http".
		 * The client is currently connected to SmartFoxServer via http.
		 *
		 * @see	#getConnectionMode
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public static const CONNECTION_MODE_HTTP:String = "http"
		
		// -------------------------------------------------------
		// Properties
		// -------------------------------------------------------
		
		private var roomList:Array
		private var connected:Boolean
		private var benchStartTime:int
		
		private var sysHandler:SysHandler
		private	var extHandler:ExtHandler
		
		private var majVersion:Number
		private var minVersion:Number
		private var subVersion:Number
		
		private var messageHandlers:Array
		private var socketConnection:Socket
		private var byteBuffer:ByteArray
		
		private var autoConnectOnConfigSuccess:Boolean = false
		
		/**
		 * The SmartFoxServer IP address.
		 *
		 * @see	#connect
		 *
		 * @version	SmartFoxServer Pro
		 */
		public var ipAddress:String
		
		/**
		 * The SmartFoxServer connection port.
		 * The default port is <b>9339</b>.
		 *
		 * @see	#connect
		 *
		 * @version	SmartFoxServer Pro
		 */
		public var port:int = 9339
		
		/**
		 * The default login zone.
		 *
		 * @see	#loadConfig
		 *
		 * @version	SmartFoxServer Pro
		 */
		public var defaultZone:String
		
		//--- BlueBox settings (start) ---------------------------------------------------------------------
		
		private var isHttpMode:Boolean = false								// connection mode
		private var _httpPollSpeed:int = DEFAULT_POLL_SPEED					// bbox poll speed
		private var httpConnection:HttpConnection							// the http connection
		
		/**
		 * The BlueBox IP address.
		 *
		 * @see	#smartConnect
		 * @see	#loadConfig
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public var blueBoxIpAddress:String
		
		/**
		 * The BlueBox connection port.
		 *
		 * @see	#smartConnect
		 * @see	#loadConfig
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public var blueBoxPort:Number = 0
		
		/**
		 * A boolean flag indicating if the BlueBox http connection should be used in case a socket connection is not available.
		 * The default value is {@code true}.
		 *
		 * @see	#loadConfig
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public var smartConnect:Boolean = true
		
		//--- BlueBox settings (end) ---------------------------------------------------------------------
		
		/**
		 * An array containing the objects representing each buddy of the user's buddy list.
		 * The buddy list can be iterated with a <i>for-in</i> loop, or a specific object can be retrieved by means of the {@link #getBuddyById} and {@link #getBuddyByName} methods.
		 *
		 * <b>NOTE</b>: this property and all the buddy-related method are available only if the buddy list feature is enabled for the current zone. Check the SmartFoxServer server-side configuration.
		 *
		 * Each element in the buddy list is an object with the following properties:
		 * @param	id:			(<b>int</b>) the buddy id.
		 * @param	name:		(<b>String</b>) the buddy name.
		 * @param	isOnline:	(<b>Boolean</b>) the buddy online status: {@code true} if the buddy is online; {@code false} if the buddy is offline.
		 * @param	isBlocked:	(<b>Boolean</b>) the buddy block status: {@code true} if the buddy is blocked; {@code false} if the buddy is not blocked; when a buddy is blocked, SmartFoxServer does not deliver private messages from/to that user.
		 * @param	variables:	(<b>Object</b>) an object with extra properties of the buddy (Buddy Variables); see also {@link #setBuddyVariables}.
		 *
		 * @example	The following example shows how to retrieve the properties of each buddy in the buddy list.
		 * 			<code>
		 * 			for (var b:String in smartFox.buddyList)
		 * 			{
		 * 				var buddy:Object = smartFox.buddyList[b]
		 *
		 * 				// Trace buddy properties
		 * 				trace("Buddy id: " + buddy.id)
		 * 				trace("Buddy name: " + buddy.name)
		 * 				trace("Is buddy online? " + buddy.isOnline ? "Yes" : "No")
		 * 				trace("Is buddy blocked? " + buddy.isBlocked ? "Yes" : "No")
		 *
		 * 				// Trace all Buddy Variables
		 * 				for (var v:String in buddy.variables)
		 * 					trace("\t" + v + " --> " + buddy.variables[v])
		 * 			}
		 * 			</code>
		 *
		 * @see		#myBuddyVars
		 * @see		#loadBuddyList
		 * @see		#getBuddyById
		 * @see		#getBuddyByName
		 * @see		#removeBuddy
		 * @see		#setBuddyBlockStatus
		 * @see		#setBuddyVariables
		 * @see		SFSEvent#onBuddyList
		 * @see		SFSEvent#onBuddyListUpdate
		 *
		 * @history	SmartFoxServer Pro v1.6.0 - Buddy's <i>isBlocked</i> property added.
		 *
		 * @version	SmartFoxServer Basic (except block status) / Pro
		 */
		public var buddyList:Array
		
		/**
		 * The current user's Buddy Variables.
		 * This is an associative array containing the current user's properties when he/she is present in the buddy lists of other users.
		 * See the {@link #setBuddyVariables} method for more details.
		 *
		 * @example	The following example shows how to read the current user's own Buddy Variables.
		 * 			<code>
		 * 			for (var v:String in smartFox.myBuddyVars)
		 * 				trace("Variable " + v + " --> " + smartFox.myBuddyVars[v])
		 * 			</code>
		 *
		 * @see		#setBuddyVariables
		 * @see		#getBuddyById
		 * @see		#getBuddyByName
		 * @see		SFSEvent#onBuddyList
		 * @see		SFSEvent#onBuddyListUpdate
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public var myBuddyVars:Array
		
		/**
		 * Toggle the client-side debugging informations.
		 * When turned on, the developer is able to inspect all server messages that are sent and received by the client in the Flash authoring environment.
		 * This allows a better debugging of the interaction with the server during application developement.
		 *
		 * @example	The following example shows how to turn on SmartFoxServer API debugging.
		 * 			<code>
		 * 			var smartFox:SmartFoxClient = new SmartFoxClient()
		 * 			var runningLocally:Boolean = true
		 *
		 * 			var ip:String
		 * 			var port:int
		 *
		 * 			if (runningLocally)
		 * 			{
		 * 				smartFox.debug = true
		 * 				ip = "127.0.0.1"
		 * 				port = 9339
		 * 			}
		 * 			else
		 * 			{
		 * 				smartFox.debug = false
		 * 				ip = "100.101.102.103"
		 * 				port = 9333
		 * 			}
		 *
		 * 			smartFox.connect(ip, port)
		 * 			</code>
		 *
		 * @see		SFSEvent#onDebugMessage
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public var debug:Boolean
		
		/**
		 * The current user's SmartFoxServer id.
		 * The id is assigned to a user on the server-side as soon as the client connects to SmartFoxServer successfully.
		 *
		 * <b>NOTE:</b> client-side, the <b>myUserId</b> property is available only after a successful login is performed using the default login procedure.
		 * If a custom login process is implemented, this property must be manually set after the successful login! If not, various client-side modules (SmartFoxBits, RedBox, etc.) may not work properly.
		 *
		 * @example	The following example shows how to retrieve the user's own SmartFoxServer id.
		 * 			<code>
		 * 			trace("My user ID is: " + smartFox.myUserId)
		 * 			</code>
		 *
		 * @see		#myUserName
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public var myUserId:int
		
		/**
		 * The current user's SmartFoxServer username.
		 *
		 * <b>NOTE</b>: client-side, the <b>myUserName</b> property is available only after a successful login is performed using the default login procedure.
		 * If a custom login process is implemented, this property must be manually set after the successful login! If not, various client-side modules (SmartFoxBits, RedBox, etc.) may not work properly.
		 *
		 * @example	The following example shows how to retrieve the user's own SmartFoxServer username.
		 * 			<code>
		 * 			trace("I logged in as: " + smartFox.myUserName)
		 * 			</code>
		 *
		 * @see		#myUserId
		 * @see		#login
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public var myUserName:String
		
		/**
		 * The current user's id as a player in a game room.
		 * The <b>playerId</b> is available only after the user successfully joined a game room. This id is 1-based (player 1, player 2, etc.), but if the user is a spectator or the room is not a game room, its value is -1.
		 * When a user joins a game room, a player id (or "slot") is assigned to him/her, based on the slots available in the room at the moment in which the user entered it; for example:
		 * <ul>
		 * 	<li>in a game room for 2 players, the first user who joins it becomes player one (playerId = 1) and the second user becomes player two (player = 2);</li>
		 * 	<li>in a game room for 4 players where only player three is missing, the next user who will join the room will be player three (playerId = 3);</li>
		 * </ul>
		 *
		 * <b>NOTE</b>: if multi-room join is allowed, this property contains only the last player id assigned to the user, and so it's useless.
		 * In this case the {@link Room#getMyPlayerIndex} method should be used to retrieve the player id for each joined room.
		 *
		 * @example	The following example shows how to retrieve the user's own player id.
		 * 			<code>
		 * 			trace("I'm player " + smartFox.playerId)
		 * 			</code>
		 *
		 * @see		Room#getMyPlayerIndex
		 * @see		Room#isGame
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public var playerId:int
		
		/**
		 * A boolean flag indicating if the user is recognized as Moderator.
		 *
		 * @example	The following example shows how to check if the current user is a Moderator in the current SmartFoxServer zone.
		 * 			<code>
		 * 			if (smartfox.amIModerator)
		 * 				trace("I'm a Moderator in this zone")
		 * 			else
		 * 				trace("I'm a standard user")
		 * 			</code>
		 *
		 * @see		#sendModeratorMessage
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public var amIModerator:Boolean
		
		/**
		 * The property stores the id of the last room joined by the current user.
		 * In most multiuser applications users can join one room at a time: in this case this property represents the id of the current room.
		 * If multi-room join is allowed, the application should track the various id(s) in an array (for example) and this property should be ignored.
		 *
		 * @example	The following example shows how to retrieve the current room object (as an alternative to the {@link #getActiveRoom} method).
		 * 			<code>
		 * 			var room:Room = smartFox.getRoom(smartFox.activeRoomId)
		 * 			trace("Current room is: " + room.getName())
		 * 			</code>
		 *
		 * @see		#getActiveRoom
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public var activeRoomId:int
		
		/**
		 * A boolean flag indicating if the process of joining a new room is in progress.
		 *
		 * @exclude
		 */
		public var changingRoom:Boolean
		
		/**
		 * The TCP port used by the embedded webserver.
		 * The default port is <b>8080</b>; if the webserver is listening on a different port number, this property should be set to that value.
		 *
		 * @example	The following example shows how to retrieve the webserver's current http port.
		 * 			<code>
		 * 			trace("HTTP port is: " + smartfox.httpPort)
		 * 			</code>
		 *
		 * @see		#uploadFile
		 *
		 * @since	SmartFoxServer Pro v1.5.0
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public var httpPort:int = 8080
		
		/**
		 * Get/set the character used as separator for the String (raw) protocol.
		 * The default value is <b>%</b> (percentage character).
		 *
		 * <b>NOTE</b>: this separator must match the one set in the SmartFoxServer server-side configuration file through the {@code <RawProtocolSeparator>} parameter.
		 *
		 * @example	The following example shows how to set the raw protocol separator.
		 * 			<code>
		 * 			smartFox.rawProtocolSeparator = "|"
		 * 			</code>
		 *
		 * @see		#XTMSG_TYPE_STR
		 * @see		#sendXtMessage
		 *
		 * @since	SmartFoxServer Pro v1.5.5
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function get rawProtocolSeparator():String
		{
			return MSG_STR
		}
		
		public function set rawProtocolSeparator(value:String):void
		{
			if (value != "<" && value != "{")
				MSG_STR = value
		}
		
		/**
		 * A boolean flag indicating if the current user is connected to the server.
		 *
		 * @example	The following example shows how to check the connection status.
		 * 			<code>
		 * 			trace("My connection status: " + (smartFox.isConnected ? "connected" : "not connected"))
		 * 			</code>
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function get isConnected():Boolean
		{
			return this.connected
		}
		
		public function set isConnected(b:Boolean):void
		{
			this.connected = b
		}
		
		/**
		 * The minimum interval between two polling requests when connecting to SmartFoxServer via BlueBox module.
		 * The default value is 750 milliseconds. Accepted values are between 0 and 10000 milliseconds (10 seconds).
		 *
		 * @usageNote	<i>Which is the optimal value for polling speed?</i>
		 * 				A value between 750-1000 ms is very good for chats, turn-based games and similar kind of applications. It adds minimum lag to the client responsiveness and it keeps the server CPU usage low.
		 * 				Lower values (200-500 ms) can be used where a faster responsiveness is necessary. For super fast real-time games values between 50 ms and 100 ms can be tried.
		 * 				With settings < 200 ms the CPU usage will grow significantly as the http connection and packet wrapping/unwrapping is more expensive than using a persistent connection.
		 * 				Using values below 50 ms is not recommended.
		 *
		 * @example	The following example shows how to set the polling speed.
		 * 			<code>
		 * 			smartFox.httpPollSpeed = 200
		 * 			</code>
		 *
		 * @see		#smartConnect
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function get httpPollSpeed():int
		{
			return this._httpPollSpeed
		}
		
		public function set httpPollSpeed(sp:int):void
		{
			// Acceptable values: 0 <= sp <= 10sec
			if (sp >= 0 && sp <= 10000)
				this._httpPollSpeed = sp
		}
		
		/*
		* New since 1.5.5
		*/
		public var properties:Object = null
		
		// -------------------------------------------------------
		// Constructor
		// -------------------------------------------------------
		
		/**
		 * The SmartFoxClient contructor.
		 *
		 * @param	debug:	turn on the debug messages (optional).
		 *
		 * @example	The following example shows how to instantiate the SmartFoxClient class enabling the debug messages.
		 * 			<code>
		 * 			var smartFox:SmartFoxServer = new SmartFoxServer(true)
		 * 			</code>
		 */
		public function SmartFoxClient(debug:Boolean = false)
		{
			// Initialize properties
			this.majVersion = 1
			this.minVersion = 5
			this.subVersion = 8

			
			this.activeRoomId = -1
			this.debug = debug
			
			//initialize()
			
			this.messageHandlers = []
			setupMessageHandlers()
			
			// Initialize socket object
			socketConnection = new Socket()
			
			socketConnection.addEventListener(Event.CONNECT, handleSocketConnection)
			socketConnection.addEventListener(Event.CLOSE, handleSocketDisconnection)
			socketConnection.addEventListener(ProgressEvent.SOCKET_DATA, handleSocketData)
			socketConnection.addEventListener(IOErrorEvent.IO_ERROR, handleIOError)
			socketConnection.addEventListener(IOErrorEvent.NETWORK_ERROR, handleIOError)
			socketConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleSecurityError)
			
			// Initialize HttpConnection
			httpConnection = new HttpConnection()
			httpConnection.addEventListener(HttpEvent.onHttpConnect, handleHttpConnect)
			httpConnection.addEventListener(HttpEvent.onHttpClose, handleHttpClose)
			httpConnection.addEventListener(HttpEvent.onHttpData, handleHttpData)
			httpConnection.addEventListener(HttpEvent.onHttpError, handleHttpError)
			
			// Main write buffer
			byteBuffer = new ByteArray()
		}
		
		// -------------------------------------------------------
		// Public methods
		// -------------------------------------------------------
		
		/**
		 * Load a client configuration file.
		 * The SmartFoxClient instance can be configured through an external xml configuration file loaded at run-time.
		 * By default, the <b>loadConfig</b> method loads a file named "config.xml", placed in the same folder of the application swf file.
		 * If the <i>autoConnect</i> parameter is set to {@code true}, on loading completion the {@link #connect} method is automatically called by the API, otherwise the {@link SFSEvent#onConfigLoadSuccess} event is dispatched.
		 * In case of loading error, the {@link SFSEvent#onConfigLoadFailure} event id fired.
		 *
		 * <b>NOTE</b>: the SmartFoxClient configuration file (client-side) should not be confused with the SmartFoxServer configuration file (server-side).
		 *
		 * @usageNote	The external xml configuration file has the following structure; ip, port and zone parameters are mandatory, all other parameters are optional.
		 * 				<code>
		 * 				<SmartFoxClient>
		 * 					<ip>127.0.0.1</ip>
		 * 					<port>9339</port>
		 * 					<zone>simpleChat</zone>
		 * 					<debug>true</debug>
		 * 					<blueBoxIpAddress>127.0.0.1</blueBoxIpAddress>
		 * 					<blueBoxPort>9339</blueBoxPort>
		 * 					<smartConnect>true</smartConnect>
		 * 					<httpPort>8080</httpPort>
		 * 					<httpPollSpeed>750</httpPollSpeed>
		 * 					<rawProtocolSeparator>%</rawProtocolSeparator>
		 * 				</SmartFoxClient>
		 * 				</code>
		 *
		 * @param	configFile:		external xml configuration file name (optional).
		 * @param	autoConnect:	a boolean flag indicating if the connection to SmartFoxServer must be attempted upon configuration loading completion (optional).
		 *
		 * @sends	SFSEvent#onConfigLoadSuccess
		 * @sends	SFSEvent#onConfigLoadFailure
		 *
		 * @example	The following example shows how to load an external configuration file.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onConfigLoadSuccess, onConfigLoadSuccessHandler)
		 * 			smartFox.addEventListener(SFSEvent.onConfigLoadFailure, onConfigLoadFailureHandler)
		 *
		 * 			smartFox.loadConfig("testEnvironmentConfig.xml", false)
		 *
		 * 			function onConfigLoadSuccessHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Config file loaded, now connecting...")
		 * 				smartFox.connect(smartFox.ipAddress, smartFox.port)
		 * 			}
		 *
		 * 			function onConfigLoadFailureHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Failed loading config file: " + evt.params.message)
		 * 			}
		 * 			</code>
		 *
		 * @see		#ipAddress
		 * @see		#port
		 * @see		#defaultZone
		 * @see		#debug
		 * @see		#blueBoxIpAddress
		 * @see		#blueBoxPort
		 * @see		#smartConnect
		 * @see		#httpPort
		 * @see		#httpPollSpeed
		 * @see		#rawProtocolSeparator
		 * @see		SFSEvent#onConfigLoadSuccess
		 * @see		SFSEvent#onConfigLoadFailure
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function loadConfig(configFile:String = "config.xml", autoConnect:Boolean = true):void
		{
			this.autoConnectOnConfigSuccess = autoConnect
			
			var loader:URLLoader = new URLLoader()
			loader.addEventListener(Event.COMPLETE, onConfigLoadSuccess)
			loader.addEventListener(IOErrorEvent.IO_ERROR, onConfigLoadFailure)
			
			loader.load(new URLRequest(configFile))
		}
		
		/**
		 * Get the current connection mode.
		 *
		 * @return	The current connection mode, expressed by one of the following constants: {@link #CONNECTION_MODE_DISCONNECTED} (disconnected), {@link #CONNECTION_MODE_SOCKET} (socket mode), {@link #CONNECTION_MODE_HTTP} (http mode).
		 *
		 * @example	The following example shows how to check the current connection mode.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onConnection, onConnectionHandler)
		 *
		 *			smartFox.connect("127.0.0.1", 9339)
		 *
		 *			function onConnectionHandler(evt:SFSEvent):void
		 *			{
		 *				trace("Connection mode: " + smartFox.getConnectionMode())
		 *			}
		 * 			</code>
		 *
		 * @see		#CONNECTION_MODE_DISCONNECTED
		 * @see		#CONNECTION_MODE_SOCKET
		 * @see		#CONNECTION_MODE_HTTP
		 * @see		#connect
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function getConnectionMode():String
		{
			var mode:String = CONNECTION_MODE_DISCONNECTED
			
			if ( this.isConnected )
			{
				if ( this.isHttpMode )
					mode = CONNECTION_MODE_HTTP
				else
					mode = CONNECTION_MODE_SOCKET
			}
	
			return mode
		}
		
		/**
		 * Establish a connection to SmartFoxServer.
		 * The client usually gets connected to SmartFoxServer through a socket connection. In SmartFoxServer Pro, if a socket connection is not available and the {@link #smartConnect} property is set to {@code true}, an http connection to the BlueBox module is attempted.
		 * When a successful connection is established, the {@link #getConnectionMode} can be used to check the current connection mode.
		 *
		 * @param	ipAdr:	the SmartFoxServer ip address.
		 * @param	port:	the SmartFoxServer TCP port (optional).
		 *
		 * @sends	SFSEvent#onConnection
		 *
		 * @example	The following example shows how to connect to SmartFoxServer.
		 * 			<code>
		 * 			smartFox.connect("127.0.0.1", 9339)
		 * 			</code>
		 *
		 * @see		#disconnect
		 * @see		#getConnectionMode
		 * @see		#smartConnect
		 * @see		SFSEvent#onConnection
		 *
		 * @history	SmartFoxServer Pro v1.6.0 - BlueBox connection attempt in case of socket connection not available.
		 *
		 * @version	SmartFoxServer Basic (except BlueBox connection) / Pro
		 */
		public function connect(ipAdr:String, port:int = 9339):void
		{
			if (!connected)
			{
				initialize()
				this.ipAddress = ipAdr
				this.port = port
				
				socketConnection.connect(ipAdr, port)
				
			}
			else
				debugMessage("*** ALREADY CONNECTED ***")
		}
		
		/**
		 * Close the current connection to SmartFoxServer.
		 *
		 * @sends	SFSEvent#onConnectionLost
		 *
		 * @example	The following example shows how to disconnect from SmartFoxServer.
		 * 			<code>
		 * 			smartFox.disconnect()
		 * 			</code>
		 *
		 * @see		#connect
		 * @see		SFSEvent#onConnectionLost
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function disconnect():void
		{
			connected = false
			
			if (!isHttpMode)
				socketConnection.close()
			else
				httpConnection.close()
			
			// dispatch event
			sysHandler.dispatchDisconnection()
		}
		
		/**
		 * Add a user to the buddy list.
		 * Since SmartFoxServer Pro 1.6.0, the buddy list feature can be configured to use a <i>basic</i> or <i>advanced</i> security mode (see the SmartFoxServer server-side configuration file).
		 * Check the following usage notes for details on the behavior of the <b>addBuddy</b> method in the two cases.
		 *
		 * @usageNote	Before you can add or remove any buddy from the list you must load the buddy-list from the server.
		 *				Always make sure to call {@see #loadBuddyList} before interacting with the buddy-list.
		 *
		 *				<i>Basic security mode</i>
		 * 				When a buddy is added, if the buddy list is already full, the {@link SFSEvent#onBuddyListError} event is fired; otherwise the buddy list is updated and the {@link SFSEvent#onBuddyList} event is fired.
		 * 				<hr />
		 * 				<i>Advanced security mode</i>
		 * 				If the {@code <addBuddyPermission>} parameter is set to {@code true} in the buddy list configuration section of a zone, before the user is actually added to the buddy list he/she must grant his/her permission.
		 * 				The permission request is sent if the user is online only; the user receives the {@link SFSEvent#onBuddyPermissionRequest} event. When the permission is granted, the buddy list is updated and the {@link SFSEvent#onBuddyList} event is fired.
		 * 				If the permission is not granted (or the buddy didn't receive the permission request), the <b>addBuddy</b> method can be called again after a certain amount of time only. This time is set in the server configuration {@code <permissionTimeOut>} parameter.
		 * 				Also, if the {@code <mutualAddBuddy>} parameter is set to {@code true}, when user A adds user B to the buddy list, he/she is automatically added to user B's buddy list.
		 * 				Lastly, if the buddy list is full, the {@link SFSEvent#onBuddyListError} event is fired.
		 *
		 * @param	buddyName:	the name of the user to be added to the buddy list.
		 *
		 * @sends	SFSEvent#onBuddyList
		 * @sends	SFSEvent#onBuddyListError
		 * @sends	SFSEvent#onBuddyPermissionRequest
		 *
		 * @example	The following example shows how to add a user to the buddy list.
		 * 			<code>
		 * 			smartFox.addBuddy("jack")
		 * 			</code>
		 *
		 * @see		#buddyList
		 * @see		#removeBuddy
		 * @see		#setBuddyBlockStatus
		 * @see		SFSEvent#onBuddyList
		 * @see		SFSEvent#onBuddyListError
		 * @see		SFSEvent#onBuddyPermissionRequest
		 *
		 * @history	SmartFoxServer Pro v1.6.0 - Buddy list's <i>advanced security mode</i> implemented.
		 *
		 * @version	SmartFoxServer Basic (except <i>advanced mode</i>) / Pro
		 */
		public function addBuddy(buddyName:String):void
		{
			if (buddyName != myUserName && !checkBuddyDuplicates(buddyName))
			{
				var xmlMsg:String = "<n>" + buddyName + "</n>"
				send({t:"sys"}, "addB", -1, xmlMsg)
			}
		}
		
		/**
		 * Automatically join the the default room (if existing) for the current zone.
		 * A default room can be specified in the SmartFoxServer server-side configuration by adding the {@code autoJoin = "true"} attribute to one of the {@code <Room>} tags in a zone.
		 * When a room is marked as <i>autoJoin</i> it becomes the default room where all clients are joined when this method is called.
		 *
		 * @sends	SFSEvent#onJoinRoom
		 * @sends	SFSEvent#onJoinRoomError
		 *
		 * @example	The following example shows how to join the default room in the current zone.
		 * 			<code>
		 * 			smartFox.autoJoin()
		 * 			</code>
		 *
		 * @see		#joinRoom
		 * @see		SFSEvent#onJoinRoom
		 * @see		SFSEvent#onJoinRoomError
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function autoJoin():void
		{
			if ( !checkRoomList() )
				return
				
			var header:Object 	= {t:"sys"}
			this.send(header, "autoJoin", (this.activeRoomId ? this.activeRoomId : -1) , "")
		}
		
		/**
		 * Remove all users from the buddy list.
		 *
		 * @deprecated	In order to avoid conflits with the buddy list <i>advanced security mode</i> implemented since SmartFoxServer Pro 1.6.0, buddies should be removed one by one, by iterating through the buddy list.
		 *
		 * @sends	SFSEvent#onBuddyList
		 *
		 * @example	The following example shows how to clear the buddy list.
		 * 			<code>
		 * 			smartFox.clearBuddyList()
		 * 			</code>
		 *
		 * @see		#buddyList
		 * @see		SFSEvent#onBuddyList
		 *
		 * @history	SmartFoxServer Pro v1.6.0 - Method deprecated.
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function clearBuddyList():void
		{
			buddyList = []
			send({t:"sys"}, "clearB", -1, "")
			
			// Fire event!
			var params:Object = {}
			params.list = buddyList
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onBuddyList, params)
			dispatchEvent(evt)
		}
		
		/**
		 * Dynamically create a new room in the current zone.
		 *
		 * <b>NOTE</b>: if the newly created room is a game room, the user is joined automatically upon successful room creation.
		 *
		 * @param	roomObj:	an object with the properties described farther on.
		 * @param	roomId:		the id of the room from where the request is originated, in case the application allows multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * <hr />
		 * The <i>roomObj</i> parameter is an object containing the following properties:
		 * @param	name:				(<b>String</b>) the room name.
		 * @param	password:			(<b>String</b>) a password to make the room private (optional, default: none).
		 * @param	maxUsers:			(<b>int</b>) the maximum number of users that can join the room.
		 * @param	maxSpectators:		(<b>int</b>) in game rooms only, the maximum number of spectators that can join the room (optional, default value: 0).
		 * @param	isGame:				(<b>Boolean</b>) if {@code true}, the room is a game room (optional, default value: {@code false}).
		 * @param	exitCurrentRoom:	(<b>Boolean</b>) if {@code true} and in case of game room, the new room is joined after creation (optional, default value: {@code true}).
		 * @param	joinAsSpectator		(<b>Boolean</b>) if {@code true} and in case of game room, allows to join the new room as spectator (optional, default value: {@code false}).
		 * @param	uCount:				(<b>Boolean</b>) if {@code true}, the new room will receive the {@link SFSEvent#onUserCountChange} notifications (optional, default <u>recommended</u> value: {@code false}).
		 * @param	vars:				(<b>Array</b>) an array of Room Variables, as described in the {@link #setRoomVariables} method documentation (optional, default: none).
		 * @param	extension:			(<b>Object</b>) which extension should be dynamically attached to the room, as described farther on (optional, default: none).
		 *
		 * <hr />
		 * A Room-level extension can be attached to any room during creation; the <i>extension</i> property in the <i>roomObj</i> parameter is an object with the following properties:
		 * @param	name:	(<b>String</b>) the name used to reference the extension (see the SmartFoxServer server-side configuration).
		 * @param	script:	(<b>String</b>) the file name of the extension script (for Actionscript and Python); if Java is used, the fully qualified name of the extension must be provided. The file name is relative to the root of the extension folder ("sfsExtensions/" for Actionscript and Python, "javaExtensions/" for Java).
		 *
		 * @sends	SFSEvent#onRoomAdded
		 * @sends	SFSEvent#onCreateRoomError
		 *
		 * @example	The following example shows how to create a new room.
		 * 			<code>
		 * 			var roomObj:Object = new Object()
		 * 			roomObj.name = "The Cave"
		 * 			roomObj.isGame = true
		 * 			roomObj.maxUsers = 15
		 *
		 * 			var variables:Array = new Array()
		 * 			variables.push({name:"ogres", val:5, priv:true})
		 * 			variables.push({name:"skeletons", val:4})
		 *
		 * 			roomObj.vars = variables
		 *
		 * 			smartFox.createRoom(roomObj)
		 * 			</code>
		 *
		 * @see		SFSEvent#onRoomAdded
		 * @see		SFSEvent#onCreateRoomError
		 * @see		SFSEvent#onUserCountChange
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function createRoom(roomObj:Object, roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
			
			if (roomId == -1)
				roomId = activeRoomId
				
			var header:Object = {t:"sys"}
			var isGame:String = (roomObj.isGame) ? "1" : "0"
			var exitCurrentRoom:String = "1"
			var maxUsers:String = roomObj.maxUsers == null ? "0" : String(roomObj.maxUsers)
			var maxSpectators:String = roomObj.maxSpectators == null ? "0" : String(roomObj.maxSpectators)
			var joinAsSpectator:String = roomObj.joinAsSpectator ? "1" : "0"
			
			if (roomObj.isGame && roomObj.exitCurrentRoom != null)
				exitCurrentRoom = roomObj.exitCurrentRoom ? "1" : "0"
				
			var xmlMsg:String  = "<room tmp='1' gam='" + isGame + "' spec='" + maxSpectators + "' exit='" + exitCurrentRoom + "' jas='" + joinAsSpectator + "'>"
		
			xmlMsg += "<name><![CDATA[" + (roomObj.name == null ? "" : roomObj.name) + "]]></name>"
			xmlMsg += "<pwd><![CDATA[" + (roomObj.password == null ? "" : roomObj.password) + "]]></pwd>"
			xmlMsg += "<max>" + maxUsers + "</max>"
			
			if (roomObj.uCount != null)
				xmlMsg += "<uCnt>" + (roomObj.uCount ? "1" : "0") + "</uCnt>"
			
			// Set extension for room
			if (roomObj.extension != null)
			{
				xmlMsg += "<xt n='" + roomObj.extension.name
				xmlMsg += "' s='" + roomObj.extension.script + "' />"
			}
			
			// Set Room Variables on creation
			if (roomObj.vars == null)
				xmlMsg += "<vars></vars>"
			else
			{
				xmlMsg += "<vars>"
				
				for (var i:String in roomObj.vars)
				{
					xmlMsg += getXmlRoomVariable(roomObj.vars[i])
				}
				
				xmlMsg += "</vars>"
			}
			
			xmlMsg += "</room>"
				
			send(header, "createRoom", roomId, xmlMsg)
		}
		
		/**
		 * Get the list of rooms in the current zone.
		 * Unlike the {@link #getRoomList} method, this method returns the list of {@link Room} objects already stored on the client, so no request is sent to the server.
		 *
		 * @return	The list of rooms available in the current zone.
		 *
		 * @example	The following example shows how to retrieve the room list.
		 * 			<code>
		 * 			var rooms:Array = smartFox.getAllRooms()
		 *
		 * 			for (var r:String in rooms)
		 * 			{
		 * 				var room:Room = rooms[r]
		 * 				trace("Room: " + room.getName())
		 * 			}
		 * 			</code>
		 *
		 * @see		#getRoomList
		 * @see		Room
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getAllRooms():Array
		{
			return roomList
		}
		
		/**
		 * Get a buddy from the buddy list, using the buddy's username as key.
		 * Refer to the {@link #buddyList} property for a description of the buddy object's properties.
		 *
		 * @param	buddyName:	the username of the buddy.
		 *
		 * @return	The buddy object.
		 *
		 * @example	The following example shows how to retrieve a buddy from the buddy list.
		 * 			<code>
		 * 			var buddy:Object = smartFox.getBuddyByName("jack")
		 *
		 * 			trace("Buddy id: " + buddy.id)
		 * 			trace("Buddy name: " + buddy.name)
		 * 			trace("Is buddy online? " + buddy.isOnline ? "Yes" : "No")
		 * 			trace("Is buddy blocked? " + buddy.isBlocked ? "Yes" : "No")
		 *
		 * 			trace("Buddy Variables:")
		 * 			for (var v:String in buddy.variables)
		 * 				trace("\t" + v + " --> " + buddy.variables[v])
		 * 			</code>
		 *
		 * @see 	#buddyList
		 * @see		#getBuddyById
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function getBuddyByName(buddyName:String):Object
		{
			for each (var buddy:Object in buddyList)
			{
				if (buddy.name == buddyName)
					return buddy
			}
			
			return null
		}
		
		/**
		 * Get a buddy from the buddy list, using the user id as key.
		 * Refer to the {@link #buddyList} property for a description of the buddy object's properties.
		 *
		 * @param	id:	the user id of the buddy.
		 *
		 * @return	The buddy object.
		 *
		 * @example	The following example shows how to retrieve a buddy from the buddy list.
		 * 			<code>
		 * 			var buddy:Object = smartFox.getBuddyById(25)
		 *
		 * 			trace("Buddy id: " + buddy.id)
		 * 			trace("Buddy name: " + buddy.name)
		 * 			trace("Is buddy online? " + buddy.isOnline ? "Yes" : "No")
		 * 			trace("Is buddy blocked? " + buddy.isBlocked ? "Yes" : "No")
		 *
		 * 			trace("Buddy Variables:")
		 * 			for (var v:String in buddy.variables)
		 * 				trace("\t" + v + " --> " + buddy.variables[v])
		 * 			</code>
		 *
		 * @see 	#buddyList
		 * @see		#getBuddyByName
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function getBuddyById(id:int):Object
		{
			for each (var buddy:Object in buddyList)
			{
				if (buddy.id == id)
					return buddy
			}
			
			return null
		}
		
		/**
		 * Request the room id(s) of the room(s) where a buddy is currently located into.
		 *
		 * @param	buddy:	a buddy object taken from the {@link #buddyList} array.
		 *
		 * @sends	SFSEvent#onBuddyRoom
		 *
		 * @example	The following example shows how to join the same room of a buddy.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onBuddyRoom, onBuddyRoomHandler)
		 *
		 * 			var buddy:Object = smartFox.getBuddyByName("jack")
		 * 			smartFox.getBuddyRoom(buddy)
		 *
		 * 			function onBuddyRoomHandler(evt:SFSEvent):void
		 * 			{
		 * 				// Reach the buddy in his room
		 * 				smartFox.join(evt.params.idList[0])
		 * 			}
		 * 			</code>
		 *
		 * @see 	#buddyList
		 * @see		SFSEvent#onBuddyRoom
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getBuddyRoom(buddy:Object):void
		{
			// If buddy is active...
			if (buddy.id != -1)
				send({t:"sys"}, "roomB", -1, "<b id='" + buddy.id + "' />")
		}
		
		/**
		 * Get a {@link Room} object, using its id as key.
		 *
		 * @param	roomId:	the id of the room.
		 *
		 * @return	The {@link Room} object.
		 *
		 * @example	The following example shows how to retrieve a room from its id.
		 * 			<code>
		 * 			var roomObj:Room = smartFox.getRoom(15)
		 * 			trace("Room name: " + roomObj.getName() + ", max users: " + roomObj.getMaxUsers())
		 * 			</code>
		 *
		 * @see 	#getRoomByName
		 * @see		#getAllRooms
		 * @see		#getRoomList
		 * @see		Room
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getRoom(roomId:int):Room
		{
			if ( !checkRoomList() )
				return null
				
			return roomList[roomId]
		}
		
		/**
		 * Get a {@link Room} object, using its name as key.
		 *
		 * @param	roomName:	the name of the room.
		 *
		 * @return	The {@link Room} object.
		 *
		 * @example	The following example shows how to retrieve a room from its id.
		 * 			<code>
		 * 			var roomObj:Room = smartFox.getRoomByName("The Entrance")
		 * 			trace("Room id: " + roomObj.getId() + ", max users: " + roomObj.getMaxUsers())
		 * 			</code>
		 *
		 * @see 	#getRoom
		 * @see		#getAllRooms
		 * @see		#getRoomList
		 * @see		Room
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getRoomByName(roomName:String):Room
		{
			if ( !checkRoomList() )
				return null
			
			var room:Room = null
			
			for each (var r:Room in roomList)
			{
				if (r.getName() == roomName)
				{
					room = r
					break
				}
			}
			
			return room
		}
		
		/**
		 * Retrieve the updated list of rooms in the current zone.
		 * Unlike the {@link #getAllRooms} method, this method sends a request to the server, which then sends back the complete list of rooms with all their properties and server-side variables (Room Variables).
		 *
		 * If the default login mechanism provided by SmartFoxServer is used, then the updated list of rooms is received right after a successful login, without the need to call this method.
		 * Instead, if a custom login handler is implemented, the room list must be manually requested to the server using this method.
		 *
		 * @sends	SFSEvent#onRoomListUpdate
		 *
		 * @example	The following example shows how to retrieve the room list from the server.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRoomListUpdate, onRoomListUpdateHandler)
		 *
		 * 			smartFox.getRoomList()
		 *
		 * 			function onRoomListUpdateHandler(evt:SFSEvent):void
		 * 			{
		 * 				// Dump the names of the available rooms in the current zone
		 * 				for (var r:String in evt.params.roomList)
		 * 					trace(evt.params.roomList[r].getName())
		 * 			}
		 * 			</code>
		 *
		 * @see		#getRoom
		 * @see		#getRoomByName
		 * @see		#getAllRooms
		 * @see		SFSEvent#onRoomListUpdate
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getRoomList():void
		{
			var header:Object 	= {t:"sys"}
			send(header, "getRmList", activeRoomId, "")
		}
		
		/**
		 * Get the currently active {@link Room} object.
		 * SmartFoxServer allows users to join two or more rooms at the same time (multi-room join). If this feature is used, then this method is useless and the application should track the various room id(s) manually, for example by keeping them in an array.
		 *
		 * @return	the {@link Room} object of the currently active room; if the user joined more than one room, the last joined room is returned.
		 *
		 * @example	The following example shows how to retrieve the current room object.
		 * 			<code>
		 * 			var room:Room = smartFox.getActiveRoom()
		 * 			trace("Current room is: " + room.getName())
		 * 			</code>
		 *
		 * @see		#activeRoomId
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getActiveRoom():Room
		{
			if ( !checkRoomList() || !checkJoin() )
				return null
				
			return roomList[activeRoomId]
		}
		
		/**
		 * Retrieve a random string key from the server.
		 * This key is also referred in the SmartFoxServer documentation as the "secret key".
		 * It's a unique key, valid for the current session only. It can be used to create a secure login system.
		 *
		 * @sends	SFSEvent#onRandomKey
		 *
		 * @example	The following example shows how to handle the request a random key to the server.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRandomKey, onRandomKeyHandler)
		 *
		 * 			smartFox.getRandomKey()
		 *
		 * 			function onRandomKeyHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Random key received from server: " + evt.params.key)
		 * 			}
		 * 			</code>
		 *
		 * @see		SFSEvent#onRandomKey
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function getRandomKey():void
		{
			send({t:"sys"}, "rndK", -1, "")
		}
		
		/**
		 * Get the default upload path of the embedded webserver.
		 *
		 * @return	The http address of the default folder in which files are uploaded.
		 *
		 * @example	The following example shows how to get the default upload path.
		 * 			<code>
		 * 			var path:String = smartFox.getUploadPath()
		 * 			</code>
		 *
		 * @see		#uploadFile
		 *
		 * @since	SmartFoxServer Pro v1.5.0
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getUploadPath():String
		{
			return "http://" + this.ipAddress + ":" + this.httpPort + "/default/uploads/"
		}
		
		/**
		 * Get the SmartFoxServer Flash API version.
		 *
		 * @return	The current version of the SmartFoxServer client API.
		 *
		 * @example	The following example shows how to trace the SmartFoxServer API version.
		 * 			<code>
		 * 			trace("Current API version: " + smartFox.getVersion())
		 * 			</code>
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getVersion():String
		{
			return this.majVersion + "." + this.minVersion + "." + this.subVersion
		}
		
		/**
		 * Join a room.
		 *
		 * @param	newRoom:		the name ({@code String}) or the id ({@code int}) of the room to join.
		 * @param	pword:			the room's password, if it's a private room (optional).
		 * @param	isSpectator:	a boolean flag indicating wheter you join as a spectator or not (optional).
		 * @param	dontLeave:		a boolean flag indicating if the current room must be left after successfully joining the new room (optional).
		 * @param	oldRoom:		the id of the room to leave (optional, default value: {@link #activeRoomId}).
		 * <hr />
		 * <b>NOTE</b>: the last two optional parameters enable the advanced multi-room join feature of SmartFoxServer, which allows a user to join two or more rooms at the same time. If this feature is not required, the parameters can be omitted.
		 *
		 * @sends	SFSEvent#onJoinRoom
		 * @sends	SFSEvent#onJoinRoomError
		 *
		 * @example	In the following example the user requests to join a room with id = 10; by default SmartFoxServer will disconnect him from the previous room.
		 * 			<code>
		 * 			smartFox.joinRoom(10)
		 * 			</code>
		 * 			<hr />
		 *
		 * 			In the following example the user requests to join a room with id = 12 and password = "mypassword"; by default SmartFoxServer will disconnect him from the previous room.
		 * 			<code>
		 * 			smartFox.joinRoom(12, "mypassword")
		 * 			</code>
		 * 			<hr />
		 *
		 * 			In the following example the user requests to join the room with id = 15 and passes {@code true} to the <i>dontLeave</i> flag; this will join the user in the new room while keeping him in the old room as well.
		 * 			<code>
		 * 			smartFox.joinRoom(15, "", false, true)
		 * 			</code>
		 *
		 * @see 	SFSEvent#onJoinRoom
		 * @see		SFSEvent#onJoinRoomError
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function joinRoom(newRoom:*, pword:String  = "", isSpectator:Boolean = false, dontLeave:Boolean = false, oldRoom:int = -1):void
		{
			if ( !checkRoomList() )
				return
				
			var newRoomId:int = -1
			var isSpec:int = isSpectator ? 1 : 0
			
			if (!this.changingRoom)
			{
				if (typeof newRoom == "number")
					newRoomId = int(newRoom)

				else if (typeof newRoom == "string")
				{
					// Search the room
					for each (var r:Room in roomList)
					{
						if (r.getName() == newRoom)
						{
							newRoomId = r.getId()
							break
						}
					}
				}
				
				if (newRoomId != -1)
				{
					var header:Object = {t:"sys"}
	
					var leaveCurrRoom:String = dontLeave ? "0": "1"
					
					// Set the room to leave
					var roomToLeave:int = oldRoom > -1 ? oldRoom : activeRoomId

					// CHECK: activeRoomId == -1 no room has already been entered
					if (activeRoomId == -1)
					{
						leaveCurrRoom = "0"
						roomToLeave = -1
					}
					
					var message:String = "<room id='" + newRoomId + "' pwd='" + pword + "' spec='" + isSpec + "' leave='" + leaveCurrRoom + "' old='" + roomToLeave + "' />"
					
					send(header, "joinRoom", activeRoomId, message)
					changingRoom = true
				}
				
				
				else
				{
					debugMessage("SmartFoxError: requested room to join does not exist!")
				}
			}
		}
		
		/**
		 * Disconnect the user from the given room.
		 * This method should be used only when users are allowed to be present in more than one room at the same time (multi-room join feature).
		 *
		 * @param	roomId:	the id of the room to leave.
		 *
		 * @sends	SFSEvent#onRoomLeft
		 *
		 * @example	The following example shows how to make a user leave a room.
		 * 			<code>
		 * 			smartFox.leaveRoom(15)
		 * 			</code>
		 *
		 * @see 	#joinRoom
		 * @see		SFSEvent#onRoomLeft
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function leaveRoom(roomId:int):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<rm id='" + roomId + "' />"
			
			send(header, "leaveRoom", roomId, xmlMsg)
		}
		
		/**
		 * Load the buddy list for the current user.
		 *
		 * @sends	SFSEvent#onBuddyList
		 * @sends	SFSEvent#onBuddyListError
		 *
		 * @example	The following example shows how to load the current user's buddy list.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onBuddyList, onBuddyListHandler)
		 *
		 * 			smartFox.loadBuddyList()
		 *
		 * 			function onBuddyListHandler(evt:SFSEvent):void
		 * 			{
		 * 				for (var b:String in smartFox.buddyList)
		 * 				{
		 * 					var buddy:Object = smartFox.buddyList[b]
		 *
		 * 					trace("Buddy id: " + buddy.id)
		 * 					trace("Buddy name: " + buddy.name)
		 * 					trace("Is buddy online? " + buddy.isOnline ? "Yes" : "No")
		 * 					trace("Is buddy blocked? " + buddy.isBlocked ? "Yes" : "No")
		 *
		 * 					trace("Buddy Variables:")
		 * 					for (var k:String in buddy.variables)
		 * 						trace("\t" + k + " --> " + buddy.variables[k])
		 * 				}
		 * 			}
		 * 			</code>
		 *
		 * @see		#buddyList
		 * @see		SFSEvent#onBuddyList
		 * @see		SFSEvent#onBuddyListError
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function loadBuddyList():void
		{
			send({t:"sys"}, "loadB", -1, "")
		}

		/**
		 * Perform the default login procedure.
		 * The standard SmartFoxServer login procedure accepts guest users. If a user logs in with an empty username, the server automatically creates a name for the client using the format <i>guest_n</i>, where <i>n</i> is a progressive number.
		 * Also, the provided username and password are checked against the moderators list (see the SmartFoxServer server-side configuration) and if a user matches it, he is set as a Moderator.
		 *
		 * <b>NOTE 1</b>: duplicate names in the same zone are not allowed.
		 *
		 * <b>NOTE 2</b>: for SmartFoxServer Basic, where a server-side custom login procedure can't be implemented due to the lack of <i>extensions</i> support, a custom client-side procedure can be used, for example to check usernames against a database using a php/asp page.
		 * In this case, this should be done BEFORE calling the <b>login</b> method. This way, once the client is validated, the stadard login procedure can be used.
		 *
		 * <b>NOTE 3</b>: for SmartFoxServer PRO. If the Zone you are accessing uses a custom login the login-response will be sent from server side and you will need to handle it using the <b>onExtensionResponse</b> handler.
		 * Additionally you will need to manually set the myUserId and myUserName properties if you need them. (This is automagically done by the API when using a <em>default login</em>)
		 *
		 * @param	zone:	the name of the zone to log into.
		 * @param	name:	the user name.
		 * @param	pass:	the user password.
		 *
		 * @sends	SFSEvent#onLogin
		 *
		 * @example	The following example shows how to login into a zone.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onLogin, onLoginHandler)
		 *
		 * 			smartFox.login("simpleChat", "jack")
		 *
		 * 			function onLoginHandler(evt:SFSEvent):void
		 * 			{
		 * 				if (evt.params.success)
		 * 					trace("Successfully logged in as " + evt.params.name)
		 * 				else
		 * 					trace("Zone login error; the following error occurred: " + evt.params.error)
		 * 			}
		 * 			</code>
		 *
		 * @see 	#logout
		 * @see		SFSEvent#onLogin
		 * @see		SFSEvent#onExtensionResponse
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function login(zone:String, name:String, pass:String):void
		{
			var header:Object = {t:"sys"}
			var message:String = "<login z='" + zone + "'><nick><![CDATA[" + name + "]]></nick><pword><![CDATA[" + pass + "]]></pword></login>"
	
			send(header, "login", 0, message)
		}
		
		/**
		 * Log the user out of the current zone.
		 * After a successful logout the user is still connected to the server, but he/she has to login again into a zone, in order to be able to interact with the server.
		 *
		 * @sends	SFSEvent#onLogout
		 *
		 * @example	The following example shows how to logout from a zone.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onLogout, onLogoutHandler)
		 *
		 * 			smartFox.logout()
		 *
		 * 			function onLogoutHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Logged out successfully")
		 * 			}
		 * 			</code>
		 *
		 * @see 	#login
		 * @see		SFSEvent#onLogout
		 *
		 * @since	SmartFoxServer Pro v1.5.5
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function logout():void
		{
			var header:Object = {t:"sys"}
			send(header, "logout", -1, "")
		}
		
		/**
		 * Remove a buddy from the buddy list.
		 * Since SmartFoxServer Pro 1.6.0, the buddy list feature can be configured to use a <i>basic</i> or <i>advanced</i> security mode (see the SmartFoxServer server-side configuration file).
		 * Check the following usage notes for details on the behavior of the <b>removeBuddy</b> method in the two cases.
		 *
		 * @usageNote	Before you can add or remove any buddy from the list you must load the buddy-list from the server.
		 *				Always make sure to call {@see #loadBuddyList} before interacting with the buddy-list.
		 *
	 	 *				<i>Basic security mode</i>
		 * 				When a buddy is removed, the buddy list is updated and the {@link SFSEvent#onBuddyList} event is fired.
		 * 				<hr />
		 * 				<i>Advanced security mode</i>
		 * 				In addition to the basic behavior, if the {@code <mutualRemoveBuddy>} server-side configuration parameter is set to {@code true}, when user A removes user B from the buddy list, he/she is automatically removed from user B's buddy list.
		 *
		 * @param	buddyName:	the name of the user to be removed from the buddy list.
		 *
		 * @sends	SFSEvent#onBuddyList
		 *
		 * @example	The following example shows how to remove a user from the buddy list.
		 * 			<code>
		 * 			var buddyName:String = "jack"
		 * 			smartFox.removeBuddy(buddyName)
		 * 			</code>
		 *
		 * @see		#buddyList
		 * @see		#addBuddy
		 * @see		SFSEvent#onBuddyList
		 *
		 * @history	SmartFoxServer Pro v1.6.0 - Buddy list's <i>advanced security mode</i> implemented.
		 *
		 * @version	SmartFoxServer Basic (except <i>advanced mode</i>) / Pro
		 */
		public function removeBuddy(buddyName:String):void
		{
			var found:Boolean = false
			var buddy:Object
			
			for (var it:String in buddyList)
			{
				buddy = buddyList[it]
				
				if (buddy.name == buddyName)
				{
					delete buddyList[it]
					found = true
					break
				}
			}
			
			if (found)
			{
				var header:Object = {t:"sys"}
				var xmlMsg:String = "<n>" + buddyName + "</n>"
					
				send(header, "remB", -1, xmlMsg)
					
				// Fire event!
				var params:Object = {}
				params.list = buddyList
				
				var evt:SFSEvent = new SFSEvent(SFSEvent.onBuddyList, params)
				dispatchEvent(evt)
			}
		}
		
		/**
		 * Send a roundtrip request to the server to test the connection' speed.
		 * The roundtrip request sends a small packet to the server which immediately responds with another small packet, and causing the {@link SFSEvent#onRoundTripResponse} event to be fired.
		 * The time taken by the packet to travel forth and back is called "roundtrip time" and can be used to calculate the average network lag of the client.
		 * A good way to measure the network lag is to send continuos requests (every 3 or 5 seconds) and then calculate the average roundtrip time on a fixed number of responses (i.e. the last 10 measurements).
		 *
		 * @sends	SFSEvent#onRoundTripResponse
		 *
		 * @example	The following example shows how to check the average network lag time.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRoundTripResponse, onRoundTripResponseHandler)
		 *
		 * 			var totalPingTime:Number = 0
		 * 			var pingCount:int = 0
		 *
		 * 			smartFox.roundTripBench() // TODO: this method must be called repeatedly every 3-5 seconds to have a significant average value
		 *
		 * 			function onRoundTripResponseHandler(evt:SFSEvent):void
		 * 			{
		 * 				var time:int = evt.params.elapsed
		 *
		 * 				// We assume that it takes the same time to the ping message to go from the client to the server
		 * 				// and from the server back to the client, so we divide the elapsed time by 2.
		 * 				totalPingTime += time / 2
		 * 				pingCount++
		 *
		 * 				var avg:int = Math.round(totalPingTime / pingCount)
		 *
		 * 				trace("Average lag: " + avg + " milliseconds")
		 * 			}
		 * 			</code>
		 *
		 * @see		SFSEvent#onRoundTripResponse
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function roundTripBench():void
		{
			this.benchStartTime = getTimer()
			send({t:"sys"}, "roundTrip", activeRoomId, "")
		}
		
		/**
		 * Grant current user permission to be added to a buddy list.
		 * If the SmartFoxServer Pro 1.6.0 <i>advanced</i> security mode is used (see the SmartFoxServer server-side configuration), when a user wants to add a buddy to his/her buddy list, a permission request is sent to the buddy.
		 * Once the {@link SFSEvent#onBuddyPermissionRequest} event is received, this method must be used by the buddy to grant or refuse permission. When the permission is granted, the requester's buddy list is updated.
		 *
		 * @param	allowBuddy:		{@code true} to grant permission, {@code false} to refuse to be added to the requester's buddy list.
		 * @param	targetBuddy:	the username of the requester.
		 *
		 * @example	The following example shows how to grant permission to be added to a buddy list once request is received.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onBuddyPermissionRequest, onBuddyPermissionRequestHandler)
		 *
		 * 			var autoGrantPermission:Boolean = true
		 *
		 * 			function onBuddyPermissionRequestHandler(evt:SFSEvent):void
		 * 			{
		 * 				if (autoGrantPermission)
		 * 				{
		 * 					// Automatically grant permission
		 *
		 * 					smartFox.sendBuddyPermissionResponse(true, evt.params.sender)
		 * 				}
		 * 				else
		 * 				{
		 * 					// Display a custom alert containing grant/refuse buttons
		 *
		 * 					var alert_mc:CustomAlertPanel = new CustomAlertPanel()
		 *
		 * 					alert_mc.name_lb.text = evt.params.sender
		 * 					alert_mc.message_lb.text = evt.params.message
		 *
		 * 					// Display alert
		 * 					addChild(alert_mc)
		 * 				}
		 * 			}
		 * 			</code>
		 *
		 * @see		#addBuddy
		 * @see		SFSEvent#onBuddyPermissionRequest
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function sendBuddyPermissionResponse(allowBuddy:Boolean, targetBuddy:String):void
		{
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<n res='" + (allowBuddy ? "g" : "r") + "'>" + targetBuddy + "</n>";
			
			send(header, "bPrm", -1, xmlMsg)
		}
		
		/**
		 * Send a public message.
		 * The message is broadcasted to all users in the current room, including the sender.
		 *
		 * @param	message:	the text of the public message.
		 * @param	roomId:		the id of the target room, in case of multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @sends	SFSEvent#onPublicMessage
		 *
		 * @example	The following example shows how to send and receive a public message.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onPublicMessage, onPublicMessageHandler)
		 *
		 * 			smartFox.sendPublicMessage("Hello world!")
		 *
		 * 			function onPublicMessageHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("User " + evt.params.sender.getName() + " said: " + evt.params.message)
		 * 			}
		 * 			</code>
		 *
		 * @see		#sendPrivateMessage
		 * @see		SFSEvent#onPublicMessage
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function sendPublicMessage(message:String, roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId
				
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<txt><![CDATA[" + Entities.encodeEntities(message) + "]]></txt>"
			
			send(header, "pubMsg", roomId, xmlMsg)
		}
		
		/**
		 * Send a private message to a user.
		 * The message is broadcasted to the recipient and the sender.
		 *
		 * @param	message:		the text of the private message.
		 * @param	recipientId:	the id of the recipient user.
		 * @param	roomId:			the id of the room from where the message is sent, in case of multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @sends	SFSEvent#onPrivateMessage
		 *
		 * @example	The following example shows how to send and receive a private message.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onPrivateMessage, onPrivateMessageHandler)
		 *
		 * 			smartFox.sendPrivateMessage("Hallo Jack!", 22)
		 *
		 * 			function onPrivateMessageHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("User " + evt.params.sender.getName() + " sent the following private message: " + evt.params.message)
		 * 			}
		 * 			</code>
		 *
		 * @see		#sendPublicMessage
		 * @see		SFSEvent#onPrivateMessage
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function sendPrivateMessage(message:String, recipientId:int, roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId
				
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<txt rcp='" + recipientId + "'><![CDATA[" + Entities.encodeEntities(message) + "]]></txt>"
			send(header, "prvMsg", roomId, xmlMsg)
		}
		
		/**
		 * Send a Moderator message to the current zone, the current room or a specific user in the current room.
		 * In order to send these kind of messages, the user must have Moderator's privileges, which are set by SmartFoxServer when the user logs in (see the {@link #login} method).
		 *
		 * @param	message:	the text of the message.
		 * @param	type:		the type of message. The following constants can be passed: {@link #MODMSG_TO_USER}, {@link #MODMSG_TO_ROOM} and {@link #MODMSG_TO_ZONE}, to send the message to a user, to the current room or to the entire current zone respectively.
		 * @param	id:			the id of the recipient room or user (ignored if the message is sent to the zone).
		 *
		 * @sends	SFSEvent#onModeratorMessage
		 *
		 * @example	The following example shows how to send a Moderator message.
		 * 			<code>
		 * 			smartFox.sendModeratorMessage("Greetings from the Moderator", SmartFoxClient.MODMSG_TO_ROOM, smartFox.getActiveRoom())
		 * 			</code>
		 *
		 * @see		#login
		 * @see		#MODMSG_TO_USER
		 * @see		#MODMSG_TO_ROOM
		 * @see		#MODMSG_TO_ZONE
		 * @see		SFSEvent#onModeratorMessage
		 *
		 * @since	SmartFoxServer Pro v1.4.5
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function sendModeratorMessage(message:String, type:String, id:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<txt t='" + type + "' id='" + id + "'><![CDATA[" + Entities.encodeEntities(message) + "]]></txt>"
	
			send(header, "modMsg", (type == MODMSG_TO_ROOM ? id : activeRoomId), xmlMsg)
		}
		
		/**
		 * Send an Actionscript object to the other users in the current room.
		 * This method can be used to send complex/nested data structures to clients, like a game move or a game status change. Supported data types are: Strings, Booleans, Numbers, Arrays, Objects.
		 *
		 * @param	obj:	the Actionscript object to be sent.
		 * @param	roomId:	the id of the target room, in case of multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @sends	SFSEvent#onObjectReceived
		 *
		 * @example	The following example shows how to send a simple object with primitive data to the other users.
		 * 			<code>
		 * 			var move:Object = new Object()
		 * 			move.x = 150
		 * 			move.y = 250
		 * 			move.speed = 8
		 *
		 * 			smartFox.sendObject(move)
		 * 			</code>
		 * 			<hr />
		 *
		 * 			The following example shows how to send an object with two arrays of items to the other users.
		 * 			<code>
		 * 			var itemsFound:Object = new Object()
		 * 			itemsFound.jewels = ["necklace", "ring"]
		 * 			itemsFound.weapons = ["sword", "sledgehammer"]
		 *
		 * 			smartFox.sendObject(itemsFound)
		 * 			</code>
		 *
		 * @see		#sendObjectToGroup
		 * @see		SFSEvent#onObjectReceived
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function sendObject(obj:Object, roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId
				
			var xmlData:String = "<![CDATA[" + ObjectSerializer.getInstance().serialize(obj) + "]]>"
			var header:Object = {t:"sys"}
			
			send(header, "asObj", roomId, xmlData)
		}
		
		/**
		 * Send an Actionscript object to a group of users in the room.
		 * See {@link #sendObject} for more info.
		 *
		 * @param	obj:		the Actionscript object to be sent.
		 * @param	userList:	an array containing the id(s) of the recipients.
		 * @param	roomId:		the id of the target room, in case of multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @sends	SFSEvent#onObjectReceived
		 *
		 * @example	The following example shows how to send a simple object with primitive data to two users.
		 * 			<code>
		 * 			var move:Object = new Object()
		 * 			move.x = 150
		 * 			move.y = 250
		 * 			move.speed = 8
		 *
		 * 			smartFox.sendObjectToGroup(move, [11, 12])
		 * 			</code>
		 *
		 * @see		#sendObject
		 * @see		SFSEvent#onObjectReceived
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function sendObjectToGroup(obj:Object, userList:Array, roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId
			
			var strList:String = ""
			
			for (var i:String in userList)
			{
				if (!isNaN(userList[i]))
					strList += userList[i] + ","
			}
			
			// remove last comma
			strList = strList.substr(0, strList.length - 1)
			
			obj._$$_ = strList
			
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<![CDATA[" + ObjectSerializer.getInstance().serialize(obj) + "]]>"
			
			send(header, "asObjG", roomId, xmlMsg)
		}
		
		/**
		 * Send a request to a server side extension.
		 * The request can be serialized using three different protocols: XML, JSON and String-based (aka "raw protocol").
		 * XML and JSON can both serialize complex objects with any level of nested properties, while the String protocol allows to send linear data delimited by a separator (see the {@link #rawProtocolSeparator} property).
		 *
		 * <b>NOTE</b>: the use JSON instead of XML is highly recommended, as it can save a lot of bandwidth. The String-based protocol can be very useful for realtime applications/games where reducing the amount of data is the highest priority.
		 *
		 * @param	xtName:		the name of the extension (see also the {@link #createRoom} method).
		 * @param	cmd:		the name of the action/command to execute in the extension.
		 * @param	paramObj:	an object containing the data to be passed to the extension (set to empty object if no data is required).
		 * @param	type:		the protocol to be used for serialization (optional). The following constants can be passed: {@link #XTMSG_TYPE_XML}, {@link #XTMSG_TYPE_STR}, {@link #XTMSG_TYPE_JSON}.
		 * @param	roomId:		the id of the room where the request was originated, in case of multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @example	The following example shows how to notify a multiplayer game server-side extension that a game action occurred.
		 * 			<code>
		 * 			// A bullet is being fired
		 * 			var params:Object = new Object()
		 * 			params.type = "bullet"
		 * 			params.posx = 100
		 * 			params.posy = 200
		 * 			params.speed = 10
		 * 			params.angle = 45
		 *
		 * 			// Invoke "fire" command on the extension called "gameExt", using JSON protocol
		 * 			smartFox.sendXtMessage("gameExt", "fire", params, SmartFoxClient.XTMSG_TYPE_JSON)
		 * 			</code>
		 *
		 * @see		#rawProtocolSeparator
		 * @see		#XTMSG_TYPE_XML
		 * @see		#XTMSG_TYPE_JSON
		 * @see		#XTMSG_TYPE_STR
		 * @see		SFSEvent#onExtensionResponse
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function sendXtMessage(xtName:String, cmd:String, paramObj:*, type:String = "xml", roomId:int = -1):void
		{
			if ( !checkRoomList() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId
			
			// Send XML
			if (type == XTMSG_TYPE_XML)
			{
				var header:Object = {t:"xt"}
				
				// Encapsulate message
				var xtReq:Object = {name: xtName, cmd: cmd, param: paramObj}
				var xmlmsg:String= "<![CDATA[" + ObjectSerializer.getInstance().serialize(xtReq) + "]]>"
				
				send(header, "xtReq", roomId, xmlmsg)
			}
			
			// Send raw/String
			else if (type == XTMSG_TYPE_STR)
			{
				var hdr:String = MSG_STR + "xt" + MSG_STR + xtName + MSG_STR + cmd + MSG_STR + roomId + MSG_STR

				for (var i:Number = 0; i < paramObj.length; i++)
					hdr += paramObj[i].toString() + MSG_STR
	
				sendString(hdr)
			}
			
			// Send JSON
			else if (type == XTMSG_TYPE_JSON)
			{
				var body:Object = {}
				body.x = xtName
				body.c = cmd
				body.r = roomId
				body.p = paramObj
				
				var obj:Object = {}
				obj.t = "xt"
				obj.b = body
				
				var msg:String = JSON.stringify(obj)
				sendJson(msg)
			}
		}
		
		/**
		 * Block or unblock a user in the buddy list.
		 * When a buddy is blocked, SmartFoxServer does not deliver private messages from/to that user.
		 *
		 * @param	buddyName:	the name of the buddy to be blocked or unblocked.
		 * @param	status:		{@code true} to block the buddy, {@code false} to unblock the buddy.
		 *
		 * @example	The following example shows how to block a user from the buddy list.
		 * 			<code>
		 * 			smartFox.setBuddyBlockStatus("jack", true)
		 * 			</code>
		 *
		 * @see		#buddyList
		 *
		 * @since	SmartFoxServer Pro v1.6.0
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function setBuddyBlockStatus(buddyName:String, status:Boolean):void
		{
			var b:Object = getBuddyByName(buddyName)
			
			if ( b != null )
			{
				if (b.isBlocked != status)
				{
					b.isBlocked = status
					
					var xmlMsg:String = "<n x='" + (status ? "1" : "0") +"'>" + buddyName + "</n>"
					send({t:"sys"}, "setB", -1, xmlMsg)
					
					// Fire internal update
					var params:Object = {}
					params.buddy = b
					
					var evt:SFSEvent = new SFSEvent(SFSEvent.onBuddyListUpdate, params)
					dispatchEvent(evt)
					
				}
			}
		}
		
		/**
		 * Set the current user's Buddy Variables.
		 * This method allows to set a number of properties of the current user as buddy of other users; in other words these variables will be received by the other users who have the current user as a buddy.
		 *
		 * Buddy Variables are the best way to share user's informations with all the other users having him/her in their buddy list.: for example the nickname, the current audio track the user is listening to, etc. The most typical usage is to set a variable containing the current user status, like "available", "occupied", "away", "invisible", etc.).
		 *
		 * <b>NOTE</b>: before the release of SmartFoxServer Pro v1.6.0, Buddy Variables could not be stored, and existed during the user session only. SmartFoxServer Pro v1.6.0 introduced the ability to persist (store) all Buddy Variables and the possibility to save "offline Buddy Variables" (see the following usage notes).
		 *
		 * @usageNote	Let's assume that three users (A, B and C) use an "istant messenger"-like application, and user A is part of the buddy lists of users B and C.
		 * 				If user A sets his own variables (using the {@link #setBuddyVariables} method), the {@link #myBuddyVars} array on his client gets populated and a {@link SFSEvent#onBuddyListUpdate} event is dispatched to users B and C.
		 * 				User B and C can then read those variables in their own buddy lists by means of the <b>variables</b> property on the buddy object (which can be retrieved from the {@link #buddyList} array by means of the {@link #getBuddyById} or {@link #getBuddyByName} methods).
		 * 				<hr />
		 * 				If the buddy list's <i>advanced security mode</i> is used (see the SmartFoxServer server-side configuration), Buddy Variables persistence is enabled: in this way regular variables are saved when a user goes offline and they are restored (and dispatched to the other users) when their owner comes back online.
		 * 				Also, setting the {@code <offLineBuddyVariables>} parameter to {@code true}, offline variables can be used: this kind of Buddy Variables is loaded regardless the buddy is online or not, providing further informations for each entry in the buddy list. A typical usage for offline variables is to define a buddy image or additional informations such as country, email, rank, etc.
		 * 				To creare an offline Buddy Variable, the "$" character must be placed before the variable name.
		 *
		 * @param	varList:	an associative array, where the key is the name of the variable and the value is the variable's value. Buddy Variables should all be strings. If you need to use other data types you should apply the appropriate type casts.
		 *
		 * @sends	SFSEvent#onBuddyListUpdate
		 *
		 * @example	The following example shows how to set three variables containing the user's status, the current audio track the user listening to and the user's rank. The last one is an offline variable.
		 * 			<code>
		 * 			var bVars:Object = new Object()
		 * 			bVars["status"] = "away"
		 * 			bVars["track"] = "One Of These Days"
		 * 			bVars["$rank"] = "guru"
		 *
		 * 			smartFox.setBuddyVariables(bVars)
		 * 			</code>
		 *
		 * @see		#myBuddyVars
		 * @see		SFSEvent#onBuddyListUpdate
		 *
		 * @history	SmartFoxServer Pro v1.6.0 - Buddy list's <i>advanced security mode</i> implemented (persistent and offline Buddy Variables).
		 *
		 * @version	SmartFoxServer Basic (except <i>advanced mode</i>) / Pro
		 */
		public function setBuddyVariables(varList:Array):void
		{
			var header:Object = {t:"sys"}
			
			// Encapsulate Variables
			var xmlMsg:String = "<vars>"
			
			// Reference to the user setting the variables
			for (var vName:String in varList)
			{
				var vValue:String = varList[vName]
				
				// if variable is new or updated send it and update locally
				if (myBuddyVars[vName] != vValue)
				{
					myBuddyVars[vName] = vValue
					xmlMsg += "<var n='" + vName + "'><![CDATA[" + vValue + "]]></var>"
				}
			}
			
			xmlMsg += "</vars>"
		
			this.send(header, "setBvars", -1, xmlMsg)
		}
		
		/**
		 * Set one or more Room Variables.
		 * Room Variables are a useful feature to share data across the clients, keeping it in a centralized place on the server. When a user sets/updates/deletes one or more Room Variables, all the other users in the same room are notified.
		 * Allowed data types for Room Variables are Numbers, Strings and Booleans; in order save bandwidth, Arrays and Objects are not supported. Nevertheless, an array of values can be simulated, for example, by using an index in front of the name of each variable (check one of the following examples).
		 * If a Room Variable is set to {@code null}, it is deleted from the server.
		 *
		 * @param	varList:		an array of objects with the properties described farther on.
		 * @param	roomId:			the id of the room where the variables should be set, in case of molti-room join (optional, default value: {@link #activeRoomId}).
		 * @param	setOwnership:	{@code false} to prevent the Room Variable change ownership when its value is modified by another user (optional).
		 *
		 * <hr />
		 * Each Room Variable is an object containing the following properties:
		 * @param	name:		(<b>String</b>) the variable name.
		 * @param	val:		(<b>*</b>) the variable value.
		 * @param	priv:		(<b>Boolean</b>) if {@code true}, the variable can be modified by its creator only (optional, default value: {@code false}).
		 * @param	persistent:	(<b>Boolean</b>) if {@code true}, the variable will exist until its creator is connected to the current zone; if {@code false}, the variable will exist until its creator is connected to the current room (optional, default value: {@code false}).
		 *
		 * @sends	SFSEvent#onRoomVariablesUpdate
		 *
		 * @example	The following example shows how to save a persistent Room Variable called "score". This variable won't be destroyed when its creator leaves the room.
		 * 			<code>
		 * 			var rVars:Array = new Array()
		 * 			rVars.push({name:"score", val:2500, persistent:true})
		 *
		 * 			smartFox.setRoomVariables(rVars)
		 * 			</code>
		 *
		 * 			<hr />
		 * 			The following example shows how to save two Room Variables at once. The one called "bestTime" is private and no other user except its owner can modify it.
		 * 			<code>
		 * 			var rVars:Array = new Array()
		 * 			rVars.push({name:"bestTime", val:100, priv:true})
		 * 			rVars.push({name:"bestLap", val:120})
		 *
		 * 			smartFox.setRoomVariables(rVars)
		 * 			</code>
		 *
		 * 			<hr />
		 * 			The following example shows how to delete a Room Variable called "bestTime" by setting its value to {@code null}.
		 * 			<code>
		 * 			var rVars:Array = new Array()
		 * 			rVars.push({name:"bestTime", val:null})
		 *
		 * 			smartFox.setRoomVariables(rVars)
		 * 			</code>
		 *
		 * 			<hr />
		 * 			The following example shows how to send an array-like set of data without consuming too much bandwidth.
		 * 			<code>
		 * 			var rVars:Array = new Array()
		 * 			var names:Array = ["john", "dave", "sam"]
		 *
		 * 			for (var i:int = 0; i < names.length; i++)
		 * 				rVars.push({name:"name" + i, val:names[i]})
		 *
		 * 			smartFox.setRoomVariables(rVars)
		 * 			</code>
		 *
		 * 			<hr />
		 * 			The following example shows how to handle the data sent in the previous example when the {@link SFSEvent#onRoomVariablesUpdate} event is received.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRoomVariablesUpdate, onRoomVariablesUpdateHandler)
		 *
		 * 			function onRoomVariablesUpdateHandler(evt:SFSEvent):void
		 * 			{
		 * 				var changedVars:Array = evt.params.changedVars
		 *
		 * 				// Iterate on the 'changedVars' array to check which variables were updated
		 * 				for (var v:String in changedVars)
		 * 					trace(v + " room variable was updated; new value is: " + evt.params.room.getVariable(v))
		 * 			}
		 * 			</code>
		 *
		 * 			<hr />
		 * 			The following example shows how to update a Room Variable without affecting the variable's ownership.
		 * 			By default, when a user updates a Room Variable, he becomes the "owner" of that variable. In some cases it could be needed to disable this behavoir by setting the <i>setOwnership</i> property to {@code false}.
		 * 			<code>
		 * 			// For example, a variable that is defined in the server-side xml configuration file is owned by the Server itself;
		 * 			// if it's not set to private, its owner will change as soon as a user updates it.
		 * 			// To avoid this change of ownership the setOwnership flag is set to false.
		 * 			var rVars:Array = new Array()
		 * 			rVars.push({name:"shipPosX", val:100})
		 * 			rVars.push({name:"shipPosY", val:200})
		 *
		 * 			smartFox.setRoomVariables(rVars, smartFox.getActiveRoom(), false)
		 * 			</code>
		 *
		 * @see		Room#getVariable
		 * @see		Room#getVariables
		 * @see		SFSEvent#onRoomVariablesUpdate
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function setRoomVariables(varList:Array, roomId:int = -1, setOwnership:Boolean = true):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId
				
			var header:Object = {t:"sys"}
			var xmlMsg:String
			
			if (setOwnership)
				xmlMsg = "<vars>"
			else
				xmlMsg = "<vars so='0'>"
				
			var room:Room = getRoom(roomId);
			var roomVars:Array = room.getVariables();
			for each (var rv:Object in varList) {
				if (roomVars[rv.name] != rv.val)
					xmlMsg += getXmlRoomVariable(rv)
			}
				
			xmlMsg += "</vars>"
			
			send(header, "setRvars", roomId, xmlMsg)
		}
		
		/**
		 * Set on or more User Variables.
		 * User Variables are a useful tool to store user data that has to be shared with other users. When a user sets/updates/deletes one or more User Variables, all the other users in the same room are notified.
		 * Allowed data types for User Variables are Numbers, Strings and Booleans; Arrays and Objects are not supported in order save bandwidth.
		 * If a User Variable is set to {@code null}, it is deleted from the server. Also, User Variables are destroyed when their owner logs out or gets disconnected.
		 *
		 * @param	varObj:		an object in which each property is a variable to set/update.
		 * @param	roomId:		the room id where the request was originated, in case of molti-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @sends	SFSEvent#onUserVariablesUpdate
		 *
		 * @example	The following example shows how to save the user data (avatar name and position) in an avatar chat application.
		 * 			<code>
		 * 			var uVars:Object = new Object()
		 * 			uVars.myAvatar = "Homer"
		 * 			uVars.posx = 100
		 * 			uVars.posy = 200
		 *
		 * 			smartFox.setUserVariables(uVars)
		 * 			</code>
		 *
		 * @see		User#getVariable
		 * @see		User#getVariables
		 * @see		SFSEvent#onUserVariablesUpdate
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function setUserVariables(varObj:Object, roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId
				
			var header:Object = {t:"sys"}

			for each (var room:Room in getAllRooms()) {
				var user:User = room.getUser(myUserId);
				if (user != null)
					user.setVariables(varObj);
			}

			// Prepare and send message
			var xmlMsg:String = getXmlUserVariable(varObj)
			send(header, "setUvars", roomId, xmlMsg)
		}
		
		/**
		 * Turn a spectator inside a game room into a player.
		 * All spectators have their <b>player id</b> property set to -1; when a spectator becomes a player, his player id gets a number > 0, representing the player number. The player id values are assigned by the server, based on the order in which the players joined the room.
		 * If the user joined more than one room, the id of the room where the switch should occurr must be passed to this method.
		 * The switch operation is successful only if at least one player slot is available in the room.
		 *
		 * @param	roomId:	the id of the room where the spectator should be switched, in case of multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @sends	SFSEvent#onSpectatorSwitched
		 *
		 * @example	The following example shows how to turn a spectator into a player.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onSpectatorSwitched, onSpectatorSwitchedHandler)
		 *
		 * 			smartFox.switchSpectator()
		 *
		 * 			function onSpectatorSwitchedHandler(evt:SFSEvent):void
		 * 			{
		 * 				if (evt.params.success)
		 * 					trace("You have been turned into a player; your player id is " + evt.params.newId)
		 * 				else
		 * 					trace("The attempt to switch from spectator to player failed")
		 * 			}
		 * 			</code>
		 *
		 * @see		User#isSpectator
		 * @see		SFSEvent#onSpectatorSwitched
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function switchSpectator(roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId

			send({t:"sys"}, "swSpec", roomId, "")
		}
		
		
		/**
		 * Turn a player inside a game room into a spectator.
		 * All players have their <b>player id</b> property set to a value > 0; when a spectator becomes a player, his playerId is set to -1.
		 * If the user joined more than one room, the id of the room where the switch should occurr must be passed to this method.
		 * The switch operation is successful only if at least one spectator slot is available in the room.
		 *
		 * @param	roomId:	the id of the room where the player should be switched to spectator, in case of multi-room join (optional, default value: {@link #activeRoomId}).
		 *
		 * @sends	SFSEvent#onPlayerSwitched
		 *
		 * @example	The following example shows how to turn a player into a spectator.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onPlayerSwitched, onPlayerSwitchedHandler)
		 *
		 * 			smartFox.switchPlayer()
		 *
		 * 			function onPlayerSwitchedHandler(evt:SFSEvent):void
		 * 			{
		 * 				if (evt.params.success)
		 * 					trace("You have been turned into a spectator; your id is: " + evt.params.newId)
		 * 				else
		 * 					trace("The attempt to switch from player to spectator failed!")
		 * 			}
		 * 			</code>
		 *
		 * @see		User#isSpectator
		 * @see		SFSEvent#onPlayerSwitched
		 *
		 * @version	SmartFoxServer Pro
		 */
		public function switchPlayer(roomId:int = -1):void
		{
			if ( !checkRoomList() || !checkJoin() )
				return
				
			if (roomId == -1)
				roomId = activeRoomId

			send({t:"sys"}, "swPl", roomId, "")
		}
		
		/**
		 * Upload a file to the embedded webserver.
		 *
		 * <b>NOTE</b>: upload events fired in response should be handled by the provided FileReference object (see the example).
		 *
		 * @param	fileRef:	the FileReference object (see the example).
		 * @param	id:			the user id (optional, default value: {@link #myUserId}).
		 * @param	nick:		the user name (optional, default value: {@link #myUserName}).
		 * @param	port:		the webserver's TCP port (optional, default value: {@link #httpPort}).
		 *
		 * @example	Check the Upload Tutorial available here: {@link http://www.smartfoxserver.com/docs/docPages/tutorials_pro/14_imageManager/}
		 *
		 * @see		#myUserId
		 * @see		#myUserName
		 * @see		#httpPort
		 *
		 * @since	SmartFoxServer Pro v1.5.0
		 *
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function uploadFile(fileRef:FileReference, id:int = -1, nick:String = "", port:int = -1):void
		{
			if (id == -1)
				id = this.myUserId
		
			if (nick == "")
				nick = this.myUserName
				
			if (port == -1)
				port = this.httpPort
			
			fileRef.upload(new URLRequest("http://" + this.ipAddress + ":" + port + "/default/Upload.py?id=" + id + "&nick=" + nick))

			debugMessage("[UPLOAD]: http://" + this.ipAddress + ":" + port + "/default/Upload.py?id=" + id + "&nick=" + nick)
		}
		
		/**
		 * @private
		 */
		public function __logout():void
		{
			initialize(true)
		}
		
		/**
		 * @private
		 */
		public function sendString(strMessage:String):void
		{
			debugMessage("[Sending - STR]: " + strMessage + "\n")
			
			if (isHttpMode)
				httpConnection.send(strMessage)
			else
				writeToSocket(strMessage)
		}
		
		/**
		 * @private
		 */
		public function sendJson(jsMessage:String):void
		{
			debugMessage("[Sending - JSON]: " + jsMessage + "\n")
			
			if (isHttpMode)
				httpConnection.send(jsMessage)
			else
				writeToSocket(jsMessage)
		}
		
		/**
		 * @private
		 */
		public function getBenchStartTime():int
		{
			return this.benchStartTime
		}
		
		/**
		 * @private
		 */
		public function clearRoomList():void
		{
			this.roomList = []
		}
		
		// -------------------------------------------------------
		// Private methods
		// -------------------------------------------------------
		
		private function initialize(isLogOut:Boolean = false):void
		{
			// Clear local properties
			this.changingRoom = false
			this.amIModerator = false
			this.playerId = -1
			this.activeRoomId = -1
			this.myUserId = -1
			this.myUserName = ""
			
			// Clear data structures
			this.roomList = []
			this.buddyList = []
			this.myBuddyVars = []
			
			// Set connection status
			if (!isLogOut)
			{
				this.connected = false
				this.isHttpMode = false
			}
		}
		
		private function onConfigLoadSuccess( evt:Event ):void
		{
			var loader:URLLoader = evt.target as URLLoader
			var xmlDoc:XML = new XML( loader.data )

			this.ipAddress = this.blueBoxIpAddress = xmlDoc.ip
			this.port = int(xmlDoc.port)
			this.defaultZone = xmlDoc.zone
			
			if ( xmlDoc.blueBoxIpAddress != undefined )
				this.blueBoxIpAddress = xmlDoc.blueBoxIpAddress
				
			if ( xmlDoc.blueBoxPort != undefined )
				this.blueBoxPort = xmlDoc.blueBoxPort
				
			if ( xmlDoc.debug != undefined )
				this.debug = xmlDoc.debug.toLowerCase() == "true" ? true : false
				
			if ( xmlDoc.smartConnect != undefined )
				this.smartConnect = xmlDoc.smartConnect.toLowerCase() == "true" ? true : false
							
			if ( xmlDoc.httpPort != undefined )
				this.httpPort = int( xmlDoc.httpPort )
			
			if ( xmlDoc.httpPollSpeed != undefined )
				this.httpPollSpeed = int (xmlDoc.httpPollSpeed)
			
			if ( xmlDoc.rawProtocolSeparator != undefined )
				rawProtocolSeparator = xmlDoc.rawProtocolSeparator

			if ( autoConnectOnConfigSuccess )
				this.connect( ipAddress, port )
			else
			{
				// Dispatch onConfigLoadSuccess event
				var sfsEvt:SFSEvent = new SFSEvent( SFSEvent.onConfigLoadSuccess, {} )
				dispatchEvent( sfsEvt )
			}
		}
		
		private function onConfigLoadFailure( evt:IOErrorEvent ):void
		{
			var params:Object = { message:evt.text }
			var sfsEvt:SFSEvent = new SFSEvent( SFSEvent.onConfigLoadFailure, params )
			
			dispatchEvent( sfsEvt )
		}
		
		private function setupMessageHandlers():void
		{
			sysHandler = new SysHandler(this)
			extHandler = new ExtHandler(this)
			
			addMessageHandler("sys", sysHandler)
			addMessageHandler("xt", extHandler)
		}
		
		
		private function addMessageHandler(key:String, handler:IMessageHandler):void
		{
			if (this.messageHandlers[key] == null)
			{
				this.messageHandlers[key] = handler
			}
			else
				debugMessage("Warning, message handler called: " + key + " already exist!")
		}
		
		private function debugMessage(message:String):void
		{
			if (this.debug)
			{
				trace(message)
				
				var evt:SFSEvent = new SFSEvent(SFSEvent.onDebugMessage, {message:message})
				dispatchEvent(evt)
			}
		}
		
		private function send(header:Object, action:String, fromRoom:Number, message:String):void
		{
			// Setup Msg Header
			var xmlMsg:String = makeXmlHeader(header)
			
			// Setup Body
			xmlMsg += "<body action='" + action + "' r='" + fromRoom + "'>" + message + "</body>" + closeHeader()
		
			debugMessage("[Sending]: " + xmlMsg + "\n")
			
			if (isHttpMode)
				httpConnection.send(xmlMsg)
			else
				writeToSocket(xmlMsg)
		}
		
		private function writeToSocket(msg:String):void
		{
			var byteBuff:ByteArray = new ByteArray()
			byteBuff.writeMultiByte(msg, "utf-8")
			byteBuff.writeByte(0)
			
			socketConnection.writeBytes(byteBuff)
			socketConnection.flush()
		}
		
		private function makeXmlHeader(headerObj:Object):String
		{
			var xmlData:String = "<msg"
		
			for (var item:String in headerObj)
			{
				xmlData += " " + item + "='" + headerObj[item] + "'"
			}
		
			xmlData += ">"
		
			return xmlData
		}
		
		private function closeHeader():String
		{
			return "</msg>"
		}
		
		private function checkBuddyDuplicates(buddyName:String):Boolean
		{
			// Check for buddy duplicates in the current buddy list
			
			var res:Boolean = false
		
			for each(var buddy:Object in buddyList)
			{
				if (buddy.name == buddyName)
				{
					res = true
					break
				}
			}
			
			return res
		}
		
		private function xmlReceived(msg:String):void
		{
			// Got XML response
			
			var xmlData:XML = new XML(msg)
			var handlerId:String = xmlData.@t
			var action:String = xmlData.body.@action
			var roomId:int = xmlData.body.@r
			
			var handler:IMessageHandler = messageHandlers[handlerId]
			
			if (handler != null)
				handler.handleMessage(xmlData, XTMSG_TYPE_XML)
		}
		
		private function jsonReceived(msg:String):void
		{
			// Got JSON response
			
			var jso:Object = JSON.parse(msg)

			var handlerId:String = jso["t"]
			var handler:IMessageHandler = messageHandlers[handlerId]
			
			if (handler != null)
				handler.handleMessage(jso["b"], XTMSG_TYPE_JSON)
		}
		
		private function strReceived(msg:String):void
		{
			// Got String response
			
			var params:Array = msg.substr(1, msg.length - 2).split(MSG_STR)

			var handlerId:String = params[0]
			var handler:IMessageHandler = messageHandlers[handlerId]
			
			if (handler != null)
				handler.handleMessage(params.splice(1, params.length - 1), XTMSG_TYPE_STR)
		}
		
		private function getXmlRoomVariable(rVar:Object):String
		{
			// Get properties for this var
			var vName:String		= rVar.name.toString()
			var vValue:*	 		= rVar.val
			var vPrivate:String		= (rVar.priv) ? "1":"0"
			var vPersistent:String	= (rVar.persistent) ? "1":"0"
			
			var t:String = null
			var type:String = typeof(vValue)
			
			// Check type
			if (type == "boolean")
			{
				t = "b"
				vValue = (vValue) ? "1" : "0"			// transform in number before packing in xml
			}
			
			else if (type == "number")
			{
				t = "n"
			}
			
			else if (type == "string")
			{
				t = "s"
			}
			
			/*
			* !!Warning!!
			* Dynamic typed vars (*) when set to null:
			* 	type = object, val = "null".
			* 	Also they can use undefined type.
			*
			* Static typed vars when set to null:
			* 	type = null, val = "null"
			* 	undefined = null
			*/
			else if ((vValue == null && type == "object") || type == "undefined")
			{
				t = "x"
				vValue = ""
			}
		
			if (t != null)
				return "<var n='" + vName + "' t='" + t + "' pr='" + vPrivate + "' pe='" + vPersistent + "'><![CDATA[" + vValue + "]]></var>"
			else
				return ""
		}
		
		private function getXmlUserVariable(uVars:Object):String
		{
			var xmlStr:String = "<vars>"
			var val:*
			var t:String
			var type:String
			
			for (var key:String in uVars)
			{
				val = uVars[key]
				type = typeof(val)
				t = null

				// Check types
				if (type == "boolean")
				{
					t = "b"
					val = (val) ? "1" : "0"
				}
				
				else if (type == "number")
				{
					t = "n"
				}
				
				else if (type == "string")
				{
					t = "s"
				}
				
				/*
				* !!Warning!!
				* Dynamic typed vars (*) when set to null:
				* 	type = object, val = "null".
				* 	Also they can use undefined type.
				*
				* Static typed vars when set to null:
				* 	type = null, val = "null"
				* 	undefined = null
				*/
				else if ((val == null && type == "object") || type == "undefined")
				{
					t = "x"
					val = ""
				}
				
				if (t != null)
					xmlStr += "<var n='" + key + "' t='" + t + "'><![CDATA[" + val + "]]></var>"
			}
			
			xmlStr += "</vars>"
			
			return xmlStr
		}
		
		private function checkRoomList():Boolean
		{
			var success:Boolean = true
			
			if (roomList == null || roomList.length == 0)
			{
				success = false
				errorTrace("The room list is empty!\nThe client API cannot function properly until the room list is populated.\nPlease consult the documentation for more infos.")
			}
			
			return success
		}
		
		private function checkJoin():Boolean
		{
			var success:Boolean = true
			
			if (activeRoomId < 0)
			{
				success = false
				errorTrace("You haven't joined any rooms!\nIn order to interact with the server you should join at least one room.\nPlease consult the documentation for more infos.")
			}
			
			return success
		}

		private function errorTrace(msg:String):void
		{
			trace("\n****************************************************************")
			trace("Warning:")
			trace(msg)
			trace("****************************************************************")
		}
		
		// -------------------------------------------------------
		// Internal Http Event Handlers
		// -------------------------------------------------------
		
		private function handleHttpConnect(evt:HttpEvent):void
		{
			this.handleSocketConnection(null)
			
			connected = true
			
			httpConnection.send( HTTP_POLL_REQUEST )
		}
		
		private function handleHttpClose(evt:HttpEvent):void
		{
			//trace("HttpClose")
			
			// Clear data
		 	initialize()

		 	// Fire event
	 		var sfse:SFSEvent = new SFSEvent(SFSEvent.onConnectionLost, {})
	 		dispatchEvent(sfse)
		}
		
		private function handleHttpData(evt:HttpEvent):void
		{
			var data:String = evt.params.data as String
			var messages:Array = data.split("\n")
			var message:String
			
			if (messages[0] != "")
			{
				/*
				if (messages[0] != "ok")
					trace("  HTTP DATA ---> " + messages + " (len: " + messages.length + ")")
				*/
				
				for (var i:int = 0; i < messages.length - 1; i++)
				{
					message = messages[i]
					
					if (message.length > 0)
						handleMessage(message)
				}
				
				/*
				*	Sleep a little before sending next poll request
				*	WARNING: without delay the server may use too many requests
				*/
				if (this._httpPollSpeed > 0)
				{
					setTimeout( this.handleDelayedPoll, this._httpPollSpeed )
				}
				else
				{
					handleDelayedPoll()
				}
			}
		}
		
		private function handleDelayedPoll():void
		{
			httpConnection.send( HTTP_POLL_REQUEST )
		}
		
		private function handleHttpError(evt:HttpEvent):void
		{
			trace("HttpError")
			if (!connected)
			{
				dispatchConnectionError()
			}
		}
		
		// -------------------------------------------------------
		// Internal Socket Event Handlers
		// -------------------------------------------------------
		
		private function handleSocketConnection(e:Event):void
		{
			var header:Object = {t:"sys"}
			var xmlMsg:String = "<ver v='" + this.majVersion.toString() + this.minVersion.toString() + this.subVersion.toString() + "' />"
			
			send(header, "verChk", 0, xmlMsg)
		}
		
		private function handleSocketDisconnection(evt:Event):void
		{
			// Clear data
			initialize()
			
			// Fire event
	 		var sfse:SFSEvent = new SFSEvent(SFSEvent.onConnectionLost, {})
	 		dispatchEvent(sfse)
		}
		
		private function handleIOError(evt:IOErrorEvent):void
		{
			tryBlueBoxConnection(evt)
		}
		
		/*
		* New in 1.5.4
		*/
		private function tryBlueBoxConnection(evt:ErrorEvent):void
		{
			if (!connected)
			{
				if (smartConnect)
				{
					debugMessage("Socket connection failed. Trying BlueBox")
					
					isHttpMode = true
					var __ip:String = blueBoxIpAddress != null ? blueBoxIpAddress : ipAddress
					var __port:int = blueBoxPort != 0 ? blueBoxPort : httpPort
					
					httpConnection.connect( __ip, __port )
				}
				else
					dispatchConnectionError()
				
			}
			else
			{
				// Dispatch back the IO error
				dispatchEvent(evt)
		    	debugMessage("[WARN] Connection error: " + evt.text)
			}
		}
		
		private function handleSocketError(evt:SecurityErrorEvent):void
		{
			debugMessage("Socket Error: " + evt.text)
		}
		
		private function handleSecurityError(evt:SecurityErrorEvent):void
		{
			tryBlueBoxConnection(evt)
		}
		
		private function handleSocketData(evt:Event):void
		{
			var bytes:int = socketConnection.bytesAvailable
		
		   while (--bytes >= 0)
		   {
		   	var b:int = socketConnection.readByte()
		
		   	if (b != 0x00)
		   	{
		   		byteBuffer.writeByte(b)
		   	}
		   	else
		   	{
		   		handleMessage(byteBuffer.toString())
		   		byteBuffer = new ByteArray()
		   	}
		   }
		}
		
		/*
		 * Analyze incoming message
		 */
		private function handleMessage(msg:String):void
		{
			if (msg != "ok")
				debugMessage("[ RECEIVED ]: " + msg + ", (len: " + msg.length + ")")
			
			var type:String = msg.charAt(0)

			if (type == MSG_XML)
			{
				xmlReceived(msg)
			}
			else if (type == MSG_STR)
			{
				strReceived(msg)
			}
			else if (type == MSG_JSON)
			{
				jsonReceived(msg)
			}
		}
		
		private function dispatchConnectionError():void
		{
			var params:Object = {}
	 		params.success = false
	 		params.error = "I/O Error"
	
	 		var sfse:SFSEvent = new SFSEvent(SFSEvent.onConnection, params)
	 		dispatchEvent(sfse)
		}
	}
}
