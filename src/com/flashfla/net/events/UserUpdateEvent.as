package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;
    import classes.User;

    public class UserUpdateEvent extends TypedSFSEvent
    {
        public var user:User;

        public function UserUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_USER_UPDATE);
            user = params.user;
        }
    }
}
