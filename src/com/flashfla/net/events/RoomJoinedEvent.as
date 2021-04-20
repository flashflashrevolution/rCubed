package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import classes.Room
    import com.flashfla.net.Multiplayer;

    public class RoomJoinedEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function RoomJoinedEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_JOINED);
            room = params.room;
        }
    }
}
