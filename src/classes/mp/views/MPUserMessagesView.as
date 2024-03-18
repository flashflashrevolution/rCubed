package classes.mp.views
{

    import assets.menu.icons.fa.iconProfile;
    import classes.mp.MPView;
    import classes.mp.Multiplayer;
    import classes.mp.components.MPViewChatLogUser;
    import classes.mp.components.MPViewUserListPM;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPPMSelect;
    import classes.mp.events.MPUserEvent;
    import classes.mp.prompts.MPUserProfilePrompt;
    import classes.ui.BoxIcon;
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.KeyboardEvent;

    public class MPUserMessagesView extends MPView
    {
        private static const _mp:Multiplayer = Multiplayer.instance;

        private var _width:Number = 409;
        private var _height:Number = 388;

        private var userName:Text;
        private var profile:BoxIcon;

        private var chat:MPViewChatLogUser;
        private var userlist:MPViewUserListPM;

        private var _userProfilePrompt:MPUserProfilePrompt;

        public function MPUserMessagesView(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
        {
            super(parent, xpos, ypos);

            build();
        }

        override public function build():void
        {
            super.build();

            chat = new MPViewChatLogUser(this, 0, 30, _width, _height - 30);

            // Userlist
            userlist = new MPViewUserListPM(this, 410, 0);
            userlist.addEventListener(MPPMSelect.CHAT_SELECT, e_onChatSelect);

            // Name
            new Text(this, 5, 0, "@", 14, "#c0c0c0").setAreaParams(15, 30);

            userName = new Text(this, 20, 0, _lang.string("mp_pm_no_user_selected"), 16);
            userName.setAreaParams(_width - 50, 30);

            profile = new BoxIcon(this, _width - 26, 4, 22, 22, new iconProfile(), e_onProfileSelect);
            profile.padding = 7;
            profile.visible = false;

            // Graphics
            redraw();
        }

        override public function dispose():void
        {
            userlist.removeEventListener(MPPMSelect.CHAT_SELECT, e_onChatSelect);

            closePrompts();
        }

        override public function onSelect():void
        {
            _mp.addEventListener(MPEvent.USER_MESSAGE, e_onMessage);
            _mp.addEventListener(MPEvent.USER_ROOM_INVITE, e_onMessage);

            userlist.update();
        }

        override public function onExit():void
        {
            _mp.removeEventListener(MPEvent.USER_MESSAGE, e_onMessage);
            _mp.removeEventListener(MPEvent.USER_ROOM_INVITE, e_onMessage);
        }

        public function redraw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(0, 0, 0);

            // Title BG
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, 0, _width, 30);
            this.graphics.endFill();

            // BG
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();

            // Title
            this.graphics.moveTo(1, 30);
            this.graphics.lineTo(_width, 30);
        }

        override public function onKeyInput(e:KeyboardEvent):void
        {
            if (_userProfilePrompt)
            {
                _userProfilePrompt.onKeyInput(e);
                return;
            }

            chat.onKeyInput(e);
        }

        public function e_onMessage(e:MPUserEvent):void
        {
            chat.update(e);
            userlist.update();
        }

        private function e_onChatSelect(e:MPPMSelect):void
        {
            chat.setHistory(e.chat);
            userName.text = chat.displayName;
            profile.visible = true;
        }

        private function e_onProfileSelect(e:Event):void
        {
            if (chat.user)
            {
                _userProfilePrompt = new MPUserProfilePrompt(chat.user, null, this);
                _userProfilePrompt.addEventListener(Event.CLOSE, e_onProfileClose);
            }
        }

        private function e_onProfileClose(e:Event):void
        {
            _userProfilePrompt.removeEventListener(Event.CLOSE, e_onProfileClose);
            _userProfilePrompt = null;
        }

        public function closePrompts():void
        {
            if (_userProfilePrompt)
            {
                _userProfilePrompt.close();
                e_onProfileClose(null);
            }
        }

    }
}
