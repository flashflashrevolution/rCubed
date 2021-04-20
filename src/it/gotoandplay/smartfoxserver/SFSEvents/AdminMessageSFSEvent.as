package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class AdminMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var roomId:int;
        public var userId:int;

        public function AdminMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onAdminMessage);
            message = params.message;
            roomId = params.roomId;
            userId = params.userId;
        }
    }
}
