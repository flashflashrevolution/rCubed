package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnBuddyListUpdate extends TypedSFSEvent
    {
        public var buddy:Object;

        public function OnBuddyListUpdate(params:Object)
        {
            buddy = params.buddy;
        }
    }
}
