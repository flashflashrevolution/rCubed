package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.Room

    public class UserCountChangeSFSEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function UserCountChangeSFSEvent(params:Object)
        {
            super(SFSEvent.onUserCountChange);
            room = params.room;
        }
    }
}
