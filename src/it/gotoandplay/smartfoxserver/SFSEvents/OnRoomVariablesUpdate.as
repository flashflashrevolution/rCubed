package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class OnRoomVariablesUpdate extends TypedSFSEvent
    {
        public var room:Room;
        public var changedVars:Array;

        public function OnRoomVariablesUpdate(params:Object)
        {
            room = params.room;
            changedVars = params.changedVars;
        }
    }
}
