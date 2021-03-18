package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import classes.Room
    import com.flashfla.net.Multiplayer;
    import classes.User;

    public class MessageEvent extends TypedSFSEvent
    {
        public var message:String;
        public var msgType:int;
        public var room:Room;
        public var user:User;

        public function MessageEvent(params:Object)
        {
            super(Multiplayer.EVENT_MESSAGE);
            message = params.message;
            msgType = params.msgType;
            room = params.room;
            user = params.user;
        }
    }
}
