package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;
    import classes.User;

    public class ServerMessageEvent extends TypedSFSEvent
    {
        public var message:String;
        public var user:User;

        public function ServerMessageEvent(params:Object)
        {
            super(Multiplayer.EVENT_SERVER_MESSAGE);
            message = params.message;
            user = params.user;
        }
    }
}
