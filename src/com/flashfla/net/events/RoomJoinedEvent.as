package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import classes.Room
    import com.flashfla.net.Multiplayer;

    public class RoomJoinedEvent extends TypedSFSEvent
    {
        public var room:Room;
        public var isSolo:Boolean;

        public function RoomJoinedEvent(params:Object, _isSolo:Boolean = false)
        {
            super(Multiplayer.EVENT_ROOM_JOINED);
            room = params.room;
            isSolo = _isSolo;
        }
    }
}
