package classes.mp.commands
{
    import classes.mp.MPUser;

    public class MPCModBanUser implements IMPCommand
    {
        public var user:MPUser;
        public var duration:Number;

        public function MPCModBanUser(user:MPUser, duration:int):void
        {
            this.user = user;
            this.duration = duration;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "user",
                    "a": "mod_ban",
                    "d": {
                        "uid": user.uid,
                        "sid": user.sid,
                        "duration": duration
                    }});
        }
    }
}
