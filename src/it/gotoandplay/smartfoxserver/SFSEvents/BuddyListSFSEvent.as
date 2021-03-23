package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyListSFSEvent extends TypedSFSEvent
    {
        public var list:Array;

        public function BuddyListSFSEvent(params:Object)
        {
            super(SFSEvent.onBuddyList);
            list = params.list;
        }
    }
}
