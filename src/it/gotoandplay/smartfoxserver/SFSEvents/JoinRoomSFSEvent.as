package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;

    public class JoinRoomSFSEvent extends TypedSFSEvent
    {
        public var room:SFSRoom;

        public function JoinRoomSFSEvent(params:Object)
        {
            super(SFSEvent.onJoinRoom);
            room = params.room;
        }
    }
}
