package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnUserLeaveRoom extends TypedSFSEvent
    {
        public var roomId:int;
        public var userId:int;
        public var userName:String;

        public function OnUserLeaveRoom(params:Object)
        {
            roomId = params.roomId;
            userId = params.userId;
            userName = params.userName;
        }
    }
}
