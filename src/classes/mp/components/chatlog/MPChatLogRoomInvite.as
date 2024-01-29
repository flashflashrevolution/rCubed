package classes.mp.components.chatlog
{
    import classes.Language;
    import classes.mp.MPUser;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCRoomJoinCode;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import com.flashfla.utils.sprintf;
    import flash.events.Event;

    public class MPChatLogRoomInvite extends MPChatLogEntry
    {
        private static const _lang:Language = Language.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;

        private var user:MPUser;
        private var joinCode:String;
        private var roomName:String;

        private var btn:BoxButton;

        public function MPChatLogRoomInvite(user:MPUser, data:Object):void
        {
            this.user = user;
            this.roomName = data.name;
            this.joinCode = data.code;
        }

        override public function build(width:Number):void
        {
            if (built)
                return;

            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(5, 5, width - 11, 45);
            this.graphics.endFill();

            new Text(this, 10, 7, sprintf(_lang.string("mp_pm_room_invite"), {name: user.name}), 10, "#c3c3c3").setAreaParams(width - 120, 22);
            new Text(this, 9, 25, roomName, 12).setAreaParams(width - 110, 22);

            btn = new BoxButton(this, width - 96, 14, 85, 26, _lang.string("mp_pm_room_invite_join"), 11, e_songSelect);

            _height = 52;
            built = true;
        }

        private function e_songSelect(e:Event):void
        {
            _mp.sendCommand(new MPCRoomJoinCode(joinCode));
        }
    }
}
