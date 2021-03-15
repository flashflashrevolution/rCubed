package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyPermissionRequestEvent extends TypedSFSEvent
    {
        public var sender:String;
        public var message:String;

        public function BuddyPermissionRequestEvent(params:Object)
        {
            super(SFSEvent.onBuddyPermissionRequest);
            sender = params.sender;
            message = params.message;
        }
    }
}
