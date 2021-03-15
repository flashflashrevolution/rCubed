package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnBuddyListError extends TypedSFSEvent
    {
        public var error:String;

        public function OnBuddyListError(params:Object)
        {
            error = params.error;
        }
    }
}
