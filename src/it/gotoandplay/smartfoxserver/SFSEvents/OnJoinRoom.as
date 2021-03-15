package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class OnJoinRoom extends TypedSFSEvent
    {
        public var room:Room;

        public function OnJoinRoom(params:Object)
        {
            room = params.room;
        }
    }
}
