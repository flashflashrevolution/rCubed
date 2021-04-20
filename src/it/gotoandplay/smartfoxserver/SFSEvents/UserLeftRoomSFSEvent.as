package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class UserLeftRoomSFSEvent extends TypedSFSEvent
    {
        public var roomId:int;
        public var userId:int;

        public function UserLeftRoomSFSEvent(params:Object)
        {
            super(SFSEvent.onUserLeaveRoom);
            roomId = params.roomId;
            userId = params.userId;
        }
    }
}
