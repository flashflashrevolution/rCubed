package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;

    public class RoomDeletedSFSEvent extends TypedSFSEvent
    {
        public var room:SFSRoom;

        public function RoomDeletedSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomDeleted);
            room = params.room;
        }
    }
}
