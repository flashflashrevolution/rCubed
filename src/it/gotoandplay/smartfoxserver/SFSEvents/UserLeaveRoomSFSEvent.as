package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class UserLeaveRoomSFSEvent extends TypedSFSEvent
    {
        public var roomId:int;
        public var userId:int;
        public var userName:String;

        public function UserLeaveRoomSFSEvent(params:Object)
        {
            super(SFSEvent.onUserLeaveRoom);
            roomId = params.roomId;
            userId = params.userId;
            userName = params.userName;
        }
    }
}
