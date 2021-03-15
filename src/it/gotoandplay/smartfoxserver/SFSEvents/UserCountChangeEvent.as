package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class UserCountChangeEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function UserCountChangeEvent(params:Object)
        {
            super(SFSEvent.onUserCountChange);
            room = params.room;
        }
    }
}
