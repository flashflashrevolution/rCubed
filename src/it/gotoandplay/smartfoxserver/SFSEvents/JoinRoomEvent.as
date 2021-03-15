package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class JoinRoomEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function JoinRoomEvent(params:Object)
        {
            super(SFSEvent.onJoinRoom);
            room = params.room;
        }
    }
}
