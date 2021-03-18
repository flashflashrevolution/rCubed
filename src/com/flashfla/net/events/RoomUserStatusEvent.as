package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import classes.Room
    import com.flashfla.net.Multiplayer;
    import classes.User;

    public class RoomUserStatusEvent extends TypedSFSEvent
    {
        public var user:User;
        public var room:Room;

        public function RoomUserStatusEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_USER_STATUS);
            user = params.user;
            room = params.room;
        }
    }
}
