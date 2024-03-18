package classes.mp.events
{
    import classes.mp.MPSocketDataText;
    import classes.mp.MPUser;
    import classes.mp.room.MPRoom;

    public class MPRoomEvent extends MPEvent
    {
        public var room:MPRoom;
        public var user:MPUser;

        public function MPRoomEvent(type:String, command:MPSocketDataText, room:MPRoom, user:MPUser = null)
        {
            super(type, command);

            this.room = room;
            this.user = user;
        }

        override public function toString():String
        {
            return "---------------------------------\n[MPRoomEvent type=" + type + "]" + "\n" + command;
        }
    }
}
