package classes.mp.events
{
    import classes.mp.pm.MPUserChatHistory;
    import flash.events.Event;

    public class MPPMSelect extends Event
    {
        public static const CHAT_SELECT:String = "chat_select";

        public var chat:MPUserChatHistory;

        public function MPPMSelect(chat:MPUserChatHistory):void
        {
            this.chat = chat;
            super(CHAT_SELECT);
        }
    }
}
