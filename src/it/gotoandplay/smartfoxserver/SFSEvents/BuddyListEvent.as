package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyListEvent extends TypedSFSEvent
    {
        public var list:Array;

        public function BuddyListEvent(params:Object)
        {
            super(SFSEvent.onBuddyList);
            list = params.list;
        }
    }
}
