package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnBuddyPermissionRequest extends TypedSFSEvent
    {
        public var sender:String;
        public var message:String;

        public function OnBuddyPermissionRequest(params:Object)
        {
            sender = params.sender;
            message = params.message;
        }
    }
}
