package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class OnModerationMessage extends TypedSFSEvent
    {
        public var message:String;
        public var sender:User;

        public function OnModerationMessage(params:Object)
        {
            message = params.message;
            sender = params.sender;
        }
    }
}
