package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomJoinedEvent extends TypedSFSEvent
    {
        public var message:String;

        public function RoomJoinedEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_JOINED);
            message = params.message;
        }
    }
}
