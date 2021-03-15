package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class RoomDeletedEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function RoomDeletedEvent(params:Object)
        {
            super(SFSEvent.onRoomDeleted);
            room = params.room;
        }
    }
}
