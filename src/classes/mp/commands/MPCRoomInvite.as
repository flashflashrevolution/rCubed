package classes.mp.commands
{
    import classes.mp.MPUser;
    import classes.mp.room.MPRoom;

    public class MPCRoomInvite implements IMPCommand
    {
        public var user:MPUser;
        public var room:MPRoom;

        public function MPCRoomInvite(user:MPUser, room:MPRoom):void
        {
            this.user = user;
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "user",
                    "a": "room_invite",
                    "d": {
                        "uid": user.uid,
                        "name": room.name,
                        "code": room.joinCode
                    }});
        }
    }
}
