package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class OnSpectatorSwitched extends TypedSFSEvent
    {
        public var success:String;
        public var newId:int;
        public var room:Room;

        public function OnSpectatorSwitched(params:Object)
        {
            success = params.success;
            newId = params.newId;
            room = params.room;
        }
    }
}
