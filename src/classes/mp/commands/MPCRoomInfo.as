package classes.mp.commands
{
    import classes.mp.room.MPRoom;

    public class MPCRoomInfo implements IMPCommand
    {
        public var room:MPRoom;

        public function MPCRoomInfo(room:MPRoom):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "room",
                    "a": "info",
                    "d": {
                        "uid": room.uid
                    }});
        }
    }
}
