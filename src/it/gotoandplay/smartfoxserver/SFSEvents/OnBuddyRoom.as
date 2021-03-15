package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnBuddyRoom extends TypedSFSEvent
    {
        public var idList:Array;

        public function OnBuddyRoom(params:Object)
        {
            idList = params.idList;
        }
    }
}
