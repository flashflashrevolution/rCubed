package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RoomListUpdateEvent extends TypedSFSEvent
    {
        public var roomList:Array;

        public function RoomListUpdateEvent(params:Object)
        {
            super(SFSEvent.onRoomListUpdate);
            roomList = params.roomList;
        }
    }
}
