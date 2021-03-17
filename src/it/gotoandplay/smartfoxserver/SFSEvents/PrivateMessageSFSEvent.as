package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSUser;

    public class PrivateMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var sender:SFSUser;
        public var userId:int;
        public var roomId:int;

        public function PrivateMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onPrivateMessage);
            message = params.message;
            sender = params.sender;
            userId = params.userId;
            roomId = params.roomId;
        }
    }
}
