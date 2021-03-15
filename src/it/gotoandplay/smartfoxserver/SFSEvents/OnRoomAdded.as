package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class OnRoomAdded extends TypedSFSEvent
    {
        public var room:Room;

        public function OnRoomAdded(params:Object)
        {
            room = params.room;
        }
    }
}
