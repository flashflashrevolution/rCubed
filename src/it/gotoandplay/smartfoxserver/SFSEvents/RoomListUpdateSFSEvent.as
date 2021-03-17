package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;

    public class RoomListUpdateSFSEvent extends TypedSFSEvent
    {
        public var roomList:Vector.<SFSRoom>;

        public function RoomListUpdateSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomListUpdate);
            roomList = params.roomList;
        }
    }
}
