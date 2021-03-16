package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomUpdateEvent extends TypedSFSEvent
    {
        public var message:String;

        public function RoomUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_UPDATE);
            message = params.message;
        }
    }
}
