package classes.mp
{
    import classes.mp.room.MPRoom;

    public class MPTeam
    {
        public var isStale:Boolean = false;

        public var room:MPRoom;

        public var uid:uint;
        public var name:String = "Default Team Name";
        public var id:uint = 0;
        public var maxUsers:Number = 0;
        public var spectator:Boolean = false;
        public var canJoin:Boolean = true;

        public var users:Vector.<MPUser> = new <MPUser>[];
        public var captain:MPUser;

        public function MPTeam(room:MPRoom)
        {
            this.room = room;
        }

        public function update(data:Object):void
        {
            var temp_user:MPUser;

            if (data.uid != null)
                this.uid = data.uid;

            if (data.id != null)
                this.id = data.id;

            if (data.name != null)
                this.name = data.name;

            if (data.maxUsers != null)
                this.maxUsers = data.maxUsers;

            if (data.spectator != null)
                this.spectator = data.spectator;

            if (data.canJoin != null)
                this.canJoin = data.canJoin;

            if (data.usersUID != null)
            {
                this.users.length = 0;
                for each (var user_uid:Number in data.usersUID)
                {
                    temp_user = room.getUser(user_uid);
                    if (temp_user)
                    {
                        this.users.push(temp_user);
                    }
                }
                _userSort();
            }

            if (data.captainUID != null)
            {
                temp_user = room.getUser(data.captainUID);
                if (temp_user)
                {
                    this.captain = temp_user;
                }
                else
                {
                    this.captain = null;
                }
            }

            this.isStale = false;
        }

        public function clear():void
        {
            this.isStale = true;
            this.room = null;
            this.users = null;
            this.captain = null;
            this.name = null;
        }

        public function get userCount():Number
        {
            return users.length;
        }

        public function addUser(user:MPUser):void
        {
            var idx:int = this.users.indexOf(user);
            if (idx == -1)
            {
                this.users.push(user);
            }
            _userSort();
        }

        public function removeUser(user:MPUser):void
        {
            var idx:int = this.users.indexOf(user);
            if (idx != -1)
            {
                this.users.splice(idx, 1);
            }
            _userSort();
        }

        public function setCaptain(user:MPUser):void
        {
            this.captain = user;
        }

        public function contains(user:MPUser):Boolean
        {
            return this.users.indexOf(user) != -1;
        }

        private function _userSort():void
        {
            users.sort(MPUser.sort);
        }

        /**
         * Sort Teams compare function based on id. Spectator should always be the lowest.
         */
        public static function sort(a:MPTeam, b:MPTeam):int
        {
            if (a.spectator && !b.spectator)
                return 1;

            if (!a.spectator && b.spectator)
                return -1;

            if (a.id > b.id)
                return 1;

            return -1;
        }

    }
}
