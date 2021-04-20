package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.Room

    public class RoomListUpdateSFSEvent extends TypedSFSEvent
    {
        public var roomList:Vector.<Room>;

        public function RoomListUpdateSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomListUpdate);
            roomList = params.roomList;
        }
    }
}
