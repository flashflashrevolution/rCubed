package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRGameStateChange implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var state:String;

        public function MPCFFRGameStateChange(room:MPRoomFFR, state:String)
        {
            this.room = room;
            this.state = state;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "game_state",
                    "d": {
                        "uid": room.uid,
                        "state": state
                    }});
        }
    }
}
