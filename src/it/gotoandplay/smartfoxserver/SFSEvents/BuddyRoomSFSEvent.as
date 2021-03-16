package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class BuddyRoomSFSEvent extends TypedSFSEvent
    {
        public var idList:Array;

        public function BuddyRoomSFSEvent(params:Object)
        {
            super(SFSEvent.onBuddyRoom);
            idList = params.idList;
        }
    }
}
