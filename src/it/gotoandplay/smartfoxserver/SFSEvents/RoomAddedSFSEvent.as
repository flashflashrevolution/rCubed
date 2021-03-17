package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;

    public class RoomAddedSFSEvent extends TypedSFSEvent
    {
        public var room:SFSRoom;

        public function RoomAddedSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomAdded);
            room = params.room;
        }
    }
}
