package classes.mp.commands
{

    public class MPCRoomJoinCode implements IMPCommand
    {
        public var code:String;

        public function MPCRoomJoinCode(code:String):void
        {
            this.code = code;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "room",
                    "a": "join_code",
                    "d": code});
        }
    }
}
