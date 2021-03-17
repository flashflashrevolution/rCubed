package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSUser;

    public class PublicMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var sender:SFSUser;
        public var userId:int;
        public var roomId:int;

        public function PublicMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onPublicMessage);
            message = params.message;
            sender = params.sender;
            userId = params.userId;
            roomId = params.roomId;
        }
    }
}
