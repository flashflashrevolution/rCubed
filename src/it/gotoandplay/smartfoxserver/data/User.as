package it.gotoandplay.smartfoxserver.data
{
	/**
	 * The User class stores the properties of each user.
	 * This class is used internally by the {@link SmartFoxClient} class; also, User objects are returned by various methods and events of the SmartFoxServer API.
	 * 
	 * <b>NOTE</b>: in the provided examples, {@code user} always indicates a User instance.
	 * 
	 * @version	1.0.0
	 * 
	 * @author	The gotoAndPlay() Team
	 * 			{@link http://www.smartfoxserver.com}
	 * 			{@link http://www.gotoandplay.it}
	 */
	public class User
	{
		private var id:int
		private var name:String
		private var variables:Array
		private var isSpec:Boolean
		private var isMod:Boolean
		private var pId:int
		
		/**
		 * User contructor.
		 * 
		 * @param	id:		the user id.
		 * @param	name:	the user name.
		 * 
		 * @exclude
		 */		
		public function User(id:int, name:String)
		{
			this.id = id
			this.name = name
			this.variables = []
			this.isSpec = false
			this.isMod = false
		}
		
		/**
		 * Get the id of the user.
		 * 
		 * @return	The user id.
		 * 
		 * @example	<code>
		 * 			trace("User id:" + user.getId())
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
		 * Get the name of the user.
		 * 
		 * @return	The user name.
		 * 
		 * @example	<code>
		 * 			trace("User name:" + user.getName())
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
		 * Retrieve a User Variable.
		 * 
		 * @param	varName:	the name of the variable to retrieve.
		 * 
		 * @return	The User Variable's value.
		 * 
		 * @example	<code>
		 * 			var age:int = room.getVariable("age") as int
		 * 			</code>
		 * 
		 * @see		#getVariables
		 * @see		SmartFoxClient#setUserVariables
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getVariable(varName:String):*
		{
			return this.variables[varName]
		}
		
		/**
		 * Retrieve the list of all User Variables.
		 * 
		 * @return	An associative array containing User Variables' values, where the key is the variable name.
		 * 
		 * @example	<code>
		 * 			var userVars:Array = user.getVariables()
		 * 			
		 * 			for (var v:String in userVars)
		 * 				trace("Name:" + v + " | Value:" + userVars[v])
		 * 			</code>
		 * 
		 * @see		#getVariable
		 * @see		SmartFoxClient#setUserVariables
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */
		public function getVariables():Array
		{
			return this.variables
		}
		
		/**
		 * Set the User Variabless.
		 * 
		 * @param	o:	an object containing variables' key-value pairs.
		 * 
		 * @exclude
		 */
		public function setVariables(o:Object):void
		{
			/*
			* TODO: only string, number (int, uint) and boolean should be allowed
			*/
			for (var key:String in o)
			{
				var v:* = o[key] 
				if (v != null)
					this.variables[key] = v
				
				else
					delete this.variables[key]
			} 
		}
		
		/**
		 * Reset User Variabless.
		 * 
		 * @exclude
		 */	
		public function clearVariables():void
		{
			this.variables = []
		}
		
		/**
		 * Set the {@link #isSpectator} property.
		 * 
		 * @param	b:	{@code true} if the user is a spectator.
		 * 
		 * @exclude
		 */
		public function setIsSpectator(b:Boolean):void
		{
			this.isSpec = b
		}
		
		/**
		 * A boolean flag indicating if the user is a spectator in the current room.
		 * 
		 * @return	{@code true} if the user is a spectator.
		 * 
		 * @example	<code>
		 * 			if (user.isSpectator)
		 * 				trace("The user is a spectator")
		 * 			</code>
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */	
		public function isSpectator():Boolean
		{
			return this.isSpec
		}
		
		/**
		 * Set the {@link #isModerator} property.
		 * 
		 * @param	b:	{@code true} if the user is a Moderator.
		 * 
		 * @exclude
		 */	
		public function setModerator(b:Boolean):void
		{
			this.isMod = b
		}
		
		/**
		 * A boolean flag indicating if the user is a Moderator in the current zone.
		 * 
		 * @return	{@code true} if the user is a Moderator.
		 * 
		 * @example	<code>
		 * 			if (user.isModerator)
		 * 				trace("The user is a Moderator")
		 * 			</code>
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */	
		public function isModerator():Boolean
		{
			return this.isMod
		}
		
		/**
		 * Retrieve the player id of the user.
		 * The user must be a player inside a game room for this method to work properly.
		 * This id is 1-based (player 1, player 2, etc.), but if the user is a spectator its value is -1.
		 * 
		 * @return	The current player id.
		 * 
		 * @example	<code>
		 * 			trace("The user's player id is " + user.getPlayerId())
		 * 			</code>
		 * 
		 * @version	SmartFoxServer Basic / Pro
		 */	
		public function getPlayerId():int
		{
			return this.pId
		}
		
		/**
		 * Set the playerId property.
		 * 
		 * @param	pid:	the playerId value.
		 * 
		 * @exclude
		 */
		public function setPlayerId(pid:int):void
		{
			this.pId = pid
		}
	}
}