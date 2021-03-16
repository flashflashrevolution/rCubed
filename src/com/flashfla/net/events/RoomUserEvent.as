package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomUserEvent extends TypedSFSEvent
    {
        public var message:String;

        public function RoomUserEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_USER);
            message = params.message;
        }
    }
}
