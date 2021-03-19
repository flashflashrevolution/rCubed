package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class UserCountChangeSFSEvent extends TypedSFSEvent
    {
        public var roomId:int;
        public var userCount:int;
        public var specCount:int;

        public function UserCountChangeSFSEvent(params:Object)
        {
            super(SFSEvent.onUserCountChange);
            roomId = params.roomId;
            userCount = params.userCount;
            specCount = params.specCount;
        }
    }
}
