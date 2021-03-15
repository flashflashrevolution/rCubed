package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RoomLeftEvent extends TypedSFSEvent
    {
        public var roomId:int;

        public function RoomLeftEvent(params:Object)
        {
            super(SFSEvent.onRoomLeft);
            roomId = params.roomId;
        }
    }
}
