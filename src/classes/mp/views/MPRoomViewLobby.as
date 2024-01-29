package classes.mp.views
{
    import classes.mp.components.MPViewChatLogRoom;
    import classes.mp.components.MPViewUserListRoom;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.events.MPUserEvent;
    import classes.mp.prompts.MPUserProfilePrompt;
    import classes.mp.room.MPRoom;
    import classes.ui.Text;
    import com.flashfla.utils.sprintf;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.KeyboardEvent;

    public class MPRoomViewLobby extends MPRoomView
    {
        public var room:MPRoom;

        private var _width:Number = 409;
        private var _height:Number = 388;

        private var roomName:Text;

        private var chat:MPViewChatLogRoom;
        private var userlist:MPViewUserListRoom;

        private var _userProfilePrompt:MPUserProfilePrompt;

        public function MPRoomViewLobby(room:MPRoom, parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
        {
            this.room = room;

            super(parent, xpos, ypos);
        }

        override public function build():void
        {
            super.build();

            chat = new MPViewChatLogRoom(this, 0, 30, _width, _height - 30);
            chat.setRoom(room);

            // Userlist
            userlist = new MPViewUserListRoom(this, 410, 0);
            userlist.setRoom(room);
            userlist.addEventListener(MPEvent.ROOM_USERLIST_SELECT, e_onUserSelect);

            // Name
            new Text(this, 5, 0, "#", 14, "#c0c0c0").setAreaParams(15, 30);

            roomName = new Text(this, 20, 0, room.name, 16);
            roomName.setAreaParams(_width - 25, 30);

            // Graphics
            redraw();
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

        public function onChatMessage(e:MPRoomEvent):void
        {
            if (e.room == this.room)
                chat.onChatMessage(e);
        }

        override protected function updateRoomButton():void
        {
            this.roomButton.updateText(room.name, sprintf(_lang.string("mp_btn_user_count"), {count: room.userCount}));
        }

        override public function set width(value:Number):void
        {
            _width = value;
            redraw();
        }

        override public function get width():Number
        {
            return _width;
        }

        override public function set height(value:Number):void
        {
            _height = height;
            redraw();
        }

        override public function get height():Number
        {
            return _height;
        }

        override protected function e_roomMessage(e:MPRoomEvent):void
        {
            if (e.room === this.room)
                onChatMessage(e);
        }

        override protected function e_teamUpdate(e:MPRoomEvent):void
        {
            if (e.room === this.room)
                userlist.update();
        }

        override protected function e_userJoin(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                updateRoomButton();
            }
        }

        override protected function e_userLeave(e:MPRoomEvent):void
        {
            if (e.room === this.room)
            {
                userlist.update();
                updateRoomButton();
            }
        }

        override public function dispose():void
        {
            if (_userProfilePrompt)
            {
                _userProfilePrompt.close();
                _userProfilePrompt = null;
            }

            super.dispose();
        }

        private function e_onUserSelect(e:MPUserEvent):void
        {
            _userProfilePrompt = new MPUserProfilePrompt(e.user, this.room, this);
            _userProfilePrompt.addEventListener(Event.CLOSE, e_onProfileClose);
        }

        private function e_onProfileClose(e:Event):void
        {
            _userProfilePrompt.removeEventListener(Event.CLOSE, e_onProfileClose);
            _userProfilePrompt = null;
        }

    }
}
