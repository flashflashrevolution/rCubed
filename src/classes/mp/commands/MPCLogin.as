package classes.mp.commands
{
    import classes.User;

    public class MPCLogin implements IMPCommand
    {
        public var user:User;
        public var version:uint;

        public function MPCLogin(version:uint, user:User)
        {
            this.version = version;
            this.user = user;
        }

        public function toJSON():String
        {
            var data:Object = {"sid": user.siteId,
                    "token": user.hash,
                    "version": version};

            return JSON.stringify({"t": "sys",
                    "a": "login",
                    "d": data});
        }
    }
}
