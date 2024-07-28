package classes.mp.mode.ffr
{
    import classes.mp.MPUser;
    import classes.mp.room.MPRoomFFR;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;

    public class MPMatchFFR
    {
        public var room:MPRoomFFR;

        public var teams:Vector.<MPMatchFFRTeam> = new <MPMatchFFRTeam>[];
        public var teams_map:Dictionary = new Dictionary(true);

        public var users:Vector.<MPMatchFFRUser> = new <MPMatchFFRUser>[];
        public var users_map:Dictionary = new Dictionary(true);

        public var startTime:Number;

        public function MPMatchFFR(room:MPRoomFFR):void
        {
            this.room = room;
        }

        public function build(data:Object):void
        {
            var s_users:Object = data.users;
            var s_teams:Array = data.teams;

            for (var t:int = 0; t < s_teams.length; t++)
            {
                var teamData:Object = s_teams[t];

                var matchTeam:MPMatchFFRTeam = new MPMatchFFRTeam();
                matchTeam.update(teamData);
                teams.push(matchTeam);
                teams_map[matchTeam.id] = matchTeam;

                var scores:Array = teamData.scores;
                for (var s:int = 0; s < scores.length; s++)
                {
                    var scoreData:Object = scores[s];
                    var scoreUser:MPUser = room.getUser(scoreData.uid);

                    if (!scoreUser)
                    {
                        scoreUser = new MPUser();
                        if (s_users[scoreUser.uid] != null)
                            scoreUser.update(s_users[scoreUser.uid]);
                        else
                            scoreUser.update({uid: scoreData.uid, name: "UID " + scoreData.uid});
                    }

                    var matchUser:MPMatchFFRUser = new MPMatchFFRUser(room, scoreUser);
                    matchUser.update(scoreData);
                    matchUser.rate = room.getPlayerSongRate(scoreUser);

                    users.push(matchUser);
                    users_map[scoreUser.uid] = matchUser;

                    matchTeam.users.push(matchUser);
                }
            }

            startTime = getTimer();
        }

        public function update(data:Object):void
        {
            // Not Built
            if (teams.length == 0)
                return;

            var s_teams:Array = data.teams;

            for (var t:int = 0; t < s_teams.length; t++)
            {
                var teamData:Object = s_teams[t];
                var matchTeam:MPMatchFFRTeam = teams_map[teamData.id];
                matchTeam.update(teamData);

                var scores:Array = teamData.scores;
                for (var s:int = 0; s < scores.length; s++)
                {
                    var scoreData:Object = scores[s];
                    var matchUser:MPMatchFFRUser = users_map[scoreData.uid];
                    matchUser.update(scoreData);
                }
            }
        }
    }
}
