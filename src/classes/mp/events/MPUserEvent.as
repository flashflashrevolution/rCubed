package classes.mp.events
{
    import classes.mp.MPSocketDataText;
    import classes.mp.MPUser;

    public class MPUserEvent extends MPEvent
    {
        public var user:MPUser;
        public var user_sender:MPUser;

        public function MPUserEvent(type:String, command:MPSocketDataText, user:MPUser = null, user_sender:MPUser = null)
        {
            super(type, command);

            this.user = user;
            this.user_sender = user_sender;
        }

        override public function toString():String
        {
            return "---------------------------------\n[MPUserEvent type=" + type + "]" + "\n" + command;
        }
    }
}
