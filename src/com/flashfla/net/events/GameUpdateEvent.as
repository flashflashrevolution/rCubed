package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class GameUpdateEvent extends TypedSFSEvent
    {
        public var message:String;

        public function GameUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_GAME_UPDATE);
            message = params.message;
        }
    }
}
