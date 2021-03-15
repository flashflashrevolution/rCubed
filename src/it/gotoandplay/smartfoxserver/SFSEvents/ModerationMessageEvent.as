package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class ModerationMessageEvent extends TypedSFSEvent
    {
        public var message:String;
        public var sender:User;

        public function ModerationMessageEvent(params:Object)
        {
            super(SFSEvent.onModeratorMessage);
            message = params.message;
            sender = params.sender;
        }
    }
}
