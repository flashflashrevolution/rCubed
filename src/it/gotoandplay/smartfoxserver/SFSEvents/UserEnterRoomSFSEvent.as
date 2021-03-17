package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSUser;

    public class UserEnterRoomSFSEvent extends TypedSFSEvent
    {
        public var roomId:int;
        public var user:SFSUser;

        public function UserEnterRoomSFSEvent(params:Object)
        {
            super(SFSEvent.onUserEnterRoom);
            roomId = params.roomId;
            user = params.user;
        }
    }
}
