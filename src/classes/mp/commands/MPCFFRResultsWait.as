package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRResultsWait implements IMPCommand
    {
        public var room:MPRoomFFR;

        public function MPCFFRResultsWait(room:MPRoomFFR)
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "results_wait",
                    "d": {
                        "uid": room.uid
                    }});
        }
    }
}
