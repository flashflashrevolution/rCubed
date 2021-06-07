package classes
{
    import com.flashfla.net.Multiplayer;

    public class Room
    {
        public static const MAX_PLAYERS:int = 2

        public var id:int
        public var name:String
        public var maxUsers:int
        public var maxSpectators:int
        public var maxPlayers:int
        public var userCount:int
        public var specCount:int

        // Room flags
        public var isGameRoom:Boolean
        public var isPrivate:Boolean

        // Room game status
        public var level:int
        public var mode:Object
        public var scoreMode:Object
        public var ranked:Object
        public var songInfo:SongInfo
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
         * Maps indexes to players. This map is 1-based.
         *
         * @example
         * ```
         * _players[2] = someUser;
         * var someUser:User = _players[2];
         * ```
         */
        private var _players:Object

        /**
         * Maps ids to users.
         *
         * @example
         * ```
         * _users[1234224] = someUser;
         * var someUser:User = _users[1234224];
         * ```
         */
        private var _users:Object

        private var _playerCount:int

        public function Room(id:int, name:String = "", maxUsers:int = 0, maxSpectators:int = 0, isGame:Boolean = false, isPrivate:Boolean = false, userCount:int = 0, specCount:int = 0)
        {
            this.id = id
            this.name = name
            this.maxSpectators = maxSpectators
            this.maxUsers = maxUsers
            this.isGameRoom = isGame
            this.isPrivate = isPrivate

            this.userCount = userCount
            this.specCount = specCount

            this.variables = []

            this._users = {}
            this._players = {}
            this._playerCount = 0
        }

        public function addPlayer(user:User):int
        {
            if (_playerCount == MAX_PLAYERS)
                return -1

            var idx:int = 1
            while (idx <= MAX_PLAYERS)
            {
                if (!_players[idx])
                {
                    _players[idx] = user
                    _playerCount++
                    return idx
                }
                idx++
            }

            return -1
        }

        public function setPlayer(index:int, user:User):Boolean
        {
            if (index <= 0 || index > MAX_PLAYERS)
                return false

            if (!_players[index])
            {
                _players[index] = user
                _playerCount++
                return true
            }

            return false
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

        public function removePlayer(index:int):Boolean
        {
            if (getPlayer(index))
            {
                delete _players[index]
                _playerCount--

                if (_playerCount < 0)
                    _playerCount = 0

                return true
            }
            return false
        }

        public function get playerCount():int
        {
            return _playerCount
        }

        public function get players():Vector.<User>
        {
            var playerVec:Vector.<User> = new <User>[]

            for (var idx:int in _players)
                playerVec.push(_players[idx])

            return playerVec
        }

        public function clearPlayers():void
        {
            _players = {}
            _playerCount = 0;
        }

        public function addUser(user:User):void
        {
            _users[user.id] = user
        }

        public function removeUser(userId:int):void
        {
            delete _users[userId]
        }

        public function getUser(userId:int):User
        {
            return _users[userId]
        }

        public function hasUser(user:User):Boolean
        {
            return getUser(user.id) != null
        }

        public function updateUser(user:User):void
        {
            if (getUser(user.id))
                _users[user.id] = user;
        }

        public function get users():Vector.<User>
        {
            var usersVec:Vector.<User> = new <User>[]

            for (var idx:int in _users)
                usersVec.push(_users[idx])

            return usersVec
        }

        public function clearUsers():void
        {
            this._users = {}
        }

        public function isAllPlayersInStatus(status:int):Boolean
        {
            if (_playerCount <= 0)
                return false;

            for each (var player:User in _players)
            {
                if (player.gameplay.status != status)
                    return false;
            }

            return true;
        }

        public function isAllPlayersSameSong():Boolean
        {
            if (_playerCount <= 1)
                return false;

            var songP1:SongInfo = getPlayer(1).gameplay.songInfo;

            for each (var player:User in _players)
            {
                if (player.gameplay.songInfo != songP1)
                    return false;
            }

            return true;
        }

        public function getPlayersSong():SongInfo
        {
            if(isAllPlayersSameSong()) return getPlayer(1).gameplay.songInfo;

            return null;
        }

        public function applyVariablesFromOtherRoom(otherRoom:Room):void
        {
            for (var variable:String in otherRoom.variables)
                this.variables[variable] = otherRoom.variables[variable]
        }
    }
}
