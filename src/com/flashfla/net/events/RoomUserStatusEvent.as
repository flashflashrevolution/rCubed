package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomUserStatusEvent extends TypedSFSEvent
    {
        public var user:Object;
        public var room:Object;

        public function RoomUserStatusEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_USER_STATUS);
            user = params.user;
            room = params.room;
        }
    }
}
