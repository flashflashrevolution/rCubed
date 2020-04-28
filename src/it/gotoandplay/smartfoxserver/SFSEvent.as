package it.gotoandplay.smartfoxserver
{
	import flash.events.Event;
	
	/**
	 * SFSEvent is the class representing all events dispatched by the {@link SmartFoxClient} instance.
	 * The SFSEvent class extends the flash.events.Event class and provides a public property called {@link #params} of type {@code Object} that can contain any number of parameters.
	 * 
	 * @usage	The following example show a generic usage of a SFSEvent. Please refer to the specific events for the {@link #params} object content.
	 * 			<code>
	 * 			package sfsTest
	 * 			{
	 *				import it.gotoandplay.smartfoxserver.SmartFoxClient
	 *				import it.gotoandplay.smartfoxserver.SFSEvent
	 *				
	 *				public class MyTest
	 *				{
	 *					private var smartFox:SmartFoxClient
	 *					
	 *					public function MyTest()
	 *					{
	 *						// Create instance
	 *						smartFox = new SmartFoxClient()
	 *						
	 *						// Add event handler for connection 
	 *						smartFox.addEventListener(SFSEvent.onConnection, onConnectionHandler)
	 *						
	 *						// Connect to server
	 *						smartFox.connect("127.0.0.1", 9339)	
	 *					}
	 *					
	 *					// Handle connection event
	 *					public function onConnectionHandler(evt:SFSEvent):void
	 *					{
	 *						if (evt.params.success)
	 *							trace("Great, successfully connected!")
	 *						else
	 *							trace("Ouch, connection failed!")
	 *					}	
	 *				}
	 * 			}
	 * 			</code>
	 * 			<b>NOTE</b>: in the following examples, {@code smartFox} always indicates a SmartFoxClient instance.
	 * 
	 * @version	1.1.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 */
	public class SFSEvent extends Event
	{
		// Public event type constants ...
		
		/**
		 * Dispatched when a message from the Administrator is received.
		 * Admin messages are special messages that can be sent by an Administrator to a user or group of users.
		 * All client applications should handle this event, or users won't be be able to receive important admin notifications!
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	message:	(<b>String</b>) the Administrator's message.
		 * 
		 * @example	The following example shows how to handle a message coming from the Administrator.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onAdminMessage, onAdminMessageHandler)
		 * 			
		 * 			function onAdminMessageHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Administrator said: " + evt.params.message)
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onModeratorMessage
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onAdminMessage:String = "onAdminMessage"
		
		
		/**
		 * Dispatched when the buddy list for the current user is received or a buddy is added/removed.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	list:	(<b>Array</b>) the buddy list. Refer to the {@link SmartFoxClient#buddyList} property for a description of the buddy object's properties.
		 * 
		 * @example	The following example shows how to retrieve the properties of each buddy when the buddy list is received.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onBuddyList, onBuddyListHandler)
		 * 			
		 * 			smartFox.loadBuddyList()		
		 * 
		 * 			function onBuddyListHandler(evt:SFSEvent):void
		 * 			{
		 * 				for (var b:String in evt.params.list)
		 * 				{
		 * 					var buddy:Object = evt.params.list[b]
		 * 					
		 * 					trace("Buddy id: " + buddy.id)
		 * 					trace("Buddy name: " + buddy.name)
		 * 					trace("Is buddy online? " + buddy.isOnline ? "Yes" : "No")
		 * 					trace("Is buddy blocked? " + buddy.isBlocked ? "Yes" : "No")
		 * 					
		 * 					trace("Buddy Variables:")
		 * 					for (var v:String in buddy.variables)
		 * 						trace("\t" + v + " --> " + buddy.variables[v])
		 * 				}
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onBuddyListError
		 * @see		#onBuddyListUpdate
		 * @see		#onBuddyRoom
		 * @see		SmartFoxClient#buddyList
		 * @see		SmartFoxClient#loadBuddyList
		 * @see		SmartFoxClient#addBuddy
		 * @see		SmartFoxClient#removeBuddy
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onBuddyList:String = "onBuddyList"
		
		
		/**
		 * Dispatched when an error occurs while loading the buddy list.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	error:	(<b>String</b>) the error message.
		 * 
		 * @example	The following example shows how to handle a potential error in buddy list loading.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onBuddyListError, onBuddyListErrorHandler)
		 * 			
		 * 			function onBuddyListErrorHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("An error occurred while loading the buddy list: " + evt.params.error)
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onBuddyList
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onBuddyListError:String = "onBuddyListError"
		
		
		/**
		 * Dispatched when the status or variables of a buddy in the buddy list change.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	buddy:	(<b>Object</b>) an object representing the buddy whose status or Buddy Variables have changed. Refer to the {@link SmartFoxClient#buddyList} property for a description of the buddy object's properties.
		 * 
		 * @example	The following example shows how to handle the online status change of a buddy.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onBuddyListUpdate, onBuddyListUpdateHandler)
		 * 			
		 * 			function onBuddyListUpdateHandler(evt:SFSEvent):void
		 * 			{
		 * 				var buddy:Object = evt.params.buddy
		 * 				
		 * 				var name:String = buddy.name
		 * 				var status:String = (buddy.isOnline) ? "online" : "offline"
		 * 
		 * 				trace("Buddy " + name + " is currently " + status)
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onBuddyList
		 * @see		SmartFoxClient#buddyList
		 * @see		SmartFoxClient#setBuddyBlockStatus
		 * @see		SmartFoxClient#setBuddyVariables
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onBuddyListUpdate:String = "onBuddyListUpdate"
		
		
		/**
		 * Dispatched when the current user receives a request to be added to the buddy list of another user.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	sender:		(<b>String</b>) the name of the user requesting to add the current user to his/her buddy list.
		 * @param	message:	(<b>String</b>) a message accompaining the permission request. This message can't be sent from the client-side, but it's part of the advanced server-side buddy list features.
		 * 
		 * @example	The following example shows how to handle the request to be added to a buddy list.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onBuddyPermissionRequest, onBuddyPermissionRequestHandler)
		 * 			
		 * 			function onBuddyPermissionRequestHandler(evt:SFSEvent):void
		 * 			{
		 * 				// Create alert using custom class from Flash library
		 * 				var alert_mc:CustomAlertPanel = new CustomAlertPanel()
		 * 				
		 * 				alert_mc.name_lb.text = evt.params.sender
		 * 				alert_mc.message_lb.text = evt.params.message
		 * 				
		 * 				// Display alert
		 * 				addChild(alert_mc)
		 * 			}
		 * 			</code>
		 * 
		 * @see		SmartFoxClient#addBuddy
		 * 
		 * @since	SmartFoxServer Pro v1.6.0
		 * 
		 * @version	SmartFoxServer Pro
		 */
		public static const onBuddyPermissionRequest:String = "onBuddyPermissionRequest"
		
		
		/**
		 * Dispatched in response to a {@link SmartFoxClient#getBuddyRoom} request.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	idList:	(<b>Array</b>) the list of id of the rooms in which the buddy is currently logged; if users can't be present in more than one room at the same time, the list will contain one room id only, at 0 index.
		 * 
		 * @example	The following example shows how to join the same room in which the buddy currently is.
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
		 * @see		SmartFoxClient#getBuddyRoom
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onBuddyRoom:String = "onBuddyRoom"
		
		
		/**
		 * Dispatched when an error occurs while loading the external SmartFoxClient configuration file.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	message:	(<b>String</b>) the error message.
		 * 
		 * @example	The following example shows how to handle a potential error in configuration loading.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onConfigLoadFailure, onConfigLoadFailureHandler)
		 * 			
		 * 			smartFox.loadConfig("testEnvironmentConfig.xml")
		 * 			
		 * 			function onConfigLoadFailureHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Failed loading config file: " + evt.params.message)
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onConfigLoadSuccess
		 * @see		SmartFoxClient#loadConfig
		 * 
		 * @since	SmartFoxServer Pro v1.6.0
		 * 
		 * @version	SmartFoxServer Pro
		 */
		public static const onConfigLoadFailure:String = "onConfigLoadFailure"
		
		
		/**
		 * Dispatched when the external SmartFoxClient configuration file has been loaded successfully.
		 * This event is dispatched only if the <i>autoConnect</i> parameter of the {@link SmartFoxClient#loadConfig} method is set to {@code false}; otherwise the connection is made and the {@link #onConnection} event fired.
		 * 
		 * No parameters are provided.
		 * 
		 * @example	The following example shows how to handle a successful configuration loading.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onConfigLoadSuccess, onConfigLoadSuccessHandler)
		 * 			
		 * 			smartFox.loadConfig("testEnvironmentConfig.xml", false)
		 * 			
		 * 			function onConfigLoadSuccessHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Config file loaded, now connecting...")
		 * 				
		 * 				smartFox.connect(smartFox.ipAddress, smartFox.port)
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onConfigLoadFailure
		 * @see		SmartFoxClient#loadConfig
		 * 
		 * @since	SmartFoxServer Pro v1.6.0
		 * 
		 * @version	SmartFoxServer Pro
		 */
		public static const onConfigLoadSuccess:String = "onConfigLoadSuccess"
		
		
		
		/**
		 * Dispatched in response to the {@link SmartFoxClient#connect} request.
		 * The connection to SmartFoxServer may have succeeded or failed: the <i>success</i> parameter must be checked.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	success:	(<b>Boolean</b>) the connection result: {@code true} if the connection succeeded, {@code false} if the connection failed.
		 * @param	error:		(<b>String</b>) the error message in case of connection failure.
		 * 
		 * @example	The following example shows how to handle the connection result.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onConnection, onConnectionHandler)
		 *						
		 *			smartFox.connect("127.0.0.1", 9339)
		 *					
		 *			function onConnectionHandler(evt:SFSEvent):void
		 *			{
		 *				if (evt.params.success)
		 *					trace("Connection successful")
		 *				else
		 *					trace("Connection failed")
		 *			}
		 * 			</code>
		 * 
		 * @see		SmartFoxClient#connect
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onConnection:String = "onConnection"
		
		
		/**
		 * Dispatched when the connection with SmartFoxServer is closed (either from the client or from the server).
		 * 
		 * No parameters are provided.
		 * 
		 * @example	The following example shows how to handle a "connection lost" event.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onConnectionLost, onConnectionLostHandler)
		 * 			
		 * 			function onConnectionLostHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Connection lost!")
		 * 				
		 * 				// TODO: disable application interface
		 * 			}
		 * 			</code>
		 * 
		 * @see		SmartFoxClient#disconnect
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onConnectionLost:String = "onConnectionLost"
		
		
		/**
		 * Dispatched when an error occurs during the creation of a room.
		 * Usually this happens when a client tries to create a room but its name is already taken.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	error:	(<b>String</b>) the error message.
		 * 
		 * @example	The following example shows how to handle a potential error in room creation.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onCreateRoomError, onCreateRoomErrorHandler)
		 * 			
		 * 			var roomObj:Object = new Object()
		 * 			roomObj.name = "The Entrance"
		 * 			roomObj.maxUsers = 50
		 * 			
		 * 			smartFox.createRoom(roomObj)
		 * 			
		 * 			function onCreateRoomErrorHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Room creation error; the following error occurred: " + evt.params.error)
		 * 			}
		 * 			</code>
		 * 
		 * @see		SmartFoxClient#createRoom
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onCreateRoomError:String = "onCreateRoomError"
		
		
		/**
		 * Dispatched when a debug message is traced by the SmartFoxServer API.
		 * In order to receive this event you have to previously set the {@link SmartFoxClient#debug} flag to {@code true}.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	message:	(<b>String</b>) the debug message.
		 * 
		 * @example	The following example shows how to handle a SmartFoxServer API debug message.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onDebugMessage, onDebugMessageHandler)
		 * 			
		 * 			smartFox.debug = true
		 * 			
		 * 			function onDebugMessageHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("[SFS DEBUG] " + evt.params.message)
		 * 			}
		 * 			</code>
		 * 
		 * @see		SmartFoxClient#debug
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onDebugMessage:String = "onDebugMessage"
		
		
		/**
		 * Dispatched when a command/response from a server-side extension is received.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	dataObj:	(<b>Object</b>) an object containing all the data sent by the server-side extension; by convention, a String property called <b>_cmd</b> should always be present, to distinguish between different responses coming from the same extension.
		 * @param	type:		(<b>String</b>) one of the following response protocol types: {@link SmartFoxClient#XTMSG_TYPE_XML}, {@link SmartFoxClient#XTMSG_TYPE_STR}, {@link SmartFoxClient#XTMSG_TYPE_JSON}. By default {@link SmartFoxClient#XTMSG_TYPE_XML} is used.
		 * 
		 * @example	The following example shows how to handle an extension response.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onExtensionResponse, onExtensionResponseHandler)
		 * 			
		 * 			function onExtensionResponseHandler(evt:SFSEvent):void
		 * 			{
		 * 				var type:String = evt.params.type
		 * 				var data:Object = evt.params.dataObj
		 * 				
		 * 				var command:String = data._cmd
		 * 				
		 * 				// Handle XML responses
		 * 				if (type == SmartFoxClient.XTMSG_TYPE_XML)
		 * 				{
		 * 					// TODO: check command and perform required actions
		 * 				}
		 * 				
		 * 				// Handle RAW responses
		 * 				else if (type == SmartFoxClient.XTMSG_TYPE_STR)
		 * 				{
		 * 					// TODO: check command and perform required actions
		 * 				}
		 * 				
		 * 				// Handle JSON responses
		 * 				else if (type == SmartFoxClient.XTMSG_TYPE_JSON)
		 * 				{
		 * 					// TODO: check command and perform required actions
		 * 				}
		 * 			}
		 * 			</code>
		 * 
		 * @see		SmartFoxClient#XTMSG_TYPE_XML
		 * @see		SmartFoxClient#XTMSG_TYPE_STR
		 * @see		SmartFoxClient#XTMSG_TYPE_JSON
		 * @see		SmartFoxClient#sendXtMessage
		 * 
		 * @version	SmartFoxServer Pro
		 */
		public static const onExtensionResponse:String = "onExtensionResponse"
		
		
		/**
		 * Dispatched when a room is joined successfully.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	room:	(<b>Room</b>) the {@link Room} object representing the joined room.
		 * 
		 * @example	The following example shows how to handle an successful room joining.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onJoinRoom, onJoinRoomHandler)
		 * 			
		 * 			smartFox.joinRoom("The Entrance")
		 * 			
		 * 			function onJoinRoomHandler(evt:SFSEvent):void
		 * 			{
		 * 				var joinedRoom:Room = evt.params.room
		 * 				
		 * 				trace("Room " + joinedRoom.getName() + " joined successfully")
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onJoinRoomError
		 * @see		Room
		 * @see		SmartFoxClient#joinRoom
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */	
		public static const onJoinRoom:String = "onJoinRoom"
		
		
		/**
		 * Dispatched when an error occurs while joining a room.
		 * This error could happen, for example, if the user is trying to join a room which is currently full.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	error:	(<b>String</b>) the error message.
		 * 
		 * @example	The following example shows how to handle a potential error in room joining.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onJoinRoomError, onJoinRoomErrorHandler)
		 * 			
		 * 			smartFox.joinRoom("The Entrance")
		 * 			
		 * 			function onJoinRoomErrorHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Room join error; the following error occurred: " + evt.params.error)
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onJoinRoom
		 * @see		SmartFoxClient#joinRoom
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onJoinRoomError:String = "onJoinRoomError"
		
		
		/**
		 * Dispatched when the login to a SmartFoxServer zone has been attempted.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	success:	(<b>Boolean</b>) the login result: {@code true} if the login to the provided zone succeeded; {@code false} if login failed.
		 * @param	name:		(<b>String</b>) the user's actual username.
		 * @param	error:		(<b>String</b>) the error message in case of login failure.
		 * 
		 * <b>NOTE 1</b>: the server sends the username back to the client because not all usernames are valid: for example, those containing bad words may have been filtered during the login process.
		 * 
		 * <b>NOTE 2</b>: for SmartFoxServer PRO. If the Zone you are accessing uses a custom login the login-response will be sent from server side and you will need to handle it using the <b>onExtensionResponse</b> handler.
		 * Additionally you will need to manually set the myUserId and myUserName properties if you need them. (This is automagically done by the API when using a <em>default login</em>)
		 *
		 * @example	The following example shows how to handle the login result.
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
		 * @see		#onLogout
		 * @see		SmartFoxClient#login
		 * @see		#onExtensionResponse
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onLogin:String = "onLogin"
		
		
		/**
		 * Dispatched when the user logs out successfully.
		 * After a successful logout the user is still connected to the server, but he/she has to login again into a zone, in order to be able to interact with the server.
		 * 
		 * No parameters are provided.
		 * 
		 * @example	The following example shows how to handle the "logout" event.
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
		 * @see		#onLogin
		 * @see		SmartFoxClient#logout
		 * 
		 * @since	SmartFoxServer Pro v1.5.5
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onLogout:String = "onLogout"
		
		
		/**
		 * Dispatched when a message from a Moderator is received.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	message:	(<b>String</b>) the Moderator's message.
		 * @param	sender:		(<b>User</b>) the {@link User} object representing the Moderator.
		 * 
		 * @example	The following example shows how to handle a message coming from a Moderator.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onModeratorMessage, onModeratorMessageHandler)
		 * 			
		 * 			function onModeratorMessageHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Moderator " + evt.params.sender.getName() + " said: " + evt.params.message)
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onAdminMessage
		 * @see		User
		 * @see		SmartFoxClient#sendModeratorMessage
		 * 
		 * @since	SmartFoxServer Pro v1.4.5
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onModeratorMessage:String = "onModMessage"
		
		
		/**
		 * Dispatched when an Actionscript object is received.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	obj:	(<b>Object</b>) the Actionscript object received.
		 * @param	sender:	(<b>User</b>) the {@link User} object representing the user that sent the Actionscript object.
		 * 
		 * @example	The following example shows how to handle an Actionscript object received from a user.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onObjectReceived, onObjectReceivedHandler)
		 * 			
		 * 			function onObjectReceivedHandler(evt:SFSEvent):void
		 * 			{
		 * 				// Assuming another client sent his X and Y positions in two properties called px, py
		 * 				trace("Data received from user: " + evt.params.sender.getName())
		 * 				trace("X = " + evt.params.obj.px + ", Y = " + evt.params.obj.py)
		 * 			}
		 * 			</code>
		 * 
		 * @see		User
		 * @see		SmartFoxClient#sendObject
		 * @see		SmartFoxClient#sendObjectToGroup
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onObjectReceived:String = "onObjectReceived"
		
		
		/**
		 * Dispatched when a private chat message is received.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	message:	(<b>String</b>) the private message received.
		 * @param	sender:		(<b>User</b>) the {@link User} object representing the user that sent the message; this property is undefined if the sender isn't in the same room of the recipient.
		 * @param	roomId:		(<b>int</b>) the id of the room where the sender is.
		 * 
		 * @example	The following example shows how to handle a private message.
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
		 * @see		#onPublicMessage
		 * @see		User
		 * @see		SmartFoxClient#sendPrivateMessage
		 * 
		 * @history	SmartFoxServer Pro v1.5.0 - <i>roomId</i> and <i>userId</i> parameters added.
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onPrivateMessage:String = "onPrivateMessage"
		
		
		/**
		 * Dispatched when a public chat message is received.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	message:	(<b>String</b>) the public message received.
		 * @param	sender:		(<b>User</b>) the {@link User} object representing the user that sent the message.
		 * @param	roomId:		(<b>int</b>) the id of the room where the sender is.
		 * 
		 * @example	The following example shows how to handle a public message.
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
		 * @see		#onPrivateMessage
		 * @see		User
		 * @see		SmartFoxClient#sendPublicMessage
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onPublicMessage:String = "onPublicMessage"
		
		
		/**
		 * Dispatched in response to a {@link SmartFoxClient#getRandomKey} request.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	key:	(<b>String</b>) a unique random key generated by the server.
		 * 
		 * @example	The following example shows how to handle the key received from the server.
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
		 * @see		SmartFoxClient#getRandomKey
		 * 
		 * @version	SmartFoxServer Pro
		 */
		public static const onRandomKey:String = "onRandomKey"
		
		
		/**
		 * Dispatched when a new room is created in the zone where the user is currently logged in.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	room:	(<b>Room</b>) the {@link Room} object representing the room that was created.
		 * 
		 * @example	The following example shows how to handle a new room being created in the zone.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRoomAdded, onRoomAddedHandler)
		 * 			
		 * 			var roomObj:Object = new Object()
		 * 			roomObj.name = "The Entrance"
		 * 			roomObj.maxUsers = 50
		 * 			
		 * 			smartFox.createRoom(roomObj)
		 * 			
		 * 			function onRoomAddedHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Room " + evt.params.room.getName() + " was created")
		 * 				
		 * 				// TODO: update available rooms list in the application interface
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onRoomDeleted
		 * @see		Room
		 * @see		SmartFoxClient#createRoom
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onRoomAdded:String = "onRoomAdded"
		
		
		/**
		 * Dispatched when a room is removed from the zone where the user is currently logged in.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	room:	(<b>Room</b>) the {@link Room} object representing the room that was removed.
		 * 
		 * @example	The following example shows how to handle a new room being removed in the zone.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRoomDeleted, onRoomDeletedHandler)
		 * 			
		 * 			function onRoomDeletedHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("Room " + evt.params.room.getName() + " was removed")
		 * 				
		 * 				// TODO: update available rooms list in the application interface
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onRoomAdded
		 * @see		Room
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onRoomDeleted:String = "onRoomDeleted"
		
		
		/**
		 * Dispatched when a room is left in multi-room mode, in response to a {@link SmartFoxClient#leaveRoom} request.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	roomId:	(<b>int</b>) the id of the room that was left.
		 * 
		 * @example	The following example shows how to handle the "room left" event.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRoomLeft, onRoomLeftHandler)
		 * 			
		 * 			function onRoomLeftHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("You left room " + evt.params.roomId)
		 * 			}
		 * 			</code>
		 * 
		 * @see		SmartFoxClient#leaveRoom
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onRoomLeft:String = "onRoomLeft"
		
		
		/**
		 * Dispatched when the list of rooms available in the current zone is received.
		 * If the default login mechanism provided by SmartFoxServer is used, then this event is dispatched right after a successful login.
		 * This is because the SmartFoxServer API, internally, call the {@link SmartFoxClient#getRoomList} method after a successful login is performed.
		 * If a custom login handler is implemented, the room list must be manually requested to the server by calling the mentioned method.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	roomList:	(<b>Array</b>) a list of {@link Room} objects for the zone logged in by the user.
		 * 
		 * @example	The following example shows how to handle the list of rooms sent by SmartFoxServer.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onRoomListUpdate, onRoomListUpdateHandler)
		 * 			
		 * 			smartFox.login("simpleChat", "jack")
		 * 			
		 * 			function onRoomListUpdateHandler(evt:SFSEvent):void
		 * 			{
		 * 				// Dump the names of the available rooms in the "simpleChat" zone
		 * 				for (var r:String in evt.params.roomList)
		 * 					trace(evt.params.roomList[r].getName())
		 * 			}
		 * 			</code>
		 * 
		 * @see		Room
		 * @see		SmartFoxClient#getRoomList
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onRoomListUpdate:String = "onRoomListUpdate"
		
		
		/**
		 * Dispatched when Room Variables are updated.
		 * A user receives this notification only from the room(s) where he/she is currently logged in. Also, only the variables that changed are transmitted.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	room:			(<b>Room</b>) the {@link Room} object representing the room where the update took place.
		 * @param	changedVars:	(<b>Array</b>) an associative array with the names of the changed variables as keys. The array can also be iterated through numeric indexes (0 to {@code changedVars.length}) to get the names of the variables that changed.
		 * <hr />
		 * <b>NOTE</b>: the {@code changedVars} array contains the names of the changed variables only, not the actual values. To retrieve them the {@link Room#getVariable} / {@link Room#getVariables} methods can be used.
		 * 
		 * @example	The following example shows how to handle an update in Room Variables.
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
		 * @see		Room
		 * @see		SmartFoxClient#setRoomVariables
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onRoomVariablesUpdate:String = "onRoomVariablesUpdate"
		
		
		/**
		 * Dispatched when a response to the {@link SmartFoxClient#roundTripBench} request is received.
		 * The "roundtrip time" represents the number of milliseconds that it takes to a message to go from the client to the server and back to the client.
		 * A good way to measure the network lag is to send continuos requests (every 3 or 5 seconds) and then calculate the average roundtrip time on a fixed number of responses (i.e. the last 10 measurements).
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	elapsed:	(<b>int</b>) the roundtrip time.
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
		 * @see		SmartFoxClient#roundTripBench
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onRoundTripResponse:String = "onRoundTripResponse"
		
		
		/**
		 * Dispatched in response to the {@link SmartFoxClient#switchSpectator} request.
		 * The request to turn a spectator into a player may fail if another user did the same before your request, and there was only one player slot available.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	success:	(<b>Boolean</b>) the switch result: {@code true} if the spectator was turned into a player, otherwise {@code false}.
		 * @param	newId:		(<b>int</b>) the player id assigned by the server to the user.
		 * @param	room:		(<b>Room</b>) the {@link Room} object representing the room where the switch occurred.
		 * 
		 * @example	The following example shows how to check the handle the spectator switch.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onSpectatorSwitched, onSpectatorSwitchedHandler)
		 * 			
		 * 			smartFox.switchSpectator()
		 * 			
		 * 			function onSpectatorSwitchedHandler(evt:SFSEvent):void
		 * 			{
		 * 				if (evt.params.success)
		 * 					trace("You have been turned into a player; your id is " + evt.params.newId)
		 * 				else
		 * 					trace("The attempt to switch from spectator to player failed")
		 * 			}
		 * 			</code>
		 * 
		 * @see		User#getPlayerId
		 * @see		Room
		 * @see		SmartFoxClient#switchSpectator
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onSpectatorSwitched:String = "onSpectatorSwitched"
		
		/**
		 * Dispatched in response to the {@link SmartFoxClient#switchPlayer} request.
		 * The request to turn a player into a spectator may fail if another user did the same before your request, and there was only one spectator slot available.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	success:	(<b>Boolean</b>) the switch result: {@code true} if the player was turned into a spectator, otherwise {@code false}.
		 * @param	newId:		(<b>int</b>) the player id assigned by the server to the user.
		 * @param	room:		(<b>Room</b>) the {@link Room} object representing the room where the switch occurred.
		 * 
		 * @example	The following example shows how to handle the spectator switch.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onPlayerSwitched, onPlayerSwitchedHandler)
		 * 			
		 * 			smartFox.switchPlayer()
		 * 			
		 * 			function onPlayerSwitchedHandler(evt:SFSEvent):void
		 * 			{
		 * 				if (evt.params.success)
		 * 					trace("You have been turned into a spectator; your id is " + evt.params.newId)
		 * 				else
		 * 					trace("The attempt to switch from player to spectator failed!")
		 * 			}
		 * 			</code>
		 * 
		 * @see		User#getPlayerId
		 * @see		Room
		 * @see		SmartFoxClient#switchPlayer
		 * 
		 * @version	SmartFoxServer Pro
		 */
		public static const onPlayerSwitched:String = "onPlayerSwitched"
		
		/**
		 * Dispatched when the number of users and/or spectators changes in a room within the current zone.
		 * This event allows to keep track in realtime of the status of all the zone rooms in terms of users and spectators.
		 * In case many rooms are used and the zone handles a medium to high traffic, this notification can be turned off to reduce bandwidth consumption, since a message is broadcasted to all users in the zone each time a user enters or exits a room.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	room:	(<b>Room</b>) the {@link Room} object representing the room where the change occurred.
		 * 
		 * @example	The following example shows how to check the handle the spectator switch notification.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onUserCountChange, onUserCountChangeHandler)
		 * 			
		 * 			function onUserCountChangeHandler(evt:SFSEvent):void
		 * 			{
		 * 				// Assuming this is a game room
		 * 				
		 * 				var roomName:String = evt.params.room.getName()
		 * 				var playersNum:int = evt.params.room.getUserCount()
		 * 				var spectatorsNum:int = evt.params.room.getSpectatorCount()
		 * 				
		 * 				trace("Room " + roomName + "has " + playersNum + " players and " + spectatorsNum + " spectators")
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onUserEnterRoom
		 * @see		#onUserLeaveRoom
		 * @see		Room
		 * @see		SmartFoxClient#createRoom
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onUserCountChange:String = "onUserCountChange"
		
		
		/**
		 * Dispatched when another user joins the current room.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	roomId:	(<b>int</b>) the id of the room joined by a user (useful in case multi-room presence is allowed).
		 * @param	user:	(<b>User</b>) the {@link User} object representing the user that joined the room.
		 * 
		 * @example	The following example shows how to check the handle the user entering room notification.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onUserEnterRoom, onUserEnterRoomHandler)
		 * 			
		 * 			function onUserEnterRoomHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("User " + evt.params.user.getName() + " entered the room")
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onUserLeaveRoom
		 * @see		#onUserCountChange
		 * @see		User
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onUserEnterRoom:String = "onUserEnterRoom"
		
		
		/**
		 * Dispatched when a user leaves the current room.
		 * This event is also dispatched when a user gets disconnected from the server.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	roomId:		(<b>int</b>) the id of the room left by a user (useful in case multi-room presence is allowed).
		 * @param	userId:		(<b>int</b>) the id of the user that left the room (or got disconnected).
		 * @param	userName:	(<b>String</b>) the name of the user.
		 * 
		 * @example	The following example shows how to check the handle the user leaving room notification.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onUserLeaveRoom, onUserLeaveRoomHandler)
		 * 			
		 * 			function onUserLeaveRoomHandler(evt:SFSEvent):void
		 * 			{
		 * 				trace("User " + evt.params.userName + " left the room")
		 * 			}
		 * 			</code>
		 * 
		 * @see		#onUserEnterRoom
		 * @see		#onUserCountChange
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onUserLeaveRoom:String = "onUserLeaveRoom"
		
		
		/**
		 * Dispatched when a user in the current room updates his/her User Variables.
		 * 
		 * The {@link #params} object contains the following parameters.
		 * @param	user:			(<b>User</b>) the {@link User} object representing the user who updated his/her variables.
		 * @param	changedVars:	(<b>Array</b>) an associative array with the names of the changed variables as keys. The array can also be iterated through numeric indexes (0 to {@code changedVars.length}) to get the names of the variables that changed.
		 * <hr />
		 * <b>NOTE</b>: the {@code changedVars} array contains the names of the changed variables only, not the actual values. To retrieve them the {@link User#getVariable} / {@link User#getVariables} methods can be used.
		 * 
		 * @example	The following example shows how to handle an update in User Variables.
		 * 			<code>
		 * 			smartFox.addEventListener(SFSEvent.onUserVariablesUpdate, onUserVariablesUpdateHandler)
		 * 			
		 * 			function onUserVariablesUpdateHandler(evt:SFSEvent):void
		 * 			{
		 * 				// We assume that each user has px and py variables representing the users's avatar coordinates in a 2D environment
		 * 				
		 * 				var changedVars:Array = evt.params.changedVars
		 * 				
		 * 				if (changedVars["px"] != null || changedVars["py"] != null)
		 * 				{
		 * 					trace("User " + evt.params.user.getName() + " moved to new coordinates:")
		 * 					trace("\t px: " + evt.params.user.getVariable("px"))
		 * 					trace("\t py: " + evt.params.user.getVariable("py"))
		 * 				}
		 * 			}
		 * 			</code>
		 * 
		 * @see		User
		 * @see		SmartFoxClient#setUserVariables
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public static const onUserVariablesUpdate:String = "onUserVariablesUpdate"
		
		
		//--- END OF CONSTANTS -----------------------------------------------------------------------------
		
		
		/**
		 * An object containing all the parameters related to the dispatched event.
		 * See the class constants for details on the specific parameters contained in this object.
		 */		
		public var params:Object
		
		/**
		 * SFSEvent contructor.
		 * 
		 * @param	type:	the event's type (see the constants in this class).
		 * @param	params:	the parameters object for the event.
		 * 
		 * @see		#params
		 * 
		 * @exclude
		 */
		public function SFSEvent(type:String, params:Object)
		{
			super(type)
			this.params = params
		}
		
		/**
		 * Get a copy of the current instance.
		 * 
		 * @return		a copy of the current instance.
		 * 
		 * @overrides	Event#clone
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public override function clone():Event
		{
			return new SFSEvent(this.type, this.params)
		}
		
		
		/**
		 * Get a string containing all the properties of the current instance.
		 * 
		 * @return		a string representation of the current instance.
		 * 
		 * @overrides	Event#toString
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public override function toString():String
		{
			return formatToString("SFSEvent", "type", "bubbles", "cancelable", "eventPhase", "params")
		}
	}
}