package classes.mp.commands
{
    import classes.mp.MPUser;

    public class MPCUserMessage implements IMPCommand
    {
        public var user:MPUser;
        public var message:String;
        public var type:Number;

        public function MPCUserMessage(user:MPUser, message:String, type:Number = 0):void
        {
            this.user = user;
            this.message = message;
            this.type = type;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "user",
                    "a": "message",
                    "d": {
                        "uid": user.uid,
                        "message": message,
                        "type": type
                    }});
        }
    }
}
