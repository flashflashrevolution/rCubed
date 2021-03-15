package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class AdminMessageEvent extends TypedSFSEvent
    {
        public var message:String;

        public function AdminMessageEvent(params:Object)
        {
            super(SFSEvent.onAdminMessage);
            message = params.message;
        }
    }
}
