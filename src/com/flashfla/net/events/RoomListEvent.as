package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomListEvent extends TypedSFSEvent
    {
        public var message:String;

        public function RoomListEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_LIST);
            message = params.message;
        }
    }
}
