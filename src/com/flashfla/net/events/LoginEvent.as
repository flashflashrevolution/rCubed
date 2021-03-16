package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class LoginEvent extends TypedSFSEvent
    {
        public var message:String;

        public function LoginEvent(params:Object)
        {
            super(Multiplayer.EVENT_LOGIN);
            message = params.message;
        }
    }
}
