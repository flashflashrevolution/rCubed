package arc.mp
{
    import arc.ArcGlobals;
    import arc.mp.ListItemDoubleClick;
    import arc.mp.MultiplayerChat;
    import arc.mp.MultiplayerPrompt;
    import arc.mp.MultiplayerUsers;
    import classes.BoxButton;
    import classes.Text;
    import com.bit101.components.List;
    import com.bit101.components.PushButton;
    import com.bit101.components.Style;
    import com.bit101.components.Window;
    import com.flashfla.components.Throbber;
    import com.flashfla.net.Multiplayer;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.utils.Timer;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import menu.MenuPanel;

    public class MultiplayerPanel extends MenuPanel
    {
        private var controlChat:MultiplayerChat;
        private var controlUsers:MultiplayerUsers;
        private var controlRooms:List;
        private var controlCreate:PushButton;

        private var textLogin:Text;
        private var buttonMP:BoxButton;
        private var buttonLegacy:BoxButton;
        private var buttonVelocity:BoxButton;
        private var buttonDisconnect:BoxButton;
        private var buttonLobby:BoxButton;
        private var throbber:Throbber;

        private var updateTimer:Timer;

        private var connection:Multiplayer;

        public var window:Window;

        public function MultiplayerPanel(menuParent:MenuPanel)
        {
            super(menuParent);

            var self:MultiplayerPanel = this;

            connection = MultiplayerSingleton.getInstance().connection;
            // Connect immediately if logged in
            if (!GlobalVariables.instance.activeUser.isGuest && GlobalVariables.instance.activeUser.id != 2)
            {
                connection.mode = Multiplayer.GAME_R3;
                connection.connect();
            }
            else
            {
                textLogin = new Text("Please Login or Register");
                textLogin.x = Main.GAME_WIDTH / 2 - textLogin.width / 2;
                textLogin.y = Main.GAME_HEIGHT / 2 - textLogin.height * 3 / 2;
                addChild(textLogin);
                return;
            }

            Style.fontSize = ArcGlobals.instance.configMPSize;

            window = new Window();
            window.title = "Lobby";
            window.hasCloseButton = true;
            window.hasMinimizeButton = false;

            controlRooms = new List();
            controlRooms.listItemClass = ListItemDoubleClick;
            controlRooms.autoHideScrollBar = true;
            controlRooms.move(0, 0);
            controlRooms.setSize(200, 350);
            controlRooms.addEventListener(MouseEvent.DOUBLE_CLICK, function(event:MouseEvent):void
            {
                if (controlRooms.selectedItem != null && controlRooms.selectedItem.data != null)
                {
                    var room:Object = controlRooms.selectedItem.data;
                    joinRoom(room, room.playerCount < room.maxPlayerCount);
                }
            });
            window.addChild(controlRooms);
            buildContextMenu();

            controlChat = new MultiplayerChat(window, connection.lobby, this);
            controlChat.move(controlRooms.x + controlRooms.width, controlRooms.y);
            controlChat.setSize(365, controlRooms.height + controlChat.controlInput.height);
            controlChat.resize();

            controlUsers = new MultiplayerUsers(window, connection.lobby, this, controlChat);
            controlUsers.move(controlChat.x + controlChat.width, controlChat.y);
            controlUsers.setSize(controlUsers.width, controlChat.height);
            controlUsers.resize();

            controlCreate = new PushButton();
            controlCreate.label = "Create Room";
            controlCreate.setSize(controlRooms.width, controlChat.controlInput.height);
            controlCreate.move(controlRooms.x, controlRooms.y + controlRooms.height);
            controlCreate.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
            {
                var prompt:MultiplayerRoomCreatePrompt = new MultiplayerRoomCreatePrompt(self, "Create Room");
                prompt.addEventListener(MultiplayerRoomCreatePrompt.EVENT_SEND, function(subevent:SFSEvent):void
                {
                    connection.createRoom(subevent.params.room, subevent.params.password);
                });
            });
            window.addChild(controlCreate);

            window.width = controlUsers.x + controlUsers.width;
            window.height = window.titleBar.height + controlChat.y + controlChat.height;

            connection.addEventListener(Multiplayer.EVENT_SERVER_MESSAGE, function(event:SFSEvent):void
            {
                GlobalVariables.instance.gameMain.addAlert("Server Message: " + event.params.message);
            });
            connection.addEventListener(Multiplayer.EVENT_CONNECTION, function(event:SFSEvent):void
            {
                showButton(buttonDisconnect, connection.connected);
                showButton(buttonMP, !connection.connected);
                showButton(buttonLobby, false);
                if (!connection.connected)
                    hideThrobber();
            });
            connection.addEventListener(Multiplayer.EVENT_LOGIN, function(event:SFSEvent):void
            {
                buildContextMenu();
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_JOINED, function(event:SFSEvent):void
            {
                if (event.params.room == connection.lobby)
                {
                    showButton(buttonLobby, false);
                    openWindow();
                    updateWindowTitle(event.params.room);
                    hideThrobber();
                }
                else
                {
                    new MultiplayerRoom(self, event.params.room);
                    updateRoom(event.params.room);
                }
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_LEFT, function(event:SFSEvent):void
            {
                if (event.params.room == connection.lobby)
                {
                    showButton(buttonLobby, true);
                    closeWindow();
                }
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_LIST, function(event:SFSEvent):void
            {
                updateRooms();

                controlChat.room = connection.lobby;
                controlUsers.room = connection.lobby;
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER_STATUS, function(event:SFSEvent):void
            {
                updateRoom(event.params.room);
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_UPDATE, function(event:SFSEvent):void
            {
                if (event.params.roomList == true)
                    updateRoom(event.params.room);
            });
            window.addEventListener(Event.CLOSE, function(event:Event):void
            {
                if (!connection.connected)
                {
                    closeWindow();
                    return;
                }
                var inGame:Boolean = false;
                for each (var room:Object in connection.rooms)
                {
                    if (room.isJoined && room != connection.lobby)
                        inGame = true;
                }
                if (inGame)
                    connection.leaveRoom(connection.lobby);
                else
                {
                    closeWindow();
                    connection.disconnect();
                }
            });

            buttonMP = new BoxButton(130, 25, "Connect");
            buttonMP.x = 5;
            buttonMP.y = Main.GAME_HEIGHT - 30;
            buttonMP.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
            {
                if (connection.connected)
                    connection.disconnect();
                connection.mode = Multiplayer.GAME_R3;
                connection.connect();
                showThrobber();
            });
            addChild(buttonMP);
            showButton(buttonMP, false);

            buttonLegacy = new BoxButton(140, 40, "Connect to Legacy");
            buttonLegacy.x = buttonMP.x;
            buttonLegacy.y = buttonMP.y + buttonMP.height + 10;
            buttonLegacy.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
            {
                if (connection.connected)
                    connection.disconnect();
                connection.mode = Multiplayer.GAME_LEGACY;
                connection.connect();
                showThrobber();
            });
            addChild(buttonLegacy);
            showButton(buttonLegacy, false);

            buttonVelocity = new BoxButton(buttonLegacy.width, buttonLegacy.height, "Connect to Velocity");
            buttonVelocity.x = buttonLegacy.x;
            buttonVelocity.y = buttonLegacy.y + buttonLegacy.height + 10;
            buttonVelocity.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
            {
                if (connection.connected)
                    connection.disconnect();
                connection.mode = Multiplayer.GAME_VELOCITY;
                connection.connect();
                showThrobber();
            });
            addChild(buttonVelocity);
            showButton(buttonVelocity, false);

            buttonDisconnect = new BoxButton(buttonMP.width, buttonMP.height, "Disconnect");
            buttonDisconnect.x = buttonMP.x;
            buttonDisconnect.y = buttonMP.y;
            buttonDisconnect.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
            {
                if (connection.connected)
                    connection.disconnect();
            });

            buttonLobby = new BoxButton(buttonLegacy.width, buttonLegacy.height, "Join Lobby");
            buttonLobby.x = buttonDisconnect.x;
            buttonLobby.y = buttonDisconnect.y + buttonDisconnect.height + 10;
            buttonLobby.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
            {
                connection.joinLobby();
            });

            throbber = new Throbber();
            throbber.x = Main.GAME_WIDTH / 2;
            throbber.y = Main.GAME_HEIGHT / 2;
            showThrobber();
            addChild(throbber);

            updateTimer = new Timer(5000);
            updateTimer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void
            {
                if (connection.connected)
                {
                    updateWindowTitle(connection.lobby);

                    if (!MultiplayerSingleton.getInstance().gameplayPlayingStatus())
                        connection.refreshRooms();
                }
            });
        }

        public function buildContextMenu():void
        {
            var roomMenu:ContextMenu = new ContextMenu();
            var roomItem:ContextMenuItem = new ContextMenuItem("Spectate");
            roomItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
            {
                var room:Object = event.mouseTarget["data"]["data"];
                joinRoom(room, false);
            });
            roomMenu.customItems.push(roomItem);
            if (connection.currentUser.isModerator)
            {
                roomItem = new ContextMenuItem("Nuke Room");
                roomItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    var room:Object = event.mouseTarget["data"]["data"];
                    connection.nukeRoom(room);
                });
                roomMenu.customItems.push(roomItem);
            }
            controlRooms.contextMenu = roomMenu;
        }

        private function joinRoom(room:Object, player:Boolean):void
        {
            if (room.isPrivate)
            {
                var password:MultiplayerPrompt = new MultiplayerPrompt(this, "Password: " + room.name);
                password.controlInput.password = true;
                password.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:SFSEvent):void
                {
                    connection.joinRoom(room, player, subevent.params.value);
                });
            }
            else
                connection.joinRoom(room, player);
        }

        private function updateRoom(room:Object):void
        {
            if (window.parent == null)
                return;

            for each (var item:Object in controlRooms.items)
            {
                if (item.data == room)
                {
                    item.label = nameRoom(room);
                    controlRooms.items = controlRooms.items;
                    break;
                }
            }
        }

        private function updateRooms():void
        {
            var items:Array = new Array();
            for each (var room:Object in connection.rooms)
            {
                if (room.isGame)
                    items.push({label: nameRoom(room), labelhtml: true, data: room});
            }
            updateWindowTitle(connection.lobby);
            controlRooms.items = items;
            controlRooms.listItemClass = controlRooms.listItemClass;
        }

        public function updateWindowTitle(room:Object):void
        { // Minus 2 Rooms due to The Entrence (Fake) and Lobby
            window.title = Multiplayer.GAME_VERSIONS[connection.mode] + " " + room.name + " - Rooms: " + (connection.rooms.length - 2) + " - Players: " + room.playerCount;
        }

        private function nameRoom(room:Object):String
        {
            /*
               var colour:String;
               if (room.playerCount < room.maxPlayerCount) {
               if (room.playerCount > 0)
               colour = "#109010";
               else
               colour = "#909090";
               } else if (room.spectatorCount >= room.maxSpectatorCount)
               colour = "#a81818";
               else {
               var gameplay:Object = connection.getRoomGameplay(room);
               var p1:Object = gameplay["player1"];
               var p2:Object = gameplay["player2"];
               if (p1 && p2 && p1.status == p2.status && p1.status == Multiplayer.STATUS_PLAYING)
               colour = "#101090";
               else
               colour = "#101010";
               }
             */
            const level:int = room.level;
            const color:int = ArcGlobals.getDivisionColor(level);
            const title:String = ArcGlobals.getDivisionTitle(level);

            const dulledColour:String = MultiplayerChat.textDullColour(color, 1).toString(16);
            const roomName:String = "(" + title + ")";
            const spectatorString:String = (room.spectatorCount > 0) ? "+" + room.spectatorCount + " " : "";

            return MultiplayerChat.textFormatSize(room.playerCount + "/2 " + spectatorString, "-1") + MultiplayerChat.textFormatColour(MultiplayerChat.textEscape((room.isPrivate ? "!" : "") + roomName), "#" + dulledColour) + " " + room.name;
        }

        public function setParent(value:MenuPanel):void
        {
            super.my_Parent = value;
        }

        private function showButton(button:BoxButton, show:Boolean):void
        {
            if (button == null)
                return;

            if (button.parent == null && show)
                addChild(button);
            else if (button.parent == this && !show)
                removeChild(button);
        }

        public function hideBackground(show:Boolean = false):void
        {
            if (buttonMP != null)
            {
                buttonMP.visible = show;
                buttonLegacy.visible = show;
                buttonVelocity.visible = show;
                buttonDisconnect.visible = show;
                buttonLobby.visible = show;
            }
            if (textLogin != null)
                textLogin.visible = show;
            if (window != null)
                window.visible = show;
        }

        private function foreachroom(foreach:Function):void
        {
            for (var i:int = 0; i < numChildren; i++)
            {
                var room:Object = getChildAt(i);
                if (room is MultiplayerRoom)
                    foreach(room);
            }
        }

        public function hideRooms(show:Boolean = false):void
        {
            foreachroom(function(room:MultiplayerRoom):void
            {
                room.visible = show;
                if (show)
                    room.redraw();
            });
        }

        public function hideRoom(room:Object, show:Boolean = false):void
        {
            foreachroom(function(mproom:MultiplayerRoom):void
            {
                if (mproom.room == room)
                {
                    mproom.visible = show;
                    if (show)
                        mproom.redraw();
                }
            });
        }

        public function openWindow():void
        {
            if (window.parent == null)
                closeWindow();
            window.x = 5; // Main.GAME_WIDTH / 2 - window.width / 2.6;
            window.y = 50; // Main.GAME_HEIGHT / 2 - window.height / 1.75;

            addChild(window);
            controlChat.redraw();
            controlChat.focus();
            updateTimer.start();
        }

        public function closeWindow():void
        {
            if (window.parent == this)
                removeChild(window);
            updateTimer.stop();
        }

        private function showThrobber():void
        {
            if (throbber != null)
            {
                throbber.visible = true;
                throbber.start();
            }
        }

        private function hideThrobber():void
        {
            if (throbber != null)
            {
                throbber.visible = false;
                throbber.stop();
            }
        }
    }
}
