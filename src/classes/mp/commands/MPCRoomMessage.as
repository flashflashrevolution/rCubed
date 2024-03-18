package classes.mp.commands
{
    import classes.mp.room.MPRoom;

    public class MPCRoomMessage implements IMPCommand
    {
        public var room:MPRoom;
        public var message:String;
        public var type:Number;

        public function MPCRoomMessage(room:MPRoom, message:String, type:Number = 0):void
        {
            this.room = room;
            this.message = message;
            this.type = type;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "room",
                    "a": "message",
                    "d": {
                        "uid": room.uid,
                        "message": message,
                        "type": type
                    }});
        }
    }
}
