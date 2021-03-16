package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class RoomUpdateEvent extends TypedSFSEvent
    {
        public var room:Object;
        public var roomList:Boolean;
        public var changed:Array;

        public function RoomUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_UPDATE);
            room = params.room;
            roomList = params.roomList;
            changed = params.changed;
        }
    }
}
