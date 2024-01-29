package classes.mp.events
{
    import classes.mp.MPSocketDataRaw;
    import classes.mp.MPUser;
    import classes.mp.room.MPRoom;
    import flash.events.Event;

    public class MPRoomRawEvent extends Event
    {
        public var room:MPRoom;
        public var user:MPUser;
        public var command:MPSocketDataRaw;

        public function MPRoomRawEvent(type:String, command:MPSocketDataRaw, room:MPRoom, user:MPUser = null)
        {
            super(type);

            this.command = command;
            this.room = room;
            this.user = user;
        }
    }
}
