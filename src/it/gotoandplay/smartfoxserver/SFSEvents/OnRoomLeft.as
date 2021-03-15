package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnRoomLeft extends TypedSFSEvent
    {
        public var roomId:int;

        public function OnRoomLeft(params:Object)
        {
            roomId = params.roomId;
        }
    }
}
