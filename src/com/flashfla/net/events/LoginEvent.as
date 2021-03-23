package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class LoginEvent extends TypedSFSEvent
    {
        public function LoginEvent()
        {
            super(Multiplayer.EVENT_LOGIN);
        }
    }
}
