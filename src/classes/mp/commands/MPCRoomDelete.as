package classes.mp.commands
{
    import classes.mp.room.MPRoom;

    public class MPCRoomDelete implements IMPCommand
    {
        public var room:MPRoom;

        public function MPCRoomDelete(room:MPRoom):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "room",
                    "a": "delete",
                    "d": {"uid": room.uid}});
        }
    }
}
