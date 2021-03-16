package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class UserUpdateEvent extends TypedSFSEvent
    {
        public var message:String;

        public function UserUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_USER_UPDATE);
            message = params.message;
        }
    }
}
