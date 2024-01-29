package classes.mp.commands
{
    import classes.mp.room.MPRoom;

    public class MPCRoomJoin implements IMPCommand
    {
        public var room:MPRoom;
        public var password:String;

        public function MPCRoomJoin(room:MPRoom, password:String = null):void
        {
            this.room = room;
            this.password = password;
        }

        public function toJSON():String
        {
            var data:Object = {"uid": room.uid};

            if (password != null && password.length > 0)
                data["password"] = password;

            return JSON.stringify({"t": "room",
                    "a": "join",
                    "d": data});
        }
    }
}
