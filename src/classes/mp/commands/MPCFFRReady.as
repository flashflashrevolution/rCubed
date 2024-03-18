package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRReady implements IMPCommand
    {
        public var room:MPRoomFFR;

        public function MPCFFRReady(room:MPRoomFFR):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "ready",
                    "d": {
                        "uid": room.uid
                    }});
        }
    }
}
