package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyPermissionRequestSFSEvent extends TypedSFSEvent
    {
        public var sender:String;
        public var message:String;

        public function BuddyPermissionRequestSFSEvent(params:Object)
        {
            super(SFSEvent.onBuddyPermissionRequest);
            sender = params.sender;
            message = params.message;
        }
    }
}
