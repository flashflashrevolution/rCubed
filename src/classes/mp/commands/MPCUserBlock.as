package classes.mp.commands
{
    import classes.mp.MPUser;

    public class MPCUserBlock implements IMPCommand
    {
        public var user:MPUser;
        public var message:String;
        public var type:Number;

        public function MPCUserBlock(user:MPUser):void
        {
            this.user = user;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "user",
                    "a": "block",
                    "d": {
                        "uid": user.uid,
                        "sid": user.sid
                    }});
        }
    }
}
