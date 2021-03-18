package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.User;

    public class ModerationMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;
        public var sender:User;

        public function ModerationMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onModeratorMessage);
            message = params.message;
            sender = params.sender;
        }
    }
}
