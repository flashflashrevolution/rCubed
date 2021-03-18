package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.Room

    public class RoomDeletedSFSEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function RoomDeletedSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomDeleted);
            room = params.room;
        }
    }
}
