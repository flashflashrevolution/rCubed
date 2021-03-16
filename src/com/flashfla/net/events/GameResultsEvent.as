package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class GameResultsEvent extends TypedSFSEvent
    {
        public var message:String;

        public function GameResultsEvent(params:Object)
        {
            super(Multiplayer.EVENT_GAME_RESULTS);
            message = params.message;
        }
    }
}
