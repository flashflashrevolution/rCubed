package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RoomLeftSFSEvent extends TypedSFSEvent
    {
        public var roomId:int;

        public function RoomLeftSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomLeft);
            roomId = params.roomId;
        }
    }
}
