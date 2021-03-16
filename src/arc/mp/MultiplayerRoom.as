package arc.mp
{
    import arc.mp.MultiplayerChat;
    import arc.mp.MultiplayerPlayer;
    import arc.mp.MultiplayerUsers;
    import com.bit101.components.PushButton;
    import com.bit101.components.Window;
    import com.flashfla.net.Multiplayer;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import menu.MainMenu;
    import com.flashfla.net.events.GameStartEvent;
    import com.flashfla.net.events.ConnectionEvent;
    import com.flashfla.net.events.RoomLeftEvent;
    import com.flashfla.net.events.RoomUpdateEvent;

    public class MultiplayerRoom extends Window
    {
        public var controlChat:MultiplayerChat;
        private var controlUsers:MultiplayerUsers;
        private var controlSpectate:PushButton;
        private var controlPlayer1:MultiplayerPlayer;
        private var controlPlayer2:MultiplayerPlayer;

        private var connection:Multiplayer;
        private var spectating:Boolean;

        public var room:Object;

        public function MultiplayerRoom(parent:DisplayObjectContainer, roomValue:Object)
        {
            super(parent);

            this.room = roomValue;
            this.spectating = false;
            var self:MultiplayerRoom = this;

            connection = room.connection;
            title = room.name;

            controlPlayer1 = new MultiplayerPlayer(this, room, 1);
            controlPlayer1.move(0, 0);

            controlPlayer2 = new MultiplayerPlayer(this, room, 2);
            controlPlayer2.move(controlPlayer1.x + controlPlayer1.width, controlPlayer1.y);

            controlChat = new MultiplayerChat(this, room, parent);
            controlChat.move(controlPlayer1.x, controlPlayer1.y + controlPlayer1.height);
            controlChat.setSize(controlPlayer2.x + controlPlayer2.width - controlPlayer1.x, controlPlayer1.height * 1.4);
            controlChat.resize();

            controlUsers = new MultiplayerUsers(this, room, parent, controlChat);
            controlUsers.move(controlChat.x + controlChat.width, controlPlayer1.y);
            controlUsers.setSize(controlUsers.width - 10, controlChat.y + controlChat.height - controlPlayer1.y - controlChat.controlInput.height);
            controlUsers.resize();
            controlUsers.updateUsers();

            controlSpectate = new PushButton();
            controlSpectate.label = room.user.isPlayer ? "Spectate" : (room.playerCount < 2 ? "Join Game" : "Start Spectating");
            controlSpectate.setSize(controlUsers.width, controlChat.controlInput.height);
            controlSpectate.move(controlUsers.x, controlUsers.y + controlUsers.height);
            controlSpectate.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void
            {
                if (!room)
                    return;
                if (room.user.isPlayer || room.playerCount < 2)
                {
                    connection.switchRole(room);
                    spectating = false;
                }
                else
                {
                    spectating = !spectating;
                    GlobalVariables.instance.gameMain.addAlert(spectating ? "Now spectating games in " + room.name : "No longer spectating games in " + room.name);
                    controlSpectate.label = spectating ? "Stop Spectating" : "Start Spectating";
                    if (room.match.song != null && spectating && room.match.status >= Multiplayer.STATUS_LOADED && room.match.status < Multiplayer.STATUS_RESULTS)
                        MultiplayerSingleton.getInstance().spectateGame(room);
                }
            });
            addChild(controlSpectate);

            connection.addEventListener(Multiplayer.EVENT_GAME_START, function(event:GameStartEvent):void
            {
                if (spectating && event.room == room && !room.user.isPlayer && GlobalVariables.instance.gameMain.activePanel is MainMenu)
                    MultiplayerSingleton.getInstance().spectateGame(room);
            });

            connection.addEventListener(Multiplayer.EVENT_ROOM_USER_STATUS, onRoomUpdate);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER, onRoomUpdate);

            connection.addEventListener(Multiplayer.EVENT_CONNECTION, function(event:ConnectionEvent):void
            {
                if (!connection.connected)
                    room = null;
            });

            connection.addEventListener(Multiplayer.EVENT_ROOM_LEFT, function(event:RoomLeftEvent):void
            {
                if (event.room == room)
                {
                    if (self.parent == parent)
                        parent.removeChild(self);
                    room = null;
                }
            });

            controlChat.textAreaAddLine(MultiplayerChat.textFormatJoin(room));

            hasCloseButton = true;
            hasMinimizeButton = true;
            setSize(controlUsers.x + controlUsers.width, titleBar.height + controlChat.y + controlChat.height);
            move(parent.width / 2 - width / 2, parent.height / 2 - height / 2);
            controlChat.focus();

            addEventListener(Event.CLOSE, function(event:Event):void
            {
                if (self.room == null || !self.room.isJoined)
                {
                    parent.removeChild(self);
                    return;
                }

                var inGame:Boolean = false;
                for each (var room:Object in connection.rooms)
                {
                    if (room.isJoined && room != self.room)
                        inGame = true;
                }
                if (inGame)
                    connection.leaveRoom(self.room)
                else
                {
                    connection.joinLobby();
                    connection.leaveRoom(self.room)
                }
            });
        }

        public function redraw():void
        {
            controlPlayer1.redraw(true);
            controlPlayer2.redraw(true);
            controlChat.redraw(true);
        }

        private function onRoomUpdate(event:RoomUpdateEvent):void
        {
            if (event.room == room)
                controlSpectate.label = room.user.isPlayer ? "Spectate" : (room.playerCount < 2 ? "Join Game" : (spectating ? "Stop Spectating" : "Start Spectating"));
        }
    }
}
