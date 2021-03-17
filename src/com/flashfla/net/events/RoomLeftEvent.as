package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;
    import com.flashfla.net.Multiplayer;

    public class RoomLeftEvent extends TypedSFSEvent
    {
        public var room:SFSRoom;

        public function RoomLeftEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_LEFT);
            room = params.room;
        }
    }
}
