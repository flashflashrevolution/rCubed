package arc.mp
{
    import arc.mp.MultiplayerChat;
    import arc.mp.MultiplayerPlayer;
    import arc.mp.MultiplayerUsers;
    import com.bit101.components.PushButton;
    import com.bit101.components.Window;
    import com.flashfla.net.Multiplayer;
    import com.flashfla.net.events.GameStartEvent;
    import com.flashfla.net.events.ConnectionEvent;
    import com.flashfla.net.events.RoomLeftEvent;
    import com.flashfla.net.events.RoomUserEvent;
    import com.flashfla.net.events.RoomUserStatusEvent;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import menu.MainMenu;
    import classes.Alert;
    import classes.Language;
    import classes.Room;
    import classes.User;

    public class MultiplayerRoom extends Window
    {
        public var _lang:Language = Language.instance;

        private var controlChat:MultiplayerChat;
        private var controlUsers:MultiplayerUsers;
        private var controlSpectate:PushButton;
        private var controlState:PushButton;
        private var controlPlayer1:MultiplayerPlayer;
        private var controlPlayer2:MultiplayerPlayer;

        private var connection:Multiplayer;

        public var room:Room;

        public function MultiplayerRoom(parent:DisplayObjectContainer, room:Room)
        {
            super(parent);

            this.room = room;
            connection = room.connection;
            title = room.name;

            // Player 1 display
            controlPlayer1 = new MultiplayerPlayer(this, room, 1);
            controlPlayer1.move(0, 0);

            // Player 2 display
            controlPlayer2 = new MultiplayerPlayer(this, room, 2);
            controlPlayer2.move(controlPlayer1.x + controlPlayer1.width, controlPlayer1.y);

            // Room chat display
            controlChat = new MultiplayerChat(this, room);
            controlChat.move(controlPlayer1.x, controlPlayer1.y + controlPlayer1.height);
            controlChat.setSize(controlPlayer2.x + controlPlayer2.width - controlPlayer1.x, controlPlayer1.height * 1.4);
            controlChat.resize();
            controlChat.textAreaAddLine(MultiplayerChat.textFormatJoin(room));

            // Room user list display
            controlUsers = new MultiplayerUsers(this, room, parent, controlChat);
            controlUsers.move(controlChat.x + controlChat.width, controlPlayer1.y);
            controlUsers.setSize(controlUsers.width - 10, controlChat.y + controlChat.height - controlPlayer1.y - controlChat.controlInput.height);
            controlUsers.resize();
            controlUsers.updateUsers();

            // Player spectate state button
            controlSpectate = new PushButton();
            controlSpectate.label = room.isPlayer(currentUser) ? "Spectate" : (room.playerCount < 2 ? "Join Game" : "Cannot Join Game");
            controlSpectate.setSize(controlUsers.width, controlChat.controlInput.height);
            controlSpectate.move(controlUsers.x, controlUsers.y + controlUsers.height);
            controlSpectate.addEventListener(MouseEvent.CLICK, onSpectateButtonClick);
            addChild(controlSpectate);

            // Player state button
            controlState = new PushButton();
            controlState.label = room.isPlayer(currentUser) ? "Ready" : (currentUser.wantsToWatch ? "Stop Spectating" : "Start Spectating");
            controlState.setSize(controlUsers.width, controlChat.controlInput.height);
            controlState.move(controlUsers.x, controlUsers.y + controlUsers.height - controlChat.controlInput.height);
            controlState.addEventListener(MouseEvent.CLICK, onStateButtonClick);
            addChild(controlState);

            // Add listeners to update this display
            connection.addEventListener(Multiplayer.EVENT_GAME_START, onGameStart);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER_STATUS, onRoomUserStatus);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER, onRoomUser);
            connection.addEventListener(Multiplayer.EVENT_CONNECTION, onConnectionUpdate);
            connection.addEventListener(Multiplayer.EVENT_ROOM_LEFT, onLeftRoom);

            // Set display layout and properties
            hasCloseButton = true;
            hasMinimizeButton = true;
            setSize(controlUsers.x + controlUsers.width, titleBar.height + controlChat.y + controlChat.height);
            move(parent.width / 2 - width / 2, parent.height / 2 - height / 2);
            controlChat.focus();

            // Listener for closing the display with the top right Close button
            addEventListener(Event.CLOSE, onCloseRoom);
        }

        public function get currentUser():User
        {
            return connection.currentUser;
        }

        public function redraw():void
        {
            controlPlayer1.redraw(true);
            controlPlayer2.redraw(true);
            controlChat.redraw(true);
        }

        private function onCloseRoom(event:Event):void
        {
            if (room == null || !room.hasUser(currentUser))
            {
                parent.removeChild(this);
                return;
            }

            var inGame:Boolean = false;
            for each (var _room:Room in connection.rooms)
            {
                if (_room.hasUser(currentUser) && _room != room)
                    inGame = true;
            }
            if (inGame)
                connection.leaveRoom(room)
            else
            {
                connection.joinLobby();
                connection.leaveRoom(room)
            }
        }

        private function onSpectateButtonClick(event:MouseEvent):void
        {
            if (connection.switchRole(room))
                updateRoomDisplay();
        }

        private function onStateButtonClick(event:MouseEvent):void
        {
            if (room.isPlayer(currentUser))
            {
                if (currentUser.gameplay.status == Multiplayer.STATUS_LOADED)
                {
                    currentUser.gameplay.status = Multiplayer.STATUS_READY;
                    connection.sendCurrentUserStatus(room);
                }
                else if (currentUser.gameplay.status == Multiplayer.STATUS_READY)
                {
                    // Left intentionally empty
                }
                else
                {
                    Alert.add(_lang.string("mp_load_song_before_ready"));
                }
            }
            else
            {
                currentUser.wantsToWatch = !currentUser.wantsToWatch;
                Alert.add(currentUser.wantsToWatch ? "Now spectating games in " + room.name : "No longer spectating games in " + room.name);
                if (currentUser.wantsToWatch && room.isAllPlayersInStatus(Multiplayer.STATUS_PLAYING) && room.isAllPlayersSameSong())
                {
                    room.songInfo = room.getPlayersSong()
                    connection.lastRoomGamePlayerCount = room.playerCount;
                    MultiplayerSingleton.getInstance().spectateGame(room);
                }
            }
            updateRoomDisplay();

        }

        private function onGameStart(event:GameStartEvent):void
        {
            // If the current room has started gameplay, enter spectating view
            if (event.room == room && GlobalVariables.instance.gameMain.activePanel is MainMenu)
            {
                connection.lastRoomGamePlayerCount = room.playerCount;
                MultiplayerSingleton.getInstance().spectateGame(room);
            }
        }

        private function onConnectionUpdate(event:ConnectionEvent):void
        {
            if (!connection.connected)
                room = null;
        }

        private function onLeftRoom(event:RoomLeftEvent):void
        {
            if (event.room == room)
            {
                parent.removeChild(this);
                room = null;
            }
        }

        private function onRoomUserStatus(event:RoomUserStatusEvent):void
        {
            if (event.room == room)
                updateRoomDisplay();
        }

        private function onRoomUser(event:RoomUserEvent):void
        {
            if (event.room == room)
                updateRoomDisplay();
        }

        private function updateRoomDisplay():void
        {
            controlSpectate.label = room.isPlayer(currentUser) ? "Spectate" : (room.playerCount < 2 ? "Join Game" : "Cannot Join Game");
            controlState.label = room.isPlayer(currentUser) ? "Ready" : (currentUser.wantsToWatch ? "Stop Spectating" : "Start Spectating");
        }
    }
}
