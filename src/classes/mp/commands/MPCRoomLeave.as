package classes.mp.commands
{
    import classes.mp.room.MPRoom;

    public class MPCRoomLeave implements IMPCommand
    {
        public var room:MPRoom;

        public function MPCRoomLeave(room:MPRoom)
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "room",
                    "a": "leave",
                    "d": {
                        "uid": room.uid
                    }});
        }
    }
}
