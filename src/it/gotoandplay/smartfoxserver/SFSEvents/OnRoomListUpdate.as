package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnRoomListUpdate extends TypedSFSEvent
    {
        public var roomList:Array;

        public function OnRoomListUpdate(params:Object)
        {
            roomList = params.roomList;
        }
    }
}
