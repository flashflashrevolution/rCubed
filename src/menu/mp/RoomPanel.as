package menu.mp
{
    import classes.Box;
    import classes.BoxText;
    import com.flashfla.components.ScrollBar;
    import menu.mp.List;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import arc.mp.MultiplayerConnection;
    import arc.mp.MultiplayerSingleton;
    import arc.mp.MultiplayerChat;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import arc.mp.MultiplayerPlayer;
    import arc.ArcGlobals;

    public class RoomPanel extends Box
    {
        private var room:Object;

        private var chat:RoomChat;
        private var users:RoomUsers;

        public function RoomPanel(room:Object, width:Number, height:Number)
        {
            super(width, height, false, true);
            this.room = room;
        }

        override protected function init(e:Event = null):void
        {
            super.init(e);

            users = new RoomUsers(122, height);
            users.x = width - 122;
            users.room = room;
            addChild(users);

            chat = new RoomChat(users.x, height);
            chat.room = room;
            addChild(chat);

            chat.textAreaAddLine(RoomChat.textFormatJoin(room));
            users.updateUsers();
        }
    }
}
