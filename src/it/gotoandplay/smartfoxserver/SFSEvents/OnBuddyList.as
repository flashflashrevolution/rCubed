package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnBuddyList extends TypedSFSEvent
    {
        public var list:Array;

        public function OnBuddyList(params:Object)
        {
            list = params.list;
        }
    }
}
