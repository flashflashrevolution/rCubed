package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class RoomAddedEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function RoomAddedEvent(params:Object)
        {
            super(SFSEvent.onRoomAdded);
            room = params.room;
        }
    }
}
