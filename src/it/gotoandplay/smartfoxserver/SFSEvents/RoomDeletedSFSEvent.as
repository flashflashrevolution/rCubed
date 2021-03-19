package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RoomDeletedSFSEvent extends TypedSFSEvent
    {
        public var roomId:int;

        public function RoomDeletedSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomDeleted);
            roomId = params.roomId;
        }
    }
}
