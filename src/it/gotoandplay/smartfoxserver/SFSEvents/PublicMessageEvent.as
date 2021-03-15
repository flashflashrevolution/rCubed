package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class PublicMessageEvent extends TypedSFSEvent
    {
        public var message:String;
        public var sender:User;
        public var roomId:int;

        public function PublicMessageEvent(params:Object)
        {
            super(SFSEvent.onPublicMessage);
            message = params.message;
            sender = params.sender;
            roomId = params.roomId;
        }
    }
}
