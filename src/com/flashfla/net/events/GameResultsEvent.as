package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;
    import com.flashfla.net.Multiplayer;

    public class GameResultsEvent extends TypedSFSEvent
    {
        public var room:SFSRoom;

        public function GameResultsEvent(params:Object)
        {
            super(Multiplayer.EVENT_GAME_RESULTS);
            room = params.room;
        }
    }
}
