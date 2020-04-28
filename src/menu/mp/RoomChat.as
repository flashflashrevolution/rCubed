package menu.mp
{
    import classes.Box;
    import classes.BoxText;
    import com.flashfla.components.ScrollBar;
    import menu.mp.List;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.KeyboardEvent;
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
    import com.bit101.components.Style;

    public class RoomChat extends Box
    {
        private var _room:Object;

        private var input:BoxText;
        private var scrollbar:ScrollBar;

        private var field:TextField;
        private var chatText:String;
        private var chatScroll:Boolean;
        private var chatScrollV:int;

        public function RoomChat(width:Number, height:Number)
        {
            super(width, height, false, true);

            chatText = "";
        }

        override protected function init(e:Event = null):void
        {
            super.init(e);

            var fh:int = 20;

            input = new BoxText(width, fh);
            input.y = height - fh;
            input.textColor = 0xFFFFFF;
            input.field.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            addChild(input);

            var scrollBG:Box = new Box(18, height - fh, false, false);
            var scrollDragger:Box = new Box(18, 55, false, false);
            scrollDragger.color = 0x000000;
            scrollbar = new ScrollBar(18, height - fh, scrollDragger, scrollBG);
            scrollbar.x = width - 18;
            scrollbar.addEventListener(Event.CHANGE, onScrollChanged);
            addChild(scrollbar);

            field = new TextField();
            field.height = height - fh;
            field.width = width - 18;
            field.multiline = true;
            field.wordWrap = true;
            field.selectable = true;
            field.embedFonts = true;
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.defaultTextFormat = Constant.TEXT_FORMAT;
            field.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            addChild(field);

            chatScroll = true;
        }

        private function onScrollChanged(e:Event):void
        {
            field.scrollV = Math.round((field.maxScrollV - 1) * scrollbar.scroll) + 1;
            chatScroll = (scrollbar.scroll == 1) || field.maxScrollV <= 1;
        }

        private function onMouseWheel(event:MouseEvent):void
        {
            var scrollV:int = Math.max(1, Math.min(field.maxScrollV, field.scrollV - event.delta));
            chatScroll = (scrollV >= field.maxScrollV) || field.maxScrollV <= 1;
            field.scrollV = scrollV;
            updateScrollbar(scrollV);
        }

        private function onKeyDown(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.ENTER)
            {
                _room.connection.sendMessage(_room, input.text);
                input.text = "";
            }
            event.stopPropagation();
        }

        private function onServerMessage(event:SFSEvent):void
        {
            textAreaAddLine(textFormatServerMessage(event.params.user, event.params.message));
        }

        private function onMessage(event:SFSEvent):void
        {
            if (event.params.type == MultiplayerConnection.MESSAGE_PUBLIC)
            {
                if (event.params.room == room)
                    textAreaAddLine(textFormatMessage(event.params.user, event.params.message));
            }
            else if (event.params.room == null || event.params.room == room)
                textAreaAddLine(textFormatPrivateMessageIn(event.params.user, event.params.message));
        }

        private function onRoomUser(event:SFSEvent):void
        {
            if (event.params.room == room)
                textAreaAddLine(textFormatUser(event.params.user, event.params.user.room != null));
        }

        private function onConnection(event:SFSEvent):void
        {
            if (!room.connection.connected)
                textAreaAddLine(textFormatDisconnect());
        }

        private function onRoomJoined(event:SFSEvent):void
        {
            if (event.params.room == room)
                textAreaAddLine(textFormatJoin(event.params.room));
        }

        private function onGameResults(event:SFSEvent):void
        {
            if (event.params.room == room)
                textAreaAddLine(textFormatGameResults(room, event.params.gameplay));
        }

        private function register():void
        {
            if (room)
            {
                room.connection.addEventListener(MultiplayerConnection.EVENT_SERVER_MESSAGE, onServerMessage);
                room.connection.addEventListener(MultiplayerConnection.EVENT_MESSAGE, onMessage);
                room.connection.addEventListener(MultiplayerConnection.EVENT_ROOM_USER, onRoomUser);
                room.connection.addEventListener(MultiplayerConnection.EVENT_CONNECTION, onConnection);
                room.connection.addEventListener(MultiplayerConnection.EVENT_ROOM_JOINED, onRoomJoined);
                if (room.isGame)
                    room.connection.addEventListener(MultiplayerSingleton.EVENT_GAME_RESULTS, onGameResults);
            }
        }

        private function unregister():void
        {
            if (room)
            {
                room.connection.removeEventListener(MultiplayerConnection.EVENT_SERVER_MESSAGE, onServerMessage);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_MESSAGE, onMessage);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_ROOM_USER, onRoomUser);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_CONNECTION, onConnection);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_ROOM_JOINED, onRoomJoined);
                room.connection.removeEventListener(MultiplayerSingleton.EVENT_GAME_RESULTS, onGameResults);
            }
        }

        private function updateScrollbar(scrollV:int = -1):void
        {
            if (scrollV < 0)
                scrollV = field.scrollV;
            scrollbar.scrollTo(field.maxScrollV <= 1 ? 0 : (scrollV - 1) / (field.maxScrollV - 1), true);
        }

        public function set room(value:Object):void
        {
            unregister();
            _room = value;
            register();
        }

        public function get room():Object
        {
            return _room;
        }

        public function textAreaAddLine(message:String):void
        {
            chatScrollV = field.scrollV;

            chatText += (chatText.length == 0 ? "" : "\n");
            if (ArcGlobals.instance.configMPTimestamp)
            {
                var date:Date = new Date();
                chatText += textFormatBold("[" + (date.hours == 0 ? 12 : (date.hours > 12 ? date.hours - 12 : date.hours)) + ":" + (date.minutes < 10 ? "0" : "") + date.minutes + (date.hours < 12 ? " AM" : " PM") + "] ");
            }
            chatText += message;

            draw();
        }

        public function draw():void
        {
            field.htmlText = textFormatColour(textFormatSize(textFormatFont(chatText, Style.fontName), ArcGlobals.instance.configMPSize.toString()), COLOUR_WHITE);
            addEventListener(Event.ENTER_FRAME, onDrawFrame);
        }

        private function onDrawFrame(event:Event):void
        {
            if (chatScroll)
                chatScrollV = field.maxScrollV;
            field.scrollV = chatScrollV;
            updateScrollbar(chatScrollV);
            removeEventListener(Event.ENTER_FRAME, onDrawFrame);
        }

        public static const COLOUR_WHITE:int = 0xffffff;
        public static const COLOUR_BLACK:int = 0x080808;
        public static const COLOUR_BLUE:int = 0xc0d8ff;
        public static const COLOUR_RED:int = 0xff9595;
        public static const COLOUR_GREEN:int = 0x88fb88;
        public static const COLOUR_PM:int = 0x88c0d8;
        public static const COLOUR_ORANGE:int = 0xffdcc0;
        public static const COLOUR_PINK:int = 0xff84b2;
        public static const COLOUR_PURPLE:int = 0xc3a1e1;

        public static const USER_COLOURS:Array = [COLOUR_WHITE, COLOUR_RED, COLOUR_PURPLE, COLOUR_GREEN, COLOUR_GREEN, COLOUR_GREEN, COLOUR_PINK, COLOUR_ORANGE, COLOUR_BLUE, COLOUR_BLACK, COLOUR_WHITE, COLOUR_WHITE];

        public static function nameUser(user:Object, format:Boolean = true):String
        {
            if (user == null)
                return "";
            return (user.userLevel > 0 ? textEscape("[" + user.userLevel + "]") + " " : "") + (format ? textFormatUserName(user) : textEscape(user.userName));
        }

        public static function textDullColour(colour:int, factor:Number):int
        {
            return (Math.min(0xff, int(((colour & 0xFF0000) >> 16) * factor)) << 16) | (Math.min(0xff, int(((colour & 0x00FF00) >> 8) * factor)) << 8) | Math.min(0xff, int((colour & 0x0000FF) * factor));
        }

        public static function textFormatUserName(user:Object, postfix:String = ""):String
        {
            var usercolour:int = user.userClass;
            if (user.userColour != null)
                usercolour = user.userColour;
            var colour:int = textDullColour(USER_COLOURS[usercolour], 0.85);
            if (user.variables.arc_colour != null)
                colour = user.variables.arc_colour;
            var userName:String = textEscape(user.userName) + postfix;
            return textFormatColour(userName, colour);
        }

        public static function textFormatServerMessage(user:Object, message:String):String
        {
            return textFormatColour(textFormatBold(textEscape("* Server Notice" + (user != null ? (" [" + user.userName + "]") : "") + ": " + message)), COLOUR_RED);
        }

        public static function textFormatMessage(user:Object, message:String):String
        {
            return textFormatUserName(user, ": ") + textEscape(message);
        }

        public static function textFormatPrivateMessageIn(user:Object, message:String):String
        {
            return textFormatBold(textFormatColour(textEscape("PM << " + user.userName + ":") + " ", COLOUR_PM)) + textEscape(message);
        }

        public static function textFormatPrivateMessageOut(user:Object, message:String):String
        {
            return textFormatBold(textFormatColour(textEscape("PM >> " + user.userName + ":") + " ", COLOUR_PM)) + textEscape(message);
        }

        public static function textFormatUser(user:Object, isJoin:Boolean):String
        {
            return textFormatBold(textFormatColour("* " + nameUser(user, false) + (isJoin ? " has joined" : " has left"), isJoin ? COLOUR_GREEN : COLOUR_RED));
        }

        public static function textFormatJoin(room:Object):String
        {
            return textFormatColour("* Joined " + textEscape(room.name), COLOUR_GREEN);
        }

        public static function textFormatDisconnect():String
        {
            return textFormatColour("* Disconnected", COLOUR_RED);
        }

        public static function textFormatModeratorMute(user:Object, minutes:int):String
        {
            return textFormatBold(textFormatColour("* " + nameUser(user, false) + " has been muted for " + minutes + " minutes.", COLOUR_RED));
        }

        public static function textFormatModeratorBan(user:Object, minutes:int):String
        {
            return textFormatBold(textFormatColour("* " + nameUser(user, false) + " has been banned for " + minutes + " minutes.", COLOUR_RED));
        }

        public static function textFormatGameResults(room:Object, gameplay:Object):String
        {
            var p1:Object = gameplay["player1"];
            var p2:Object = gameplay["player2"];

            for each (var user:Object in room.users)
            {
                if (user.playerID == 1)
                    p1.user = user;
                else if (user.playerID == 2)
                    p2.user = user;
            }

            var pa:Function = function(data:Object):String
            {
                return (data.amazing + data.perfect) + "-" + data.good + "-" + data.average + "-" + data.miss + "-" + data.boo + "-" + data.maxCombo;
            }

            var winner:Object = (p1.score > p2.score ? p1 : p2);
            var loser:Object = (p1.score > p2.score ? p2 : p1);
            var tie:Boolean = (p1.score == p2.score);

            var winnertext:String = winner.user.userName + " (" + winner.score + " " + pa(winner) + ")";
            var losertext:String = loser.user.userName + " (" + loser.score + " " + pa(loser) + ")";
            var songname:String = MultiplayerPlayer.nameSong(p1);
            return textFormatSize(textFormatBold(textFormatColour(textEscape("* " + songname + ": " + winnertext + (tie ? " tied with " : " won against ") + losertext), COLOUR_GREEN)), "-2");
        }

        public static function textFormatColour(message:String, colour:int):String
        {
            return "<font color=\"#" + colour.toString(16) + "\">" + message + "</font>";
        }

        public static function textFormatSize(message:String, size:String):String
        {
            return "<font size=\"" + size + "\">" + message + "</font>";
        }

        public static function textFormatFont(message:String, face:String):String
        {
            return "<font face=\"" + face + "\">" + message + "</font>";
        }

        public static function textFormatBold(message:String):String
        {
            return "<b>" + message + "</b>";
        }

        public static function textEscape(message:String):String
        {
            return MultiplayerConnection.htmlEscape(message);
        }
    }
}
