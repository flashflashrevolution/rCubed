package classes.mp.commands
{
    import classes.mp.MPUser;
    import classes.mp.room.MPRoom;

    public class MPCRoomUserBlock implements IMPCommand
    {
        public var room:MPRoom;
        public var user:MPUser;
        public var duration:Number;

        public function MPCRoomUserBlock(room:MPRoom, user:MPUser, duration:int):void
        {
            this.room = room;
            this.user = user;
            this.duration = duration;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "room",
                    "a": "user_block",
                    "d": {
                        "uid": room.uid,
                        "userUID": user.uid,
                        "userSID": user.sid,
                        "duration": duration
                    }});
        }
    }
}
