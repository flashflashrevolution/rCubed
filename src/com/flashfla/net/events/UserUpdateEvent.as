package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class UserUpdateEvent extends TypedSFSEvent
    {
        public var user:Object;
        public var changed:Array;

        public function UserUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_USER_UPDATE);
            user = params.user;
            changed = params.changed;
        }
    }
}
