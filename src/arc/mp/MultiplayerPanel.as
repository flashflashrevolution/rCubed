package arc.mp
{
    import arc.ArcGlobals;
    import arc.mp.ListItemDoubleClick;
    import arc.mp.MultiplayerChat;
    import arc.mp.MultiplayerUsers;
    import classes.Alert;
    import classes.Room;
    import classes.User;
    import classes.ui.BoxButton;
    import classes.ui.MPCreateRoomPrompt;
    import classes.ui.Prompt;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import com.bit101.components.List;
    import com.bit101.components.PushButton;
    import com.bit101.components.Style;
    import com.bit101.components.Window;
    import com.flashfla.net.Multiplayer;
    import com.flashfla.net.events.ConnectionEvent;
    import com.flashfla.net.events.LoginEvent;
    import com.flashfla.net.events.RoomJoinedEvent;
    import com.flashfla.net.events.RoomLeftEvent;
    import com.flashfla.net.events.RoomListEvent;
    import com.flashfla.net.events.RoomUpdateEvent;
    import com.flashfla.net.events.RoomUserStatusEvent;
    import com.flashfla.net.events.ServerMessageEvent;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.utils.Timer;
    import menu.MenuPanel;

    public class MultiplayerPanel extends MenuPanel
    {
        private var controlChat:MultiplayerChat;
        private var controlUsers:MultiplayerUsers;
        private var controlRooms:List;
        private var controlCreate:PushButton;

        private var textLogin:Text;
        private var buttonMP:BoxButton;
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
                connection.connect();
            }
            else
            {
                textLogin = new Text(this, 0, 0, "Please Login or Register");
                textLogin.x = Main.GAME_WIDTH / 2 - textLogin.width / 2;
                textLogin.y = Main.GAME_HEIGHT / 2 - textLogin.height * 3 / 2;
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
            controlRooms.addEventListener(MouseEvent.DOUBLE_CLICK, onRoomDoubleClick);
            window.addChild(controlRooms);
            buildContextMenu();

            controlChat = new MultiplayerChat(window, connection.lobby);
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
            controlCreate.addEventListener(MouseEvent.CLICK, onCreateRoomClick);
            window.addChild(controlCreate);

            window.width = controlUsers.x + controlUsers.width;
            window.height = window.titleBar.height + controlChat.y + controlChat.height;

            connection.addEventListener(Multiplayer.EVENT_SERVER_MESSAGE, onServerMessageEvent);
            connection.addEventListener(Multiplayer.EVENT_CONNECTION, onConnectionEvent);
            connection.addEventListener(Multiplayer.EVENT_LOGIN, onLoginEvent);
            connection.addEventListener(Multiplayer.EVENT_ROOM_JOINED, onRoomJoinedEvent);
            connection.addEventListener(Multiplayer.EVENT_ROOM_LEFT, onRoomLeftEvent);
            connection.addEventListener(Multiplayer.EVENT_ROOM_LIST, onRoomListEvent);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER_STATUS, onRoomUserStatusEvent);
            connection.addEventListener(Multiplayer.EVENT_ROOM_UPDATE, onRoomUpdateEvent);

            window.addEventListener(Event.CLOSE, onCloseEvent);

            buttonMP = new BoxButton(this, 5, Main.GAME_HEIGHT - 30, 130, 25, "Connect", 12, onClickMP);
            showButton(buttonMP, false);

            buttonDisconnect = new BoxButton(null, buttonMP.x, buttonMP.y, buttonMP.width, buttonMP.height, "Disconnect", 12, onClickDisconnect);

            throbber = new Throbber();
            throbber.x = Main.GAME_WIDTH / 2;
            throbber.y = Main.GAME_HEIGHT / 2;
            showThrobber();
            addChild(throbber);

            updateTimer = new Timer(5000);
            updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer);
        }

        public function get currentUser():User
        {
            return connection.currentUser;
        }

        private function onRoomDoubleClick(event:MouseEvent):void
        {
            if (controlRooms.selectedItem != null && controlRooms.selectedItem.data != null)
            {
                var room:Room = controlRooms.selectedItem.data;
                joinRoom(room, true);
            }
        }

        private function onCreateRoomClick(event:MouseEvent):void
        {
            function e_createRoom(roomName:String, password:String):void
            {
                connection.createRoom(roomName, password);
            }

            new MPCreateRoomPrompt(this, 320, 120, e_createRoom);
        }

        private function onServerMessageEvent(event:ServerMessageEvent):void
        {
            Alert.add("Server Message: " + event.message);
        }

        private function onConnectionEvent(event:ConnectionEvent):void
        {
            showButton(buttonDisconnect, connection.connected);
            showButton(buttonMP, !connection.connected);
            if (!connection.connected)
                hideThrobber();
        }

        private function onLoginEvent(event:LoginEvent):void
        {
            buildContextMenu();
        }

        private function onRoomJoinedEvent(event:RoomJoinedEvent):void
        {
            if (event.room == connection.lobby)
            {
                openWindow();
                updateWindowTitle(event.room);
                hideThrobber();
            }
            else
            {
                updateRoomPanel(event.room);
                new MultiplayerRoom(this, event.room);
            }
        }

        private function onRoomLeftEvent(event:RoomLeftEvent):void
        {
            if (event.room == connection.lobby)
            {
                closeWindow();
            }
        }

        private function onRoomListEvent(event:RoomListEvent):void
        {
            updateRooms();

            controlChat.room = connection.lobby;
            controlUsers.room = connection.lobby;
        }

        private function onRoomUserStatusEvent(event:RoomUserStatusEvent):void
        {
            updateRoomPanel(event.room);
        }

        private function onRoomUpdateEvent(event:RoomUpdateEvent):void
        {
            if (event.roomList == true)
                updateRoomPanel(event.room);
        }

        private function onCloseEvent(event:Event):void
        {
            if (!connection.connected)
            {
                closeWindow();
                return;
            }
            var inGame:Boolean = false;
            for each (var room:Room in connection.rooms)
            {
                if (room.hasUser(currentUser) && room != connection.lobby)
                    inGame = true;
            }
            if (inGame)
                connection.leaveRoom(connection.lobby);
            else
            {
                closeWindow();
                connection.disconnect();
            }
        }

        private function onClickMP(event:MouseEvent):void
        {
            if (connection.connected)
                connection.disconnect();

            connection.connect();
            showThrobber();
        }

        private function onClickDisconnect(event:MouseEvent):void
        {
            if (connection.connected)
                connection.disconnect();
        }

        private function onClickJoinLobby(event:MouseEvent):void
        {
            connection.joinLobby();
        }

        private function onUpdateTimer(event:TimerEvent):void
        {
            if (connection.connected)
            {
                updateWindowTitle(connection.lobby);

                if (!MultiplayerSingleton.getInstance().gameplayPlayingStatus())
                    connection.refreshRooms();
            }
        }

        public function buildContextMenu():void
        {
            var roomMenu:ContextMenu = new ContextMenu();
            var roomItem:ContextMenuItem = new ContextMenuItem("Spectate");
            roomItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
            {
                var item:Object = event.mouseTarget["data"];

                if (!item)
                    return;

                var room:Room = item["data"];
                joinRoom(room, false);
            });
            roomMenu.customItems.push(roomItem);
            if (currentUser.isModerator)
            {
                roomItem = new ContextMenuItem("Nuke Room");
                roomItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    var item:Object = event.mouseTarget["data"];

                    if (!item)
                        return;

                    var room:Room = item["data"];
                    connection.nukeRoom(room);
                });
                roomMenu.customItems.push(roomItem);
            }
            controlRooms.contextMenu = roomMenu;
        }

        private function joinRoom(room:Room, asPlayer:Boolean):void
        {
            function e_joinRoomPassword(password:String):void
            {
                connection.joinRoom(room, asPlayer, password);
            }

            if (room.isPrivate)
            {
                new Prompt(this, 320, "Password: " + room.name, 100, "SUBMIT", e_joinRoomPassword, true);
            }
            else
            {
                connection.joinRoom(room, asPlayer);
            }
        }

        private function updateRoomPanel(room:Room):void
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

        /**
         * Updates the rooms list
         */
        private function updateRooms():void
        {
            var items:Array = [];
            for each (var room:Room in connection.rooms)
            {
                if (room.isGameRoom)
                    items.push({label: nameRoom(room), labelhtml: true, data: room});
            }
            updateWindowTitle(connection.lobby);
            controlRooms.items = items;
            controlRooms.listItemClass = controlRooms.listItemClass;
        }

        public function updateWindowTitle(room:Room):void
        {
            if (room != null)
                window.title = Multiplayer.GAME_VERSION + " " + room.name + " - Rooms: " + (connection.rooms.length - 2) + " - Players: " + room.userCount;
        }

        private function nameRoom(room:Room):String
        {
            const level:int = room.level;
            const spectatorString:String = (room.specCount > 0) ? "+" + room.specCount + " " : "";
            const roomPopulationString:String = MultiplayerChat.textFormatSize(room.userCount + "/2 " + spectatorString, "-1");
            const isPrivateString:String = (room.isPrivate ? "!" : "");
            
            if (room.playerCount > 0 && level != -1)
            {
                const color:int = ArcGlobals.getDivisionColor(level);
                const titleString:String = ArcGlobals.getDivisionTitle(level);
                const dulledColour:String = MultiplayerChat.textDullColour(color, 1).toString(16);
                const titlePrefix:String = "(" + titleString + ")";

                return roomPopulationString + MultiplayerChat.textFormatColour(isPrivateString + titlePrefix, "#" + dulledColour) + " " + MultiplayerChat.textEscape(room.name);
            }
            else
            {
                return roomPopulationString + " " + MultiplayerChat.textEscape(isPrivateString + room.name);
            }
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
                buttonMP.visible = show;
            if (buttonDisconnect != null)
                buttonDisconnect.visible = show;
            if (textLogin != null)
                textLogin.visible = show;
            if (window != null)
                window.visible = show;
        }

        private function forEachRoom(func:Function):void
        {
            for (var i:int = 0; i < numChildren; i++)
            {
                var container:Object = getChildAt(i);
                if (container is MultiplayerRoom)
                    func(container);
            }
        }

        public function setRoomsVisibility(visible:Boolean = false):void
        {
            forEachRoom(function(room:MultiplayerRoom):void
            {
                room.visible = visible;
                if (visible)
                    room.redraw();
            });
        }

        public function hideRoom(room:Room, show:Boolean = false):void
        {
            forEachRoom(function(mproom:MultiplayerRoom):void
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
