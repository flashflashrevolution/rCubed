package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyListErrorSFSEvent extends TypedSFSEvent
    {
        public var error:String;

        public function BuddyListErrorSFSEvent(params:Object)
        {
            super(SFSEvent.onBuddyListError);
            error = params.error;
        }
    }
}
