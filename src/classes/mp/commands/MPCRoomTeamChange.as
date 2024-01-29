package classes.mp.commands
{
    import classes.mp.MPTeam;
    import classes.mp.room.MPRoom;

    public class MPCRoomTeamChange implements IMPCommand
    {
        public var room:MPRoom;
        public var team:MPTeam;

        public function MPCRoomTeamChange(room:MPRoom, team:MPTeam)
        {
            this.room = room;
            this.team = team;
        }

        public function toJSON():String
        {
            var data:Object = {"uid": room.uid,
                    "team": team.uid};

            return JSON.stringify({"t": "room",
                    "a": "team",
                    "d": data});
        }
    }
}
