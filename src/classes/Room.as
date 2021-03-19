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
        public var connection:Multiplayer;

        /**
         * An associative array containing Room Variables' values, where the key is the variable name.
         *
         * @example
         * ```
         * var roomVars:Array = room.variables
         * for (var v:String in roomVars)
         *      trace("Name:" + v + " | Value:" + roomVars[v])
         * 	```
         */
        public var variables:Object

        /**
         * Maps indexes to players.
         * For example:
         * ```
         * _players[2] = someUser;
         * var secondPlayer:User = _players[2];
         * ```
         */
        private var _players:Object

        private var _playerCount:int

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

            this.variables = []

            this._players = {}
            this._playerCount = 0
        }

        public function addPlayer(user:User):void
        {
            _players[_playerCount + 1] = user
            _playerCount++
        }

        public function setPlayer(index:int, user:User):void
        {
            if (!_players[index])
            {
                _players[index] = user
                _playerCount++
            }
        }

        public function getPlayer(index:int):User
        {
            return _players[index]
        }

        public function getPlayerIndex(user:User):int
        {
            for (var idx:int in _players)
                if (_players[idx] == user)
                    return idx

            return -1
        }

        public function isPlayer(user:User):Boolean
        {
            return getPlayerIndex(user) >= 0
        }

        public function removePlayer(index:int):void
        {
            if (getPlayer(index))
            {
                delete _players[index]
                _playerCount--
            }
        }

        public function get playerCount():int
        {
            return _playerCount
        }

        public function get players():Vector.<User>
        {
            var playerVec:Vector.<User> = new Vector.<User>(true, _playerCount)

            for (var idx:int in _players)
                playerVec.push(_players[idx])

            return playerVec
        }

        public function addUser(user:User):void
        {
            userList.push(user)

            if (this.isGame && user.isSpec)
                specCount++
            else
                userCount++
        }

        public function removeUser(userId:int):void
        {
            var idx:int = -1
            for (var index:int in userList)
            {
                var _user:User = userList[index]
                if (_user.id == userId)
                {
                    idx = index
                    break
                }
            }

            if (idx >= 0)
            {
                userList.removeAt(idx)

                if (this.isGame)
                    specCount--
                else
                    userCount--
            }
        }

        public function getUser(userId:int):User
        {
            for each (var _user:User in userList)
            {
                if (_user.id == userId)
                    return _user
            }

            return null
        }

        public function clearUserList():void
        {
            this.userList = new <User>[]
            this.userCount = 0
            this.specCount = 0
        }
    }
}
