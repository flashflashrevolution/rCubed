package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomListEvent extends TypedSFSEvent
    {
        public function RoomListEvent()
        {
            super(Multiplayer.EVENT_ROOM_LIST);
        }
    }
}
