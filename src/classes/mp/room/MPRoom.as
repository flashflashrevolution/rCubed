package classes.mp.room
{

    import classes.mp.MPSocketDataRaw;
    import classes.mp.MPSocketDataText;
    import classes.mp.MPTeam;
    import classes.mp.MPUser;
    import classes.mp.Multiplayer;
    import flash.utils.Dictionary;

    public class MPRoom
    {
        protected static const _mp:Multiplayer = Multiplayer.instance;

        public var isStale:Boolean = false;

        public var uid:uint;
        public var name:String = "Default Room Name";
        public var persist:Boolean = false;
        public var type:String = "lobby";
        public var joinCode:String = "--------";

        public var hasPassword:Boolean = false;
        public var password:String;

        public var owner:MPUser;
        public var ownerName:String = "";

        public var isGame:Boolean = false;
        public var maxPlayers:uint = 2;

        public var users:Vector.<MPUser> = new <MPUser>[];
        public var userCount:uint = 0;
        public var spectatorCount:uint = 0;

        public var skillMin:Number = -1;
        public var skillMax:Number = -1;

        public var variables:Object = {};
        public var teamCount:Number = 0;
        public var teams:Vector.<MPTeam> = new <MPTeam>[];
        public var teams_map:Dictionary = new Dictionary(true);

        public var teamSpectator:MPTeam;

        public function MPRoom()
        {

        }

        public function update(data:Object):void
        {
            this.isStale = false;

            // Room List
            if (data.uid != null)
                this.uid = data.uid;

            if (data.name != null)
                this.name = data.name;

            if (data.persist != null)
                this.persist = data.persist;

            if (data.ownerName != null)
                this.ownerName = data.ownerName;

            if (data.hasPassword != null)
                this.hasPassword = data.hasPassword;

            if (data.password != null)
                this.password = data.password;

            if (data.joinCode != null)
                this.joinCode = data.joinCode;

            if (data.type != null)
                this.type = data.type;

            if (data.isGame != null)
                this.isGame = data.isGame;

            if (data.maxPlayers != null)
                this.maxPlayers = data.maxPlayers;

            if (data.teamCount != null)
                this.teamCount = data.teamCount;

            if (data.userCount != null)
                this.userCount = data.userCount;

            if (data.spectatorCount != null)
                this.spectatorCount = data.spectatorCount;

            if (data.skillMin != null)
                this.skillMin = data.skillMin;

            if (data.skillMax != null)
                this.skillMax = data.skillMax;

            if (data.vars != null)
                this.variables = data.vars;

            // Room Data
            if (data.users != null)
            {
                this.users.length = 0;

                for each (var temp_user:Object in data.users)
                {
                    var mp_user:MPUser = _mp.getUser(temp_user.uid);

                    if (mp_user == null)
                    {
                        mp_user = new MPUser();
                        mp_user.update(temp_user);
                        _mp.setUser(mp_user);
                    }

                    this.users.push(mp_user);
                }

                this.userCount = this.users.length;
            }

            if (data.owner != null)
            {
                if (data.owner > 0)
                {
                    var owner_user:MPUser = _mp.getUser(data.owner);

                    if (owner_user != null)
                        owner = owner_user;
                }
                else
                {
                    owner = null;
                }
            }

            if (data.teams != null)
                _teamBatchUpdate(data.teams);

            if (data.teamSpectator != null)
            {
                this.teamSpectator = teams_map[data.teamSpectator];
                this.spectatorCount = teamSpectator.users.length;
            }
        }

        private function _teamBatchUpdate(temp_teams:Array):void
        {
            var i:int;

            // Mark all Rooms as Stale
            for (i = teams.length - 1; i >= 0; i--)
            {
                teams[i].isStale = true;
            }

            // Add / Update Existing Rooms
            for (i = temp_teams.length - 1; i >= 0; i--)
            {
                _teamUpdateDirect(temp_teams[i]);
            }

            // Delete Stale Teams
            for (i = teams.length - 1; i >= 0; i--)
            {
                if (teams[i].isStale)
                {
                    delete teams_map[teams[i].uid];
                    teams.splice(i, 1);
                }
            }

            teamCount = teams.length;

            _teamSort();
        }

        private function _teamUpdateDirect(team:Object):void
        {
            var temp_team:MPTeam = teams_map[team.uid];

            // Existing
            if (temp_team)
                temp_team.update(team);

            // New
            else
            {
                temp_team = new MPTeam(this);
                temp_team.update(team);
                this.teams.push(temp_team);
                this.teams_map[temp_team.uid] = temp_team;
            }
        }

        private function _teamSort():void
        {
            teams.sort(MPTeam.sort);
        }

        /**
         * Sort Rooms compare function based on uid. uid starts at 0 for the Lobby and increases for every room created.
         * uid are unique and can't be the same.
         * Used in `_roomSort`.
         */
        public static function sort(a:MPRoom, b:MPRoom):int
        {
            if (a.uid > b.uid)
                return 1;

            return -1;
        }

        public function onJoin():void
        {

        }

        public function onLeave():void
        {

        }

        public function getUser(uid:uint):MPUser
        {
            return _mp.getUser(uid);
        }

        public function get playerCount():Number
        {
            var cnt:Number = 0;
            for (var i:Number = teams.length - 1; i >= 0; i--)
            {
                if (!teams[i].spectator)
                    cnt += teams[i].users.length;
            }
            return cnt;
        }

        public function get playerCountMax():Number
        {
            return maxPlayers * (teams.length - 1);
        }

        public function clear():void
        {
            this.clearExtra();
            this.teams_map = null;
            this.teams = null;
            this.users = null;
        }

        /**
         * Clear extra data not required for the room list view.
         */
        public function clearExtra():void
        {
            this.variables = null;
            this.users.length = 0;

            // Clear Teams
            for each (var team:MPTeam in teams)
            {
                team.clear();
                delete teams_map[team.uid];
            }
            this.teams.length = 0;
            this.teamSpectator = null;
        }

        public function userJoin(user:MPUser):void
        {
            var idx:int = this.users.indexOf(user);
            if (idx == -1)
            {
                this.users.push(user);
                this.userCount = this.users.length;
            }
        }

        public function userJoinTeam(user:MPUser, teamUID:int, vars:Object = null):void
        {
            var team:MPTeam = teams_map[teamUID];
            if (team)
            {
                team.addUser(user);

                if (team === teamSpectator)
                    this.spectatorCount = teamSpectator.users.length;
            }
        }

        public function userLeave(user:MPUser):void
        {
            var idx:int = this.users.indexOf(user);
            if (idx != -1)
            {
                for each (var team:MPTeam in this.teams)
                {
                    if (team.contains(user))
                    {
                        team.removeUser(user);
                        if (team === teamSpectator)
                            this.spectatorCount = teamSpectator.users.length;
                    }
                }

                this.users.splice(idx, 1);
                this.userCount = this.users.length;
            }
        }

        public function userLeaveTeam(user:MPUser, teamUID:int):void
        {
            var team:MPTeam = teams_map[teamUID];
            if (team)
            {
                team.removeUser(user);

                if (team === teamSpectator)
                    this.spectatorCount = teamSpectator.users.length;
            }
        }

        public function userTeamCaptain(user:MPUser, teamUID:int):void
        {
            var team:MPTeam = teams_map[teamUID];
            if (team)
            {
                team.setCaptain(user);
            }
        }

        public function modeCommand(cmd:MPSocketDataText, user:MPUser):void
        {

        }

        public function modeRawCommand(cmd:MPSocketDataRaw, user:MPUser):void
        {

        }

        ///////////////////////////////////////////////////////////////////////

        public function isPlayer(user:MPUser):Boolean
        {
            if (!user || teams.length == 1 || users.indexOf(user) == -1)
                return false;

            return !teamSpectator.contains(user);
        }

        public function isPlayerReady(user:MPUser):Boolean
        {
            return false;
        }

        public function canUserPlaySong(user:MPUser):Boolean
        {
            return true;
        }

        ///////////////////////////////////////////////////////////////////////

        public function toString():String
        {
            return "[MPRoom uid=" + uid + ", name=" + name + "]";
        }
    }
}
