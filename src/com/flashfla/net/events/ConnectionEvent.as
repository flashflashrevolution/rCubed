package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class ConnectionEvent extends TypedSFSEvent
    {

        public function ConnectionEvent()
        {
            super(Multiplayer.EVENT_CONNECTION);
        }
    }
}
