package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class OnPlayerSwitched extends TypedSFSEvent
    {
        public var success:String;
        public var newId:int;
        public var room:Room;

        public function OnPlayerSwitched(params:Object)
        {
            success = params.success;
            newId = params.newId;
            room = params.room;
        }
    }
}
