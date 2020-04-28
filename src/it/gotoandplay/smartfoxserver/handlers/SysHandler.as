package it.gotoandplay.smartfoxserver.handlers
{
	import it.gotoandplay.smartfoxserver.SmartFoxClient;
	import it.gotoandplay.smartfoxserver.SFSEvent;
	import it.gotoandplay.smartfoxserver.data.Room;
	import it.gotoandplay.smartfoxserver.data.User;
	import it.gotoandplay.smartfoxserver.util.Entities;
	import it.gotoandplay.smartfoxserver.util.ObjectSerializer;
	import flash.utils.getTimer;
	
	/**
	 * SysHandler class: handles "sys" type messages.
	 *
	 * @version	1.3.0
	 *
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 *
	 * @exclude
	 */
	public class SysHandler implements IMessageHandler
	{
		private var sfs:SmartFoxClient
		private var handlersTable:Array
		
		function SysHandler(sfs:SmartFoxClient)
		{
			this.sfs = sfs
			handlersTable = []
			
			handlersTable["apiOK"] 			= this.handleApiOK
			handlersTable["apiKO"] 			= this.handleApiKO
			handlersTable["logOK"] 			= this.handleLoginOk
			handlersTable["logKO"] 			= this.handleLoginKo
			handlersTable["logout"]			= this.handleLogout
			handlersTable["rmList"] 		= this.handleRoomList
			handlersTable["uCount"] 		= this.handleUserCountChange
			handlersTable["joinOK"] 		= this.handleJoinOk
			handlersTable["joinKO"] 		= this.handleJoinKo
			handlersTable["uER"] 			= this.handleUserEnterRoom
			handlersTable["userGone"] 		= this.handleUserLeaveRoom
			handlersTable["pubMsg"] 		= this.handlePublicMessage
			handlersTable["prvMsg"] 		= this.handlePrivateMessage
			handlersTable["dmnMsg"] 		= this.handleAdminMessage
			handlersTable["modMsg"] 		= this.handleModMessage
			handlersTable["dataObj"] 		= this.handleASObject
			handlersTable["rVarsUpdate"] 	= this.handleRoomVarsUpdate
			handlersTable["roomAdd"]		= this.handleRoomAdded
			handlersTable["roomDel"]		= this.handleRoomDeleted
			handlersTable["rndK"]			= this.handleRandomKey
			handlersTable["roundTripRes"]	= this.handleRoundTripBench
			handlersTable["uVarsUpdate"]	= this.handleUserVarsUpdate
			handlersTable["createRmKO"]		= this.handleCreateRoomError
			handlersTable["bList"]			= this.handleBuddyList
			handlersTable["bUpd"]			= this.handleBuddyListUpdate
			handlersTable["bAdd"]			= this.handleBuddyAdded
			handlersTable["roomB"]			= this.handleBuddyRoom
			handlersTable["leaveRoom"]		= this.handleLeaveRoom
			handlersTable["swSpec"]			= this.handleSpectatorSwitched
			handlersTable["bPrm"]			= this.handleAddBuddyPermission
			handlersTable["remB"]			= this.handleRemoveBuddy
			handlersTable["swPl"]			= this.handlePlayerSwitched
		}
		
		/**
		 * Handle messages
		 */
		public function handleMessage(msgObj:Object, type:String):void
		{
			var xmlData:XML = msgObj as XML
			var action:String = xmlData.body.@action
			
			// Get handler table
			var fn:Function = handlersTable[action]
			
			if (fn != null)
			{
				fn.apply(this, [msgObj])
			}
			
			else
			{
				trace("Unknown sys command: " + action)
			}
		}
		
		
		// Handle correct API
		public function handleApiOK(o:Object):void
		{
			sfs.isConnected = true
			var evt:SFSEvent = new SFSEvent(SFSEvent.onConnection, {success:true})
			sfs.dispatchEvent(evt)
		}
		
		
		// Handle obsolete API
		public function handleApiKO(o:Object):void
		{
			var params:Object = {}
			params.success = false
			params.error = "API are obsolete, please upgrade"
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onConnection, params)
			sfs.dispatchEvent(evt)
		}
		
		
		// Handle successfull login
		public function handleLoginOk(o:Object):void
		{
			var uid:int = int(o.body.login.@id)
			var mod:int = int(o.body.login.@mod)
			var name:String = o.body.login.@n
			
			sfs.amIModerator = (mod == 1)
			sfs.myUserId = uid
			sfs.myUserName = name
			sfs.playerId = -1
			
			var params:Object = {}
			params.success = true
			params.name = name
			params.error = ""
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onLogin, params)
			sfs.dispatchEvent(evt)
			
			// Request room list
			sfs.getRoomList()
		}
		
		// Handle successfull login
		public function handleLoginKo(o:Object):void
		{
			var params:Object = {}
			params.success = false
			params.error = o.body.login.@e
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onLogin, params)
			sfs.dispatchEvent(evt)
		}
		
		// Handle successful logout
		public function handleLogout(o:Object):void
		{
			sfs.__logout()
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onLogout, {})
			sfs.dispatchEvent(evt)
		}
		
		// Populate the room list for this zone and fire the event
		public function handleRoomList(o:Object):void
		{
			var roomList:Array = sfs.getAllRooms();
			var filling:Boolean = (roomList.length == 0);
			var roomsInList:Array = new Array();
			var room:Room;
			for each (var roomXml:XML in o.body.rmList.rm) {
				var changedVars:Array = new Array();
				var roomId:int = int(roomXml.@id);
				room = (roomList != null ? roomList[roomId] : null);
				var newRoom:Boolean = false;
				var updated:Boolean = false;
				if (room == null) {
					room = new Room(roomId, roomXml.n, int(roomXml.@maxu), int(roomXml.@maxs), (roomXml.@temp == "1"), (roomXml.@game == "1"), (roomXml.@priv == "1"), (roomXml.@lmb == "1"), int(roomXml.@ucnt), int(roomXml.@scnt));
					roomList[roomId] = room;
					newRoom = true;
				} else {
					var uCount:int = int(roomXml.@ucnt);
					var sCount:int = int(roomXml.@scnt);
					updated ||= room.getUserCount() != uCount || room.getSpectatorCount() != sCount;
					room.setUserCount(uCount);
					room.setSpectatorCount(sCount);
				}

				if (roomXml.vars.toString().length > 0)
					populateVariables(room.getVariables(), roomXml, changedVars);
				updated ||= changedVars.length > 0;

				if (!filling) {
					if (newRoom)
						sfs.dispatchEvent(new SFSEvent(SFSEvent.onRoomAdded, {room:room}));
					else if (updated)
						sfs.dispatchEvent(new SFSEvent(SFSEvent.onRoomVariablesUpdate, {room:room, changedVars:changedVars, roomList:true}));
				}
				roomsInList.push(roomId);
			}
			for each (room in roomList) {
				if (roomsInList.indexOf(room.getId()) < 0) {
					delete roomList[room.getId()];
					sfs.dispatchEvent(new SFSEvent(SFSEvent.onRoomDeleted, {room:room}));
				}
			}

			if (filling)
				sfs.dispatchEvent(new SFSEvent(SFSEvent.onRoomListUpdate, {roomList:roomList}));
		}
	
		// Handle the user count change in a room
		public function handleUserCountChange(o:Object):void
		{
			var uCount:int = int(o.body.@u)
			var sCount:int = int(o.body.@s)
			var roomId:int = int(o.body.@r)
			
			var room:Room = sfs.getAllRooms()[roomId]
			
			if (room != null)
			{
				room.setUserCount(uCount)
				room.setSpectatorCount(sCount)
				
				var params:Object = {}
				params.room = room
				
				var evt:SFSEvent = new SFSEvent(SFSEvent.onUserCountChange, params)
				sfs.dispatchEvent(evt)
			}
		}
		
		
		// Successfull room Join
		public function handleJoinOk(o:Object):void
		{
			
			var roomId:int 			= int(o.body.@r)
			var roomVarsXml:XMLList	= o.body
			var userListXml:XMLList = o.body.uLs.u
			var playerId:int		= int(o.body.pid.@id)
			
			// Set current active room
		 	sfs.activeRoomId = roomId
	
			// get current Room and populates usrList
			var currRoom:Room = sfs.getRoom(roomId)
			
			// Clear the old data, we need to start from a clean list
			currRoom.clearUserList()
			
			// Set the player ID
			// -1 = no game room
			sfs.playerId = playerId
			
			// Also set the myPlayerId in the room
			// for multi-room applications
			currRoom.setMyPlayerIndex(playerId)
			
			// Handle Room Variables
			if (roomVarsXml.vars.toString().length > 0)
			{
				currRoom.clearVariables()
				populateVariables(currRoom.getVariables(), roomVarsXml)
			}

			// Populate Room userList
			for each (var usr:XML in userListXml)
			{
				// grab the user properties
				var name:String 	= usr.n
				var id:int   		= int(usr.@i)
				var isMod:Boolean 	= usr.@m == "1" ? true : false
				var isSpec:Boolean 	= usr.@s == "1" ? true : false
				var pId:int			= usr.@p == null ? -1 : int(usr.@p)
				
				// Create and populate User
				var user:User = new User(id, name)
				user.setModerator(isMod)
				user.setIsSpectator(isSpec)
				user.setPlayerId(pId)
				
				// Handle user variables
				if (usr.vars.toString().length > 0)
				{
					populateVariables(user.getVariables(), usr)
				}
				
				// Add user
				currRoom.addUser(user, id)
			}
			
			// operation completed, release lock
			sfs.changingRoom = false
	
			// Fire event!
			var params:Object = {}
			params.room = currRoom
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onJoinRoom, params)
			sfs.dispatchEvent(evt)
		}
		
		// Failed room Join
		public function handleJoinKo(o:Object):void
		{
			sfs.changingRoom = false
			
			var params:Object = {}
			params.error = o.body.error.@msg
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onJoinRoomError, params)
			sfs.dispatchEvent(evt)
		}
		
		// New user enters the room
		public function handleUserEnterRoom(o:Object):void
		{
			var roomId:int 			= int(o.body.@r)
			
			// Get params
			var usrId:int 			= int(o.body.u.@i)
			var usrName:String 		= o.body.u.n
			var isMod:Boolean 		= (o.body.u.@m == "1")
			var isSpec:Boolean 		= (o.body.u.@s == "1")
			var pid:int 			= o.body.u.@p != null ? int(o.body.u.@p) : -1
			
			var varList:XMLList		= o.body.u.vars["var"]
			
			var currRoom:Room = sfs.getRoom(roomId)
			
			// Create new user object
			var newUser:User = new User(usrId, usrName)
			newUser.setModerator(isMod)
			newUser.setIsSpectator(isSpec)
			newUser.setPlayerId(pid)
			
			// Add user to room
			currRoom.addUser(newUser, usrId)
			
			// Populate user vars
			if (o.body.u.vars.toString().length > 0)
			{
				populateVariables(newUser.getVariables(), o.body.u)
			}
			
			// Fire event!
			var params:Object = {}
			params.roomId = roomId
			params.user = newUser
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onUserEnterRoom, params)
			sfs.dispatchEvent(evt)
		}
		
		// User leaves a room
		public function handleUserLeaveRoom(o:Object):void
		{
			var userId:int = int(o.body.user.@id)
			var roomId:int = int(o.body.@r)
			
			// Get room
			var theRoom:Room = sfs.getRoom(roomId)
			
			// Get user name
			var uName:String = theRoom.getUser(userId).getName()
			
			// Remove user
			theRoom.removeUser(userId)
			
			// Fire event!
			var params:Object = {}
			params.roomId = roomId
			params.userId = userId
			params.userName = uName
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onUserLeaveRoom, params)
			sfs.dispatchEvent(evt)
		}
		
		public function handlePublicMessage(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var userId:int = int(o.body.user.@id)
			var message:String = o.body.txt
			
			var sender:User = sfs.getRoom(roomId).getUser(userId)
			
			// Fire event!
			var params:Object = {}
			params.message = Entities.decodeEntities(message)
			params.sender = sender
			params.roomId = roomId
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onPublicMessage, params)
			sfs.dispatchEvent(evt)
			
		}
		
		public function handlePrivateMessage(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var userId:int = int(o.body.user.@id)
			var message:String = o.body.txt
			
			var sender:User = sfs.getRoom(roomId).getUser(userId)
			
			// Fire event!
			var params:Object = {}
			params.message = Entities.decodeEntities(message)
			params.sender = sender
			params.roomId = roomId
			params.userId = userId
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onPrivateMessage, params)
			sfs.dispatchEvent(evt)
		}
		
		public function handleAdminMessage(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var userId:int = int(o.body.user.@id)
			var message:String = o.body.txt
			
			// Fire event!
			var params:Object = {}
			params.message = Entities.decodeEntities(message)
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onAdminMessage, params)
			sfs.dispatchEvent(evt)
			
		}
		
		public function handleModMessage(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var userId:int = int(o.body.user.@id)
			var message:String = o.body.txt
			
			var sender:User = null;
			var room:Room = sfs.getRoom(roomId)
			
			if (room != null)
				sender = sfs.getRoom(roomId).getUser(userId)
			
			// Fire event!
			var params:Object = {}
			params.message = Entities.decodeEntities(message)
			params.sender = sender
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onModeratorMessage, params)
			sfs.dispatchEvent(evt)
		}
		
		public function handleASObject(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var userId:int = int(o.body.user.@id)
			var xmlStr:String = o.body.dataObj
			
			var sender:User = sfs.getRoom(roomId).getUser(userId)
			var asObj:Object = ObjectSerializer.getInstance().deserialize(new XML(xmlStr))
			
			// Fire event!
			var params:Object = {}
			params.obj = asObj
			params.sender = sender
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onObjectReceived, params)
			sfs.dispatchEvent(evt)
		}
		
		public function handleRoomVarsUpdate(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var userId:int = int(o.body.user.@id)
			
			var currRoom:Room = sfs.getRoom(roomId)
			var changedVars:Array = []
			
			// Handle Room Variables
			if (o.body.vars.toString().length > 0)
			{
				populateVariables(currRoom.getVariables(), o.body, changedVars)
			}
			
			// Fire event!
			var params:Object = {}
			params.room = currRoom
			params.changedVars = changedVars
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onRoomVariablesUpdate, params)
			sfs.dispatchEvent(evt)
		}
		
		/**
		*	OLD
		
		public function handleUserVarsUpdateOld(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var userId:int = int(o.body.user.@id)
			
			var currUser:User = sfs.getRoom(roomId).getUser(userId)
			var changedVars:Array = []
			
			if (o.body.vars.toString().length > 0)
			{
				populateVariables(currUser.getVariables(), o.body, changedVars)
			}
			
			// Fire event!
			var params:Object = {}
			params.user = currUser
			params.changedVars = changedVars
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onUserVariablesUpdate, params)
			sfs.dispatchEvent(evt)
		}
		*/
		
		public function handleUserVarsUpdate(o:Object):void
		{
			var userId:int = int(o.body.user.@id)
			var changedVars:Array
			var varOwner:User = null
			var returnUser:User = null
			
			// First, we check if there's actual variables data available
			if (o.body.vars.toString().length > 0)
			{
				// Search the userId in all available rooms
				for each (var room:Room in sfs.getAllRooms())
				{
					varOwner = room.getUser(userId)
					
					// found a user with the passed userId, populate his variables
					if (varOwner != null)
					{
						if (returnUser == null)
							returnUser = varOwner
							
						changedVars = []
						populateVariables(varOwner.getVariables(), o.body, changedVars)
					}
				}
				
				// Fire event!
				var params:Object = {}
				params.user = returnUser
				params.changedVars = changedVars

				var evt:SFSEvent = new SFSEvent(SFSEvent.onUserVariablesUpdate, params)
				sfs.dispatchEvent(evt)
			}
		}
		
		private function handleRoomAdded(o:Object):void
		{
			var rId:int = int(o.body.rm.@id)
			var rName:String = o.body.rm.name
			var rMax:int = int(o.body.rm.@max)
			var rSpec:int = int(o.body.rm.@spec)
			var isTemp:Boolean = o.body.rm.@temp == "1" ? true : false
			var isGame:Boolean = o.body.rm.@game == "1" ? true : false
			var isPriv:Boolean = o.body.rm.@priv == "1" ? true : false
			var isLimbo:Boolean = o.body.rm.@limbo == "1" ? true : false
			
			// Create room obj
			var newRoom:Room = new Room(rId, rName, rMax, rSpec, isTemp, isGame, isPriv, isLimbo)
			
			var rList:Array = sfs.getAllRooms()
			rList[rId] = newRoom
			
			// Handle Room Variables
			if (o.body.rm.vars.toString().length > 0)
				populateVariables(newRoom.getVariables(), o.body.rm)
			
			// Fire event!
			var params:Object = {}
			params.room = newRoom
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onRoomAdded, params)
			sfs.dispatchEvent(evt)
			
		}
		
		private function handleRoomDeleted(o:Object):void
		{
			var roomId:int = int(o.body.rm.@id)
			
			var roomList:Array = sfs.getAllRooms()
			
			// Pass the last reference to the upper level
			// If there's no other references to this room in the upper level
			// This is the last reference we're keeping
			
			// Fire event!
			var params:Object = {}
			params.room = roomList[roomId]
			
			// Remove reference from main room list
			delete roomList[roomId]

			var evt:SFSEvent = new SFSEvent(SFSEvent.onRoomDeleted, params)
			sfs.dispatchEvent(evt)
		}
		
		
		private function handleRandomKey(o:Object):void
		{
			var key:String = o.body.k.toString()
			
			// Fire event!
			var params:Object = {}
			params.key = key
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onRandomKey, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handleRoundTripBench(o:Object):void
		{
			var now:int = getTimer()
			var res:int = now - sfs.getBenchStartTime()
			
			// Fire event!
			var params:Object = {}
			params.elapsed = res
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onRoundTripResponse, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handleCreateRoomError(o:Object):void
		{
			var errMsg:String = o.body.room.@e
			
			// Fire event!
			var params:Object = {}
			params.error = errMsg
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onCreateRoomError, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handleBuddyList(o:Object):void
		{
			var bList:XMLList = o.body.bList
			var myVars:XMLList = o.body.mv
			var buddy:Object
			var params:Object = {}
			var evt:SFSEvent = null
			
			/*
			* Get my buddy variables
			*/
			if (myVars != null && myVars.toString().length > 0)
			{
				for each (var myVar:XML in myVars.v)
					sfs.myBuddyVars[myVar.@n.toString()] = myVar.toString()
			}
			
			if (bList != null && bList.b.length != null)
			{

				if (bList.toString().length > 0)
				{
					for each (var b:XML in bList.b)
					{
						buddy = {}
						buddy.isOnline = b.@s == "1" ? true : false
						buddy.name = b.n.toString()
						buddy.id = b.@i
						buddy.isBlocked = b.@x == "1" ? true : false
						buddy.variables = {}
						
						
						// Runs through buddy variables
						var bVars:XMLList = b.vs
						
						if (bVars.toString().length > 0)
						{
							for each (var bVar:XML in bVars.v)
							{
								buddy.variables[bVar.@n.toString()] = bVar.toString()
							}
						}
						
						sfs.buddyList.push(buddy)
					}
				}
				
				// Fire event!
				params.list = sfs.buddyList
				evt = new SFSEvent(SFSEvent.onBuddyList, params)
				sfs.dispatchEvent(evt)
			}
			
			// Buddy List load error!
			else
			{
				// Fire event!
				params.error = o.body.err.toString()
				evt = new SFSEvent(SFSEvent.onBuddyListError, params)
				sfs.dispatchEvent(evt)
			}
		}
		
		
		private function handleBuddyListUpdate(o:Object):void
		{
			var params:Object = {}
			var evt:SFSEvent = null
			
			// Catch Buddy List load error!
			if (o.body.err.toString().length > 0)
			{
				// Fire event!
				params.error = o.body.err.toString()
				evt = new SFSEvent(SFSEvent.onBuddyListError, params)
				sfs.dispatchEvent(evt)
				
				// Stop here
				return
			}
			
			if (o.body.b != null)
			{
				var buddy:Object = {}
				buddy.isOnline = o.body.b.@s == "1" ? true : false
				buddy.name = o.body.b.n.toString()
				buddy.id = o.body.b.@i
				buddy.isBlocked = o.body.b.@x == "1" ? true : false

				// Runs through buddy variables
				var bVars:XMLList = o.body.b.vs
				
				var tempB:Object = null
				var found:Boolean = false
				
				for (var it:String in sfs.buddyList)
				{
					tempB = sfs.buddyList[it]
					
					if (tempB.name == buddy.name)
					{
						// swap objects
						sfs.buddyList[it] = buddy
						buddy.isBlocked = tempB.isBlocked
						buddy.variables = tempB.variables
						
						// add/modify variables
						if (bVars.toString().length > 0)
						{
							for each (var bVar:XML in bVars.v)
							{
								buddy.variables[bVar.@n.toString()] = bVar.toString()
							}
						}
						
						found = true
						break
					}
				}

				// Fire event!
				if ( found )
				{
					params.buddy = buddy
					
					evt = new SFSEvent(SFSEvent.onBuddyListUpdate, params)
					sfs.dispatchEvent(evt)
				}
			}
		}
		
		private function handleAddBuddyPermission(o:Object):void
		{
			// Fire event!
			var params:Object = {}
			params.sender = o.body.n.toString()
			params.message = ""
			
			if (o.body.txt != undefined)
				params.message = Entities.decodeEntities(o.body.txt)
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onBuddyPermissionRequest, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handleBuddyAdded(o:Object):void
		{
			var buddy:Object = {}
			buddy.isOnline = o.body.b.@s == "1" ? true : false
			buddy.name = o.body.b.n.toString()
			buddy.id = o.body.b.@i
			buddy.isBlocked = o.body.b.@x == "1" ? true : false
			buddy.variables = {}

			// Runs through buddy variables
			var bVars:XMLList = o.body.b.vs
			
			if (bVars.toString().length > 0)
			{
				for each (var bVar:XML in bVars.v)
				{
					buddy.variables[bVar.@n.toString()] = bVar.toString()
				}
			}
			
			sfs.buddyList.push(buddy)

			// Fire event!
			var params:Object = {}
			params.list = sfs.buddyList
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onBuddyList, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handleRemoveBuddy(o:Object):void
		{
			var buddyName:String = o.body.n.toString()
			
			var buddy:Object = null
				
			for (var it:String in sfs.buddyList)
			{
				buddy = sfs.buddyList[it]
				
				if (buddy.name == buddyName)
				{
					delete sfs.buddyList[it]
					
					// Fire event!
					var params:Object = {}
					params.list = sfs.buddyList
					
					var evt:SFSEvent = new SFSEvent(SFSEvent.onBuddyList, params)
					sfs.dispatchEvent(evt)
					
					break
				}
			}
			
		}
		
		private function handleBuddyRoom(o:Object):void
		{
			var roomIds:String = o.body.br.@r
			var ids:Array = roomIds.split(",")
			
			for (var i:int = 0; i < ids.length; i++)
				ids[i] = int(ids[i])
				
			// Fire event!
			var params:Object = {}
			params.idList = ids
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onBuddyRoom, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handleLeaveRoom(o:Object):void
		{
			var roomLeft:int = int(o.body.rm.@id)
			
			// Fire event!
			var params:Object = {}
			params.roomId = roomLeft

			var room:Room = sfs.getRoom(roomLeft);
			if (room != null)
				room.clearUserList();
			
			var evt:SFSEvent = new SFSEvent(SFSEvent.onRoomLeft, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handleSpectatorSwitched(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var playerId:int = int(o.body.pid.@id)
			
			// Synch user count, if switch successful
			var theRoom:Room = sfs.getRoom(roomId)
			
			var userId:int;
			if (o.body.pid.@u != undefined)
				userId = int(o.body.pid.@u);
			else {
				userId = sfs.myUserId;
				sfs.playerId = playerId;
				theRoom.setMyPlayerIndex(playerId);
			}

			if (playerId > 0)
			{
				theRoom.setUserCount(theRoom.getUserCount() + 1)
				theRoom.setSpectatorCount(theRoom.getSpectatorCount() - 1)

				var user:User = theRoom.getUser(userId);

				if (user != null) {
					user.setIsSpectator(false);
					user.setPlayerId(playerId);
				}
			}


			// Fire event!
			var params:Object = {}
			params.success = playerId > 0
			params.newId = playerId
			params.room = theRoom
			params.userId = userId;

			var evt:SFSEvent = new SFSEvent(SFSEvent.onSpectatorSwitched, params)
			sfs.dispatchEvent(evt)
		}
		
		private function handlePlayerSwitched(o:Object):void
		{
			var roomId:int = int(o.body.@r)
			var playerId:int = int(o.body.pid.@id)
			var theRoom:Room = sfs.getRoom(roomId)
			var userId:int;
			if (o.body.pid.@u != undefined)
				userId = int(o.body.pid.@u);
			else {
				userId = sfs.myUserId;
				sfs.playerId = playerId;
				theRoom.setMyPlayerIndex(playerId);
			}

			// Success
			if (playerId == -1)
			{
				theRoom.setUserCount(theRoom.getUserCount() - 1)
				theRoom.setSpectatorCount(theRoom.getSpectatorCount() + 1)
				
				var user:User = theRoom.getUser(userId)

				if (user != null) {
					user.setIsSpectator(true);
					user.setPlayerId(playerId);
				}
			}

			sfs.playerId = playerId;

			// Fire event!
			var params:Object = {}
			params.success = (playerId == -1);
			params.newId = playerId;
			params.room = theRoom;
			params.userId = userId;

			var evt:SFSEvent = new SFSEvent(SFSEvent.onPlayerSwitched, params);
			sfs.dispatchEvent(evt);
		}
		
		//=======================================================================
		// Other class methods
		//=======================================================================
		/**
		 * Takes an SFS variables XML node and store it in an array
		 * Usage: for parsing room and user variables
		 *
		 * @xmlData	 	xmlData		the XML variables node
		*/
		private function populateVariables(variables:Array, xmlData:Object, changedVars:Array = null):void
		{
			for each (var v:XML in xmlData.vars["var"])
			{
				var vName:String = v.@n
				var vType:String = v.@t
				var vValue:String = v.toString();
				var value:Object = vValue;

				if (vType == "b")
					value = (vValue == "1" ? true : false);
				else if (vType == "n")
					value = Number(vValue);
				else if (vType == "x")
					value = null;

				if (variables[vName] != value) {
					if (changedVars != null) {
						changedVars.push(vName);
						changedVars[vName] = true;
					}
					if (value == null)
						delete variables[vName];
					else
						variables[vName] = value;
				}
			}
		}
		
			
		public function dispatchDisconnection():void
		{
			var evt:SFSEvent = new SFSEvent(SFSEvent.onConnectionLost, null)
			sfs.dispatchEvent(evt)
		}

		
		/*
		private function populateVariables(xmlData:Object):Array
		{
			var variables:Array = []

			for each (var v:XML in xmlData.vars["var"])
			{
				var vName:String = v.@n
				var vType:String = v.@t
				var vValue:String = v
				
				//trace(vName + " : " + vValue)
				
				if (vType == "b")
					variables[vName] = Boolean(vValue)
							
				else if (vType == "n")
					variables[vName] = Number(vValue)
					
				else if (vType == "s")
					variables[vName] = vValue
					
				else if (vType == "x")
					delete variables[vName]
				
			}
			
			return variables
		}
		*/
	}
}
