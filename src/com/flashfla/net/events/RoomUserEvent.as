package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomUserEvent extends TypedSFSEvent
    {
        public var user:Object;
        public var room:Object;

        public function RoomUserEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_USER);
            user = params.user;
            room = params.room;
        }
    }
}
