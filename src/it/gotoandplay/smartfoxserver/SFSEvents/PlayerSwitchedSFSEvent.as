package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class PlayerSwitchedSFSEvent extends TypedSFSEvent
    {
        public var playerId:int;
        public var userId:int;
        public var roomId:int;

        public function PlayerSwitchedSFSEvent(params:Object)
        {
            super(SFSEvent.onPlayerSwitched);
            playerId = params.playerId;
            userId = params.userId;
            roomId = params.roomId;
        }
    }
}
