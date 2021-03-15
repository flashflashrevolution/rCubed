package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class PrivateMessageEvent extends TypedSFSEvent
    {
        public var message:String;
        public var sender:User;
        public var roomId:int;

        public function PrivateMessageEvent(params:Object)
        {
            super(SFSEvent.onPrivateMessage);
            message = params.message;
            sender = params.sender;
            roomId = params.roomId;
        }
    }
}
