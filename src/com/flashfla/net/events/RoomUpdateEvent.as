package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import classes.Room
    import com.flashfla.net.Multiplayer;

    public class RoomUpdateEvent extends TypedSFSEvent
    {
        public var room:Room;
        public var roomList:Boolean;

        public function RoomUpdateEvent(params:Object)
        {
            super(Multiplayer.EVENT_ROOM_UPDATE);
            room = params.room;
            roomList = params.roomList;
        }
    }
}
