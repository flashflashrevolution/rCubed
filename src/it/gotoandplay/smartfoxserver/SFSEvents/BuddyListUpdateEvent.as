package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyListUpdateEvent extends TypedSFSEvent
    {
        public var buddy:Object;

        public function BuddyListUpdateEvent(params:Object)
        {
            super(SFSEvent.onBuddyListUpdate);
            buddy = params.buddy;
        }
    }
}
