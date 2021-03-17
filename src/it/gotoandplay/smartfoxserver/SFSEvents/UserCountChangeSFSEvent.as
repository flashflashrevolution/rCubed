package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;

    public class UserCountChangeSFSEvent extends TypedSFSEvent
    {
        public var room:SFSRoom;

        public function UserCountChangeSFSEvent(params:Object)
        {
            super(SFSEvent.onUserCountChange);
            room = params.room;
        }
    }
}
