package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.Room

    public class RoomVariablesUpdateSFSEvent extends TypedSFSEvent
    {
        public var room:Room;
        public var changedVars:Array;

        public function RoomVariablesUpdateSFSEvent(params:Object)
        {
            super(SFSEvent.onRoomVariablesUpdate);
            room = params.room;
            changedVars = params.changedVars;
        }
    }
}
