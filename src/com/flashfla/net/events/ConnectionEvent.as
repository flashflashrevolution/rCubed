package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class ConnectionEvent extends TypedSFSEvent
    {
        public var isSolo:Boolean;

        public function ConnectionEvent(_isSolo:Boolean = false)
        {
            super(Multiplayer.EVENT_CONNECTION);
            isSolo = _isSolo;
        }
    }
}
