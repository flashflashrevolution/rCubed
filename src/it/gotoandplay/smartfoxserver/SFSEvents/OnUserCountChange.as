package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class OnUserCountChange extends TypedSFSEvent
    {
        public var room:Room;

        public function OnUserCountChange(params:Object)
        {
            room = params.room;
        }
    }
}
