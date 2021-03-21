package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.Room
    import classes.User;

    public class JoinedRoomSFSEvent extends TypedSFSEvent
    {
        public var room:Room;
        public var users:Vector.<User>;

        public function JoinedRoomSFSEvent(params:Object)
        {
            super(SFSEvent.onJoinRoom);
            room = params.room;
            users = params.users
        }
    }
}
