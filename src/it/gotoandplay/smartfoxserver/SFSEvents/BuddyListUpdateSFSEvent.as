package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyListUpdateSFSEvent extends TypedSFSEvent
    {
        public var buddy:Object;

        public function BuddyListUpdateSFSEvent(params:Object)
        {
            super(SFSEvent.onBuddyListUpdate);
            buddy = params.buddy;
        }
    }
}
