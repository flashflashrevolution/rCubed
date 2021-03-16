package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RoomListUpdateSFSEvent extends TypedSFSEvent
    {
        public var roomList:Array;

        public function RoomListUpdateSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomListUpdate);
            roomList = params.roomList;
        }
    }
}
