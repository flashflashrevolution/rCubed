package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.Room

    public class JoinRoomSFSEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function JoinRoomSFSEvent(params:Object)
        {
            super(SFSEvent.onJoinRoom);
            room = params.room;
        }
    }
}
