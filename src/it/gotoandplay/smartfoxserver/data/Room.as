package it.gotoandplay.smartfoxserver.data
{
	import it.gotoandplay.smartfoxserver.data.*
	
	/**
	 * The Room class stores the properties of each server room.
	 * This class is used internally by the {@link SmartFoxClient} class; also, Room objects are returned by various methods and events of the SmartFoxServer API.
	 * 
	 * <b>NOTE</b>: in the provided examples, {@code room} always indicates a Room instance.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 */
	public class Room
	{
		private var id:int
		private var name:String
		private var maxUsers:int
		private var maxSpectators:int
		private var temp:Boolean
		private var game:Boolean
		private var priv:Boolean
		private var limbo:Boolean
		private var userCount:int
		private var specCount:int
		
		private var myPlayerIndex:int
		
		private var userList:Array
		private var variables:Array
		
		/**
		 * Room contructor.
		 * 
		 * @param	id:				the room id.
		 * @param	name:			the room name.
		 * @param	maxUsers:		the maximum number of users that can join the room simultaneously.
		 * @param	maxSpectators:	the maximum number of spectators in the room (for game rooms only).
		 * @param	isTemp:			{@code true} if the room is temporary.
		 * @param	isGame:			{@code true} if the room is a "game room".
		 * @param	isPrivate:		{@code true} if the room is private (password protected).
		 * @param	isLimbo:		{@code true} if the room is a "limbo room".
		 * @param	userCount
		 * @param	specCount
		 * 
		 * @exclude
		 */
		public function Room(id:int, name:String, maxUsers:int, maxSpectators:int, isTemp:Boolean, isGame:Boolean, isPrivate:Boolean, isLimbo:Boolean, userCount:int = 0, specCount:int = 0)
		{
			this.id = id
			this.name = name
			this.maxSpectators = maxSpectators
			this.maxUsers = maxUsers
			this.temp = isTemp
			this.game = isGame
			this.priv = isPrivate
			this.limbo = isLimbo
			
			this.userCount = userCount
			this.specCount = specCount
			this.userList = []
			this.variables = []		
		}
		
		/**
		 * Add a user to the room.
		 * 
		 * @param	u:	the {@link User} object.
		 * @param	id:	the user id.
		 * 
		 * @exclude
		 */
		public function addUser(u:User, id:int):void
		{
			userList[id] = u
			
			if (this.game && u.isSpectator())
				specCount++
			else
				userCount++
		}
		
		/**
		 * Remove a user from the room.
		 * 
		 * @param	id:	the user id.
		 * 
		 * @exclude
		 */
		public function removeUser(id:int):void
		{
			var u:User = userList[id]
			
			if (this.game && u.isSpectator())
				specCount--
			else
				userCount--
			
			delete userList[id]
		}
		
		/**
		 * Get the list of users currently inside the room.
		 * As the returned list is an associative array with user id(s) as keys, in order to iterate it a <i>for-in</i> loop or a <i>for-each</i> loop should be used.
		 * 
		 * @return	A list of {@link User} objects.
		 * 
		 * @example	<code>
		 * 			var users:Array = room.getUserList()
		 * 			
		 * 			for (var u:String in users)
	 	 *				trace(users[u].getName())
		 * 			</code>
		 * 
		 * @see		#getUser
		 * @see		User
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getUserList():Array
		{
			return this.userList
		}
		
		/**
		 * Retrieve a user currently in the room.
		 * 
		 * @param 	userId:	the user name ({@code String}) or the id ({@code int}) of the user to retrieve.
		 * 
		 * @return	A {@link User} object.
		 * 
		 * @example	<code>
		 * 			var user:User = room.getUser("jack")
		 * 			</code>
		 * 
		 * @see		#getUserList
		 * @see		User
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */ 
		public function getUser(userId:*):User
		{
			var user:User = null
			
			if (typeof userId == "number")
			{
				user =  userList[userId]
			}
			
			else if (typeof userId == "string")
			{
				for (var i:String in userList)
				{
					var u:User = this.userList[i]
		
					if (u.getName() == userId)
					{
						user = u
						break
					}
				}
			}
			
			return user
		}
		
		/**
		 * Reset users list.
		 * 
		 * @exclude
		 */
		public function clearUserList():void
		{
			this.userList = []
			this.userCount = 0
			this.specCount = 0
		}
		
		/**
		 * Retrieve a Room Variable.
		 * 
		 * @param	varName:	the name of the variable to retrieve.
		 * 
		 * @return	The Room Variable's value.
		 * 
		 * @example	<code>
		 * 			var location:String = room.getVariable("location") as String
		 * 			</code>
		 * 
		 * @see		#getVariables
		 * @see		SmartFoxClient#setRoomVariables
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getVariable(varName:String):*
		{
			return variables[varName]
		}
		
		/**
		 * Retrieve the list of all Room Variables.
		 * 
		 * @return	An associative array containing Room Variables' values, where the key is the variable name.
		 * 
		 * @example	<code>
		 * 			var roomVars:Array = room.getVariables()
		 * 			
		 * 			for (var v:String in roomVars)
		 * 				trace("Name:" + v + " | Value:" + roomVars[v])
		 * 			</code>
		 * 
		 * @see		#getVariable
		 * @see		SmartFoxClient#setRoomVariables
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getVariables():Array
		{
			return variables
		}
		
		/**
		 * Set the Room Variables.
		 * 
		 * @param	vars:	an array of Room Variables.
		 * 
		 * @exclude
		 */
		public function setVariables(vars:Array):void
		{
			this.variables = vars
		}
		
		/**
		 * Reset Room Variables.
		 * 
		 * @exclude
		 */
		public function clearVariables():void
		{
			this.variables = []
		}
		
		/**
		 * Get the name of the room.
		 * 
		 * @return	The name of the room.
		 * 
		 * @example	<code>
		 * 			trace("Room name:" + room.getName())
		 * 			</code>
		 * 
		 * @see		#getId
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getName():String
		{
			return this.name
		}
		
		/**
		 * Get the id of the room.
		 * 
		 * @return	The id of the room.
		 * 
		 * @example	<code>
		 * 			trace("Room id:" + room.getId())
		 * 			</code>
		 * 
		 * @see		#getName
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getId():int
		{
			return this.id
		}
		
		/**
		 * A boolean flag indicating if the room is dynamic/temporary.
		 * This is always true for rooms created at runtime on client-side.
		 * 
		 * @return	{@code true} if the room is a dynamic/temporary room.
		 * 
		 * @example	<code>
		 * 			if (room.isTemp)
		 * 				trace("Room is temporary")
		 * 			</code>
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function isTemp():Boolean
		{
			return this.temp
		}
		
		/**
		 * A boolean flag indicating if the room is a "game room".
		 * 
		 * @return	{@code true} if the room is a "game room".
		 * 
		 * @example	<code>
		 * 			if (room.isGame)
		 * 				trace("This is a game room")
		 * 			</code>
		 * 
		 * @see		#isLimbo
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function isGame():Boolean
		{
			return this.game
		}
		
		/**
		 * A boolean flag indicating if the room is private (password protected).
		 * 
		 * @return	{@code true} if the room is private.
		 * 
		 * @example	<code>
		 * 			if (room.isPrivate)
		 * 				trace("Password required for this room")
		 * 			</code>
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function isPrivate():Boolean
		{
			return this.priv
		}
		
		/**
		 * Retrieve the number of users currently inside the room.
		 * 
		 * @return	The number of users in the room.
		 * 
		 * @example	<code>
		 * 			var usersNum:int = room.getUserCount()
		 * 			trace("There are " + usersNum + " users in the room")
		 * 			</code>
		 * 
		 * @see		#getSpectatorCount
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getUserCount():int
		{
			return this.userCount
		}
		
		/**
		 * Retrieve the number of spectators currently inside the room.
		 * 
		 * @return	The number of spectators in the room.
		 * 
		 * @example	<code>
		 * 			var specsNum:int = room.getSpectatorCount()
		 * 			trace("There are " + specsNum + " spectators in the room")
		 * 			</code>
		 * 
		 * @see		#getUserCount
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getSpectatorCount():int
		{
			return this.specCount
		}
		
		/**
		 * Retrieve the maximum number of users that can join the room.
		 * 
		 * @return	The maximum number of users that can join the room.
		 * 
		 * @example	<code>
		 * 			trace("Max users allowed to join the room: " + room.getMaxUsers())
		 * 			</code>
		 * 
		 * @see		#getMaxSpectators
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getMaxUsers():int
		{
			return this.maxUsers
		}
		
		/**
		 * Retrieve the maximum number of spectators that can join the room.
		 * Spectators can exist in game rooms only.
		 * 
		 * @return	The maximum number of spectators that can join the room.
		 * 
		 * @example	<code>
		 * 			if (room.isGame)
		 * 				trace("Max spectators allowed to join the room: " + room.getMaxSpectators())
		 * 			</code>
		 * 
		 * @see		#getMaxUsers
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getMaxSpectators():int
		{
			return this.maxSpectators
		}
		
		
		/**
		 * Set the myPlayerId property.
		 * Each room where the current client is connected contains a myPlayerId (if the room is a gameRoom).
		 * myPlayerId == -1 ... user is a spectator
		 * myPlayerId  > 0  ...	user is a player
		 * 
		 * @param	id:	the myPlayerId value.
		 * 
		 * @exclude
		 */
		public function setMyPlayerIndex(id:int):void
		{
			this.myPlayerIndex = id
		}
		
		/**
		 * Retrieve the player id for the current user in the room.
		 * This id is 1-based (player 1, player 2, etc.), but if the user is a spectator its value is -1.
		 * 
		 * @return	The player id for the current user.
		 * 
		 * @example	<code>
		 * 			if (room.isGame)
		 * 				trace("My player id in this room: " + room.getMyPlayerIndex())
		 * 			</code>
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getMyPlayerIndex():int
		{
			return this.myPlayerIndex
		}
		
		/**
		 * Set the {@link #isLimbo} property.
		 * 
		 * @param	b:	{@code true} if the room is a "limbo room".
		 * 
		 * @exclude
		 */
		public function setIsLimbo(b:Boolean):void
		{
			this.limbo = b
		}
		
		/**
		 * A boolean flag indicating if the room is in "limbo mode".
		 * 
		 * @return	{@code true} if the room is in "limbo mode".
		 * 
		 * @example	<code>
		 * 			if (room.isLimbo)
		 * 				trace("This is a limbo room")
		 * 			</code>
		 * 
		 * @see		#isGame
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function isLimbo():Boolean
		{
			return this.limbo
		}
		
		/**
		 * Se the number of users in the room.
		 * 
		 * @param	n:	the number of users.
		 * 
		 * @exclude
		 */
		public function setUserCount(n:int):void
		{
			this.userCount = n
		}
		
		/**
		 * Se the number of spectators in the room.
		 * 
		 * @param	n:	the number of spectators.
		 * 
		 * @exclude
		 */
		public function setSpectatorCount(n:int):void
		{
			this.specCount = n
		}
	}
}