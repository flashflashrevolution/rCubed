package classes.mp.commands
{
    import classes.mp.MPUser;

    public class MPCModMuteUser implements IMPCommand
    {
        public var user:MPUser;
        public var duration:Number;

        public function MPCModMuteUser(user:MPUser, duration:int):void
        {
            this.user = user;
            this.duration = duration;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "user",
                    "a": "mod_mute",
                    "d": {
                        "uid": user.uid,
                        "sid": user.sid,
                        "duration": duration
                    }});
        }
    }
}
