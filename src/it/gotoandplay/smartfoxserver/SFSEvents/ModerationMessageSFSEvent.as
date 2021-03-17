package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSUser;

    public class ModerationMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var sender:SFSUser;

        public function ModerationMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onModeratorMessage);
            message = params.message;
            sender = params.sender;
        }
    }
}
