package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class SpectatorSwitchedSFSEvent extends TypedSFSEvent
    {
        public var playerId:int;
        public var userId:int;
        public var roomId:int;

        public function SpectatorSwitchedSFSEvent(params:Object)
        {
            super(SFSEvent.onSpectatorSwitched);
            playerId = params.playerId;
            userId = params.userId;
            roomId = params.roomId;
        }
    }
}
