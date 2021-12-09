package arc.mp
{
    import arc.ArcGlobals;
    import com.bit101.components.Component;
    import com.bit101.components.InputText;
    import com.bit101.components.Style;
    import com.bit101.components.TextArea;
    import com.flashfla.net.Multiplayer;
    import com.flashfla.net.events.ServerMessageEvent;
    import com.flashfla.net.events.ExtensionResponseEvent;
    import com.flashfla.net.events.MessageEvent;
    import com.flashfla.net.events.RoomUserEvent;
    import com.flashfla.net.events.ConnectionEvent;
    import com.flashfla.net.events.LoginEvent;
    import com.flashfla.net.events.RoomJoinedEvent;
    import com.flashfla.net.events.GameResultsEvent;
    import flash.display.DisplayObjectContainer;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.Keyboard;
    import classes.Room;
    import classes.User;
    import classes.Gameplay;
    import com.flashfla.utils.StringUtil;

    public class MultiplayerChat extends Component
    {
        public var controlChat:TextArea;
        public var controlInput:InputText;

        private var chatText:String = "";
        private var canRedraw:Boolean = true;
        private var chatScroll:Boolean = false;
        private var chatScrollV:int;
        private var chatFrameDelay:int;

        public var room:Room;
        public var connection:Multiplayer;

        public function MultiplayerChat(parent:DisplayObjectContainer, roomValue:Room)
        {
            super(parent);
            this.room = roomValue;

            connection = MultiplayerSingleton.getInstance().connection;

            setSize(400, 300);

            controlChat = new TextArea();
            controlChat.editable = false;
            controlChat.html = true;
            addChild(controlChat);

            controlInput = new InputText();
            controlInput.addEventListener(KeyboardEvent.KEY_DOWN, onInputTextKeyDown);
            addChild(controlInput);

            connection.addEventListener(Multiplayer.EVENT_SERVER_MESSAGE, onServerMessageEvent);
            connection.addEventListener(Multiplayer.EVENT_XT_RESPONSE, onExtensionResponseEvent);
            connection.addEventListener(Multiplayer.EVENT_MESSAGE, onMessageEvent);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER, onRoomUserEvent);
            connection.addEventListener(Multiplayer.EVENT_CONNECTION, onConnectionEvent);
            connection.addEventListener(Multiplayer.EVENT_LOGIN, onLoginEvent);
            connection.addEventListener(Multiplayer.EVENT_ROOM_JOINED, onRoomJoinedEvent);
            connection.addEventListener(Multiplayer.EVENT_GAME_RESULTS, onGameResultsEvent);

            GlobalVariables.instance.gameMain.addEventListener(Main.EVENT_PANEL_SWITCHED, checkRedraw);

            buildContextMenu();

            resize();
        }

        private function onInputTextKeyDown(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.ENTER)
            {
                connection.sendMessage(room, controlInput.text);
                controlInput.text = "";
            }
            event.stopPropagation();
        }

        private function onServerMessageEvent(event:ServerMessageEvent):void
        {
            textAreaAddLine(textFormatServerMessage(event.user, event.message));
        }

        private function onExtensionResponseEvent(event:ExtensionResponseEvent):void
        {
            //textAreaAddLine(textFormatServerMessage(event.params.user, event.params.message));
            var data:Object = event.data;
            if (data.rid == room)
            {
                if (data._cmd == "html_message")
                {
                    textAreaAddLine(textFormatUserName(data.uid, ": ") + data.m);
                }
            }
        }

        private function onMessageEvent(event:MessageEvent):void
        {
            if (event.msgType == Multiplayer.MESSAGE_PUBLIC)
            {
                if (event.room == room)
                    textAreaAddLine(textFormatMessage(event.user, event.message));
            }
            else if (event.room == null || event.room == room)
                textAreaAddLine(textFormatPrivateMessageIn(event.user, event.message));
        }

        private function onRoomUserEvent(event:RoomUserEvent):void
        {
            // Broadcast join/left message in rooms, do not broadcast in lobby
            // Add "&& event.params.user.room != null" to omit "has left" messages
            if (room != null && room.name != "Lobby" && event.room == room)
                textAreaAddLine(textFormatUser(event.user, room.getUser(event.user.id) != null));
        }

        private function onConnectionEvent(event:ConnectionEvent):void
        {
            if (!connection.connected && !event.isSolo)
                textAreaAddLine(textFormatDisconnect());
        }

        private function onLoginEvent(event:LoginEvent):void
        {
            buildContextMenu();
        }

        private function onRoomJoinedEvent(event:RoomJoinedEvent):void
        {
            if (event.room == room && !event.isSolo)
                textAreaAddLine(textFormatJoin(room));
        }

        private function onGameResultsEvent(event:GameResultsEvent):void
        {
            if (event.room == room)
            {
                textAreaAddLine(textFormatGameResults(event));
            }
        }

        private function checkRedraw(event:Event):void
        {
            canRedraw = (GlobalVariables.instance.gameMain.activePanelName == Main.GAME_MENU_PANEL);
            redraw()
        }

        public function resize():void
        {
            controlInput.move(0, height - controlInput.height);
            controlInput.setSize(width, controlInput.height);

            controlChat.move(0, 0);
            controlChat.setSize(width, controlInput.y);
        }

        public function focus():void
        {
            if (stage)
            {
                stage.focus = controlInput.textField;
                controlInput.textField.setSelection(0, 0);
            }
        }

        public function buildContextMenu():void
        {
            if (connection.currentUser.isModerator)
            {
                var inputMenu:ContextMenu = new ContextMenu();
                var inputBroadcast:ContextMenuItem = new ContextMenuItem("Broadcast Server Message");
                inputBroadcast.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    if (controlInput.text.length > 0)
                    {
                        connection.sendServerMessage(controlInput.text);
                        //textAreaAddLine(textFormatServerMessage(room.user, controlInput.text));
                        controlInput.text = "";
                    }
                });
                inputMenu.customItems.push(inputBroadcast);
                inputBroadcast = new ContextMenuItem("Broadcast Room Message");
                inputBroadcast.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    if (controlInput.text.length > 0)
                    {
                        connection.sendServerMessage(controlInput.text, room);
                        //textAreaAddLine(textFormatServerMessage(room.user, controlInput.text));
                        controlInput.text = "";
                    }
                });
                inputMenu.customItems.push(inputBroadcast);
                if (connection.currentUser.isAdmin)
                {
                    inputBroadcast = new ContextMenuItem("Send HTML");
                    inputBroadcast.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                    {
                        if (controlInput.text.length > 0)
                        {
                            connection.sendHTMLMessage(controlInput.text, room);
                            controlInput.text = "";
                        }
                    });
                    inputMenu.customItems.push(inputBroadcast);
                }
                inputMenu.clipboardMenu = true;
                controlInput.contextMenu = controlInput.textField.contextMenu = inputMenu;
            }
            else
                controlInput.contextMenu = controlInput.textField.contextMenu = null;
        }

        public function textAreaAddLine(message:String):void
        {
            if (message == null)
            {
                return;
            }

            chatScrollV = controlChat.textField.scrollV;
            chatScroll ||= (chatScrollV == controlChat.textField.maxScrollV);
            chatFrameDelay = 0;

            chatText += (chatText.length == 0 ? "" : "\n");
            if (GlobalVariables.instance.activeUser.DISPLAY_MP_TIMESTAMP)
            {
                var date:Date = new Date();
                chatText += textFormatBold("[" + (date.hours == 0 ? 12 : (date.hours > 12 ? date.hours - 12 : date.hours)) + ":" + (date.minutes < 10 ? "0" : "") + date.minutes + (date.hours < 12 ? " AM" : " PM") + "] ");
            }
            chatText += message;
            redraw();
        }

        public function redraw(force:Boolean = false):void
        {
            if (force)
                canRedraw = true;
            if (!canRedraw)
                return;

            chatFrameDelay = 0;
            controlChat.text = textFormatFont(chatText, Style.fontName);
            controlChat.draw();
            controlChat.removeEventListener(Event.ENTER_FRAME, onRedrawFrame);
            controlChat.addEventListener(Event.ENTER_FRAME, onRedrawFrame);
        }

        private function onRedrawFrame(event:Event):void
        {
            if (++chatFrameDelay > 2)
            {
                if (chatScroll)
                {
                    chatScrollV = controlChat.textField.maxScrollV;
                    chatScroll = false;
                }
                controlChat.textField.scrollV = chatScrollV;
                controlChat.removeEventListener(Event.ENTER_FRAME, onRedrawFrame);
            }
        }

        public static function nameUser(user:User, format:Boolean = true):String
        {
            if (!user)
                return "";
            return (user.userLevel >= 0 ? textFormatLevel(user) : "") + (format ? textFormatUserName(user) : textEscape(user.name));
        }

        public static function textDullColour(colour:int, factor:Number):int
        {
            return (int(((colour & 0xFF0000) >> 16) * factor) << 16) | (int(((colour & 0x00FF00) >> 8) * factor) << 8) | int((colour & 0x0000FF) * factor);
        }

        public static function textFormatUserName(user:User, postfix:String = ""):String
        {
            var usercolour:int = user.userClass;
            if (!user.userColor)
                usercolour = user.userColor;
            var colour:String = textDullColour(Multiplayer.COLOURS[usercolour], 0.75).toString(16);
            if (user.variables.arc_colour != null)
                colour = user.variables.arc_colour;
            var userName:String = textEscape(user.name) + postfix;
            return textFormatColour(userName, "#" + colour);
        }

        public static function textFormatLevel(user:User):String
        {
            const level:int = user.userLevel;
            const color:int = GlobalVariables.getDivisionColor(level);
            const title:String = GlobalVariables.getDivisionTitle(level);
            const dulledColour:String = textDullColour(color, 1).toString(16);
            //return textFormatColour(" ", "#" + dulledColour);
            //return textFormatColour("D" + division + " [" + user.userLevel + "] ", "#" + dulledColour);
            return textFormatColour("Lv." + level + " (" + title + ") ", "#" + dulledColour);
        }

        public static function textFormatServerMessage(user:User, message:String):String
        {
            return textFormatColour(textFormatBold(textEscape("* Server Notice" + (user != null ? (" [" + user.name + "]") : "") + ": " + message)), "#901000");
        }

        public static function textFormatMessage(user:User, message:String):String
        {
            return textFormatUserName(user, ": ") + textEscape(message);
        }

        public static function textFormatPrivateMessageIn(user:User, message:String):String
        {
            return textFormatBold(textFormatColour(textEscape("PM << " + user.name + ":") + " ", "#009090")) + textEscape(message);
        }

        public static function textFormatPrivateMessageOut(user:User, message:String):String
        {
            return textFormatBold(textFormatColour(textEscape("PM >> " + user.name + ":") + " ", "#009090")) + textEscape(message);
        }

        public static function textFormatUser(user:User, isJoin:Boolean):String
        {
            return textFormatBold(textFormatColour("* " + nameUser(user, false) + (isJoin ? " has joined" : " has left"), isJoin ? "#009000" : "#900000"));
        }

        public static function textFormatJoin(room:Room):String
        {
            return textFormatColour("* Joined " + textEscape(room.name), "#009000");
        }

        public static function textFormatDisconnect():String
        {
            return textFormatColour("* Disconnected", "#900000");
        }

        public static function textFormatModeratorMute(user:User, minutes:int):String
        {
            return textFormatBold(textFormatColour("* " + nameUser(user, false) + " has been muted for " + minutes + " minutes.", "#901000"));
        }

        public static function textFormatModeratorBan(user:User, minutes:int):String
        {
            return textFormatBold(textFormatColour("* " + nameUser(user, false) + " has been banned for " + minutes + " minutes.", "#901000"));
        }

        public static function textFormatGameResults(event:GameResultsEvent):String
        {
            var room:Room = event.room;

            if (room == null)
            {
                return null;
            }

            if (event.initialPlayerCount <= 1)
            {
                return null;
            }

            var p1:User = room.getPlayer(1);
            var p2:User = room.getPlayer(2);

            // Player 1 or 2 missing
            if (!p1 && p2)
                return textFormatGameResultsSingle(room, 2);
            if (p1 && !p2)
                return textFormatGameResultsSingle(room, 1);

            // Compare scores
            var gameplayP1:Gameplay = p1.gameplay;
            var gameplayP2:Gameplay = p2.gameplay;

            var pa:Function = function(gameplay:Gameplay):String
            {
                return (gameplay.amazing + gameplay.perfect) + "-" + gameplay.good + "-" + gameplay.average + "-" + gameplay.miss + "-" + gameplay.boo + "-" + gameplay.maxCombo;
            }

            var winner:User = (gameplayP1.score > gameplayP2.score ? p1 : p2);
            var loser:User = (gameplayP1.score > gameplayP2.score ? p2 : p1);
            var isTie:Boolean = (gameplayP1.score == gameplayP2.score);

            var winnertext:String = winner.name + " (" + winner.gameplay.score + " " + pa(winner.gameplay) + ")";
            var losertext:String = loser.name + " (" + loser.gameplay.score + " " + pa(loser.gameplay) + ")";
            var songname:String = MultiplayerPlayer.nameSong(gameplayP1);
            return textFormatSize(textFormatBold(textFormatColour(textEscape("* " + songname + ": " + winnertext + (isTie ? " tied with " : " won against ") + losertext), "#189018")), "-2");
        }

        public static function textFormatGameResultsSingle(room:Room, playerIndex:Number):String
        {
            var player:User = room.getPlayer(playerIndex);
            return textFormatSize(textFormatBold(textFormatColour(textEscape("* Player has left, " + player.name + " has won."), "#189018")), "-2");
        }

        public static function textFormatColour(message:String, colour:String):String
        {
            return "<font color=\"" + colour + "\">" + message + "</font>";
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
            return StringUtil.htmlEscape(message);
        }
    }
}
