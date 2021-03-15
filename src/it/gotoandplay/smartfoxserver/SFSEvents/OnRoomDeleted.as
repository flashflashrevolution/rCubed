package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class OnRoomDeleted extends TypedSFSEvent
    {
        public var room:Room;

        public function OnRoomDeleted(params:Object)
        {
            room = params.room;
        }
    }
}
