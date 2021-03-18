package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import classes.Room
    import com.flashfla.net.Multiplayer;

    public class RoomLeftEvent extends TypedSFSEvent
    {
        public var room:Room;

        public function RoomLeftEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_LEFT);
            room = params.room;
        }
    }
}
