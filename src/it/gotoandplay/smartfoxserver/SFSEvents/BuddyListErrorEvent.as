package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyListErrorEvent extends TypedSFSEvent
    {
        public var error:String;

        public function BuddyListErrorEvent(params:Object)
        {
            super(SFSEvent.onBuddyListError);
            error = params.error;
        }
    }
}
