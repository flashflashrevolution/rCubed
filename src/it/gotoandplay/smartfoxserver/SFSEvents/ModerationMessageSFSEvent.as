package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ModerationMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var roomId:int;
        public var userId:int;

        public function ModerationMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onModeratorMessage);
            message = params.message;
            roomId = params.roomId;
            userId = params.userId;
        }
    }
}
