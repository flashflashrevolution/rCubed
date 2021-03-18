package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;
    import classes.Room
    import classes.User;

    public class RoomUserEvent extends TypedSFSEvent
    {
        public var user:User;
        public var room:Room;

        public function RoomUserEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_USER);
            user = params.user;
            room = params.room;
        }
    }
}
