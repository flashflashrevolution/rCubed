package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class PrivateMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var userId:int;
        public var roomId:int;

        public function PrivateMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onPrivateMessage);
            message = params.message;
            userId = params.userId;
            roomId = params.roomId;
        }
    }
}
