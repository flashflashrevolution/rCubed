package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class MessageEvent extends TypedSFSEvent
    {
        public var message:String;

        public function MessageEvent(params:Object)
        {
            super(Multiplayer.EVENT_MESSAGE);
            message = params.message;
        }
    }
}
