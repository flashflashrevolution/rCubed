package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomLeftEvent extends TypedSFSEvent
    {
        public var message:String;

        public function RoomLeftEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_LEFT);
            message = params.message;
        }
    }
}
