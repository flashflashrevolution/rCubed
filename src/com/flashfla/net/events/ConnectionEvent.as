package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class ConnectionEvent extends TypedSFSEvent
    {
        public var message:String;

        public function ConnectionEvent(params:Object)
        {
            super(Multiplayer.EVENT_CONNECTION);
            message = params.message;
        }
    }
}
