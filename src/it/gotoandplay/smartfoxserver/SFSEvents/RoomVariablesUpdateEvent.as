package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class RoomVariablesUpdateEvent extends TypedSFSEvent
    {
        public var room:Room;
        public var changedVars:Array;

        public function RoomVariablesUpdateEvent(params:Object)
        {
            super(SFSEvent.onRoomVariablesUpdate);
            room = params.room;
            changedVars = params.changedVars;
        }
    }
}
