package classes
{
    import flash.events.EventDispatcher;
    import com.flashfla.net.Multiplayer;

    public class Room extends EventDispatcher
    {
        public var id:int
        public var name:String
        public var maxUsers:int
        public var maxSpectators:int
        public var maxPlayers:int
        public var userCount:int
        public var specCount:int
        public var user:User
        public var match:Object

        // Room flags
        public var isJoined:Boolean
        public var isGame:Boolean
        public var isPrivate:Boolean
        public var isTemp:Boolean
        public var isLimbo:Boolean

        // Room game status
        public var level:int
        public var mode:Object
        public var scoreMode:Object
        public var ranked:Object

        public var myPlayerIndex:int

        public var userList:Vector.<User>
        public var players:Vector.<User>

        public var connection:Multiplayer;

        public var variables:Array

        public function Room(id:int, name:String = "", maxUsers:int = 0, maxSpectators:int = 0, isTemp:Boolean = false, isGame:Boolean = false, isPrivate:Boolean = false, isLimbo:Boolean = false, userCount:int = 0, specCount:int = 0)
        {
            this.id = id
            this.name = name
            this.maxSpectators = maxSpectators
            this.maxUsers = maxUsers
            this.isTemp = isTemp
            this.isTemp = isGame
            this.isPrivate = isPrivate
            this.isLimbo = isLimbo
            this.isJoined = false

            this.userCount = userCount
            this.specCount = specCount
            this.userList = new <User>[]
            this.players = new <User>[]
            this.variables = []
        }

        public function addUser(user:User):void
        {
            userList.push(user)

            if (this.isGame && user.isSpec)
                specCount++
            else
                userCount++
        }

        public function removeUser(id:int):void
        {
            var idx:int = 0
            var found:Boolean = false
            for each (var user:User in userList)
            {
                if (user.id == id)
                {
                    found = true
                    break
                }
                idx++
            }

            if (found)
            {
                delete userList[idx]

                if (this.isGame && user.isSpec)
                    specCount--
                else
                    userCount--
            }
        }

        /**
         * Retrieve a user currently in the room.
         *
         * @param 	userId:	the user name ({@code String}) or the id ({@code int}) of the user to retrieve.
         *
         * @return	A {@link User} object.
         */
        public function getUser(userId:int):User
        {
            var idx:int = 0
            var found:Boolean = false
            for each (var user:User in userList)
            {
                if (user.id == id)
                {
                    found = true
                    break
                }
                idx++
            }

            if (found)
            {
                return userList[idx]
            }

            return null
        }

        public function clearUserList():void
        {
            this.userList = new <User>[]
            this.userCount = 0
            this.specCount = 0
        }

        public function getVariable(varName:String):Vector.<Object>
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
         */
        public function getVariables():Array
        {
            return variables
        }

        public function setVariables(vars:Array):void
        {
            this.variables = vars
        }

        public function clearVariables():void
        {
            this.variables = []
        }
    }
}
