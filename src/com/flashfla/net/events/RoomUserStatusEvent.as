package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;
    import com.flashfla.net.Multiplayer;
    import classes.User;

    public class RoomUserStatusEvent extends TypedSFSEvent
    {
        public var user:User;
        public var room:SFSRoom;

        public function RoomUserStatusEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_USER_STATUS);
            user = params.user;
            room = params.room;
        }
    }
}
