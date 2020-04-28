package menu
{
    import classes.BoxButton;
    import menu.mp.List;
    import menu.mp.ListEvent;
    import menu.mp.RoomPanel;
    import menu.mp.RoomUsers;
    import menu.mp.RoomChat;
    import menu.mp.RoomTab;
    import flash.display.Sprite;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import com.flashfla.components.Throbber;
    import arc.mp.MultiplayerConnection;
    import arc.mp.MultiplayerSingleton;
    import arc.mp.MultiplayerChat;

    public class MenuMultiplayer extends MenuPanel
    {
        private var sidebar:Sprite;
        private var lobbyTab:RoomTab;

        private var lobby:Sprite;
        private var roomPanels:Array;
        private var roomTabs:Array;

        private var chat:RoomChat;
        private var rooms:List;
        private var users:RoomUsers;

        private var connectionButton:BoxButton;
        private var createButton:BoxButton;
        private var throbber:Throbber;

        private var updateTimer:Timer;

        private var connection:MultiplayerConnection;

        public function MenuMultiplayer(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():void
        {
            connection = MultiplayerSingleton.getInstance().connection;

            roomTabs = new Array();

            lobby = new Sprite();
            lobby.x = 146;
            lobby.y = 56;
            addChild(lobby);
            var lw:int = 610;
            var lh:int = 388;

            rooms = new List(122, lh, "Rooms");
            rooms.addEventListener(List.ITEM_EVENT, onRoomClick);
            lobby.addChild(rooms);

            users = new RoomUsers(122, lh);
            users.x = lw - 122;
            lobby.addChild(users);

            chat = new RoomChat(users.x - rooms.width, lh);
            chat.x = rooms.width;
            lobby.addChild(chat);

            sidebar = new Sprite();
            sidebar.x = 12;
            sidebar.y = 122;
            addChild(sidebar);
            var sw:int = 124;
            var sh:int = 480 - sidebar.y;

            connectionButton = new BoxButton(sw, 29, "Connect");
            connectionButton.addEventListener(MouseEvent.CLICK, onConnectClick);
            sidebar.addChild(connectionButton);

            createButton = new BoxButton(sw, 29, "Create Room");
            createButton.x = 0;
            createButton.y = sh - 29;
            createButton.addEventListener(MouseEvent.CLICK, onCreateClick);
            sidebar.addChild(createButton);
            createButton.visible = false;

            lobbyTab = new RoomTab(this, lobby, sw, false);
            lobbyTab.y = connectionButton.y + connectionButton.height + 8;
            lobbyTab.addEventListener(MouseEvent.CLICK, onTabClick);
            sidebar.addChild(lobbyTab);
            lobbyTab.visible = false;

            throbber = new Throbber();
            throbber.x = sw / 2 - 16;
            throbber.y = 44;
            throbber.visible = false;
            sidebar.addChild(throbber);

            connection.addEventListener(MultiplayerConnection.EVENT_CONNECTION, onConnection);
            connection.addEventListener(MultiplayerConnection.EVENT_ROOM_LIST, onRoomList);
            connection.addEventListener(MultiplayerConnection.EVENT_ROOM_JOINED, onRoomJoined);

            updateTimer = new Timer(5000);
            updateTimer.addEventListener(TimerEvent.TIMER, onTimerTick);
        }

        private function showThrobber():void
        {
            throbber.visible = true;
            throbber.start();
        }

        private function hideThrobber():void
        {
            throbber.visible = false;
            throbber.stop();
        }

        private function closeRoom(tab:Object):void
        {

        }

        private function onCreateClick(event:Event):void
        {

        }

        private function onConnectClick(event:Event):void
        {
            if (connection.connected)
                connection.disconnect();
            else
            {
                connection.mode = MultiplayerConnection.GAME_R3;
                connection.connect();
                showThrobber();
            }
        }

        private function onRoomClick(event:ListEvent):void
        {
            if (event.originalType == MouseEvent.DOUBLE_CLICK)
                connection.joinRoom(event.item.data);
        }

        private function onTabClick(event:Event):void
        {
            var tab:RoomTab = event.currentTarget as RoomTab;
            if (tab != lobbyTab)
                lobbyTab.hide();
            for each (var t:RoomTab in roomTabs)
            {
                if (t != tab)
                    t.hide();
            }
            tab.show();
        }

        private function onTimerTick(event:Event):void
        {
            if (connection.connected && !MultiplayerSingleton.getInstance().gameplayPlayingStatus())
                connection.refreshRooms();
        }

        private function onConnection(event:SFSEvent):void
        {
            connectionButton.text = connection.connected ? "Disconnect" : "Connect";
            if (!connection.connected)
            {
                hideThrobber();
                createButton.visible = false;
                lobbyTab.visible = false;

                while (roomTabs.length)
                    closeRoom(roomTabs[0]);
            }
        }

        private function onRoomJoined(event:SFSEvent):void
        {
            if (event.params.room == connection.lobby)
            {
                lobbyTab.room = connection.lobby;
                lobbyTab.visible = true;
                lobbyTab.selected = true;
                createButton.visible = true;
                hideThrobber();
            }
            else
            {
                var room:RoomPanel = new RoomPanel(event.params.room, 610, 388);
                var roomTab:RoomTab = new RoomTab(this, room, 124, true);
                roomTab.addEventListener(MouseEvent.CLICK, onTabClick);
                roomTab.room = event.params.room;
                var lastTab:RoomTab = lobbyTab;
                if (roomTabs.length)
                    lastTab = roomTabs[roomTabs.length - 1];
                roomTab.y = lastTab.y + lastTab.height + 6;
                room.x = 146;
                room.y = 56;
                sidebar.addChild(roomTab);
                roomTabs.push(roomTab);
            }
        }

        private function onRoomList(event:SFSEvent):void
        {
            var items:Array = new Array();
            for each (var room:Object in connection.rooms)
            {
                if (room.isGame)
                    items.push({text: nameRoom(room), data: room});
            }
            items.sort(function(rd1:Object, rd2:Object):int
            {
                var r1:Object = rd1.data;
                var r2:Object = rd2.data;
                var v1:int = r1.userCount;
                var v2:int = r2.userCount;
                if (v1 < v2)
                    return 1;
                else if (v1 > v2)
                    return -1;
                v1 = r1.level;
                v2 = r2.level;
                if (v1 < v2)
                    return 1;
                else if (v1 > v2)
                    return -1;
                return r1.name.toLowerCase().localeCompare(r2.name.toLowerCase());
            });
            rooms.items = items;

            users.room = connection.lobby;
            chat.room = connection.lobby;
        }

        override public function stageAdd():void
        {
        }

        override public function stageRemove():void
        {
        }

        private function nameRoom(room:Object):String
        {
            var colour:String;
            if (room.userCount < room.maxUserCount)
            {
                if (room.userCount > 0)
                    colour = "#88fb88";
                else
                    colour = "#909090";
            }
            else if (room.spectatorCount >= room.maxSpectatorCount)
                colour = "#ff9595";
            else
            {
                var gameplay:Object = connection.getRoomGameplay(room);
                var p1:Object = gameplay["player1"];
                var p2:Object = gameplay["player2"];
                if (p1 && p2 && p1.status == p2.status && p1.status == MultiplayerConnection.STATUS_PLAYING)
                    colour = "#c0d8ff";
                else
                    colour = "#ffffff";
            }
            var roomName:String = (room.level ? "[" + room.level + "] " : "") + room.name;
            return MultiplayerChat.textFormatColour(MultiplayerChat.textEscape((room.isPrivate ? "!" : "") + roomName), colour) + MultiplayerChat.textFormatSize(" (" + room.spectatorCount + ")", "-1");
        }
    }
}
