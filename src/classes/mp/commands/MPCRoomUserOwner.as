package classes.mp.commands
{
    import classes.mp.MPUser;
    import classes.mp.room.MPRoom;

    public class MPCRoomUserOwner implements IMPCommand
    {
        public var room:MPRoom;
        public var user:MPUser;

        public function MPCRoomUserOwner(room:MPRoom, user:MPUser):void
        {
            this.room = room;
            this.user = user;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "room",
                    "a": "user_owner",
                    "d": {
                        "uid": room.uid,
                        "userUID": user.uid
                    }});
        }
    }
}
