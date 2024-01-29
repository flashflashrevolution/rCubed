package classes.mp.pm
{
    import classes.Language;
    import classes.mp.MPColors;
    import classes.mp.MPUser;
    import classes.mp.components.chatlog.MPChatLogEntry;
    import classes.mp.components.chatlog.MPChatLogEntryText;
    import classes.mp.components.chatlog.MPChatLogRoomInvite;
    import com.flashfla.utils.StringUtil;
    import com.flashfla.utils.sprintf;

    public class MPUserChatHistory
    {
        private static const _lang:Language = Language.instance;
        private static const DATE:Date = new Date();

        private var MAX_HISTORY:int = 200;
        public var messages:Vector.<MPChatLogEntry> = new <MPChatLogEntry>[];
        public var user:MPUser;
        public var newMessage:Boolean = false;
        public var lastMessage:Number = 0;

        public function MPUserChatHistory(user:MPUser):void
        {
            this.user = user;

            add(new MPChatLogEntryText("<font color=\"" + MPColors.SYSTEM_MESSAGE_COLOR + "\">" + sprintf(_lang.string("mp_pm_chat_start"), {"name": user.name}) + "</font>"));
        }

        public function add(entry:MPChatLogEntry):void
        {
            lastMessage = new Date().getTime();
            messages.push(entry);

            if (messages.length > MAX_HISTORY)
                messages.splice(0, messages.length - MAX_HISTORY);
        }

        public function addMessage(user:MPUser, sender:MPUser, data:Object):void
        {
            DATE.setTime(data.timestamp);

            var type:Number = data.type;
            var color:String = (type == 0 ? MPColors.MESSAGE_COLOR : (type == 2 ? MPColors.MESSAGE_ADMIN_COLOR : MPColors.MESSAGE_MOD_COLOR))

            var message:String = "";

            message += "<font color=\"" + MPColors.TIMESTAMP_COLOR + "\">" + StringUtil.pad(DATE.getHours().toString(), 2, "0") + ":" + StringUtil.pad(DATE.getMinutes().toString(), 2, "0") + "</font> ";
            message += sender.nameHTML + ":  ";
            message += "<font color=\"" + color + "\">" + data.message + "</font>";

            add(new MPChatLogEntryText(message));
            newMessage = true;
        }

        public function addGameInvite(user:MPUser, sender:MPUser, data:Object):void
        {
            add(new MPChatLogRoomInvite(sender, data));
            newMessage = true;
        }

        public function clear():void
        {
            messages.length = 0;
            newMessage = false;
        }

        public static function sort(a:MPUserChatHistory, b:MPUserChatHistory):int
        {
            if (a.lastMessage > b.lastMessage)
                return -1;

            return 1;
        }

    }
}
