package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;

    public class PlayerSwitchedEvent extends TypedSFSEvent
    {
        public var success:String;
        public var newId:int;
        public var userId:int;
        public var room:Room;

        public function PlayerSwitchedEvent(params:Object)
        {
            super(SFSEvent.onPlayerSwitched);
            success = params.success;
            newId = params.newId;
            userId = params.userId;
            room = params.room;
        }
    }
}
