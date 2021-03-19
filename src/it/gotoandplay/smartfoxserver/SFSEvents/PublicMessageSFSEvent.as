package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class PublicMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var userId:int;
        public var roomId:int;

        public function PublicMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onPublicMessage);
            message = params.message;
            userId = params.userId;
            roomId = params.roomId;
        }
    }
}
