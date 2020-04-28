package menu.mp
{
    import classes.Box;
    import classes.Text;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import menu.MenuMultiplayer;
    import arc.mp.MultiplayerConnection;
    import arc.mp.MultiplayerChat;

    public class RoomTab extends Box
    {
        private var mpmenu:MenuMultiplayer;
        private var sprite:Sprite;

        private var title:Text;
        private var users:Text;
        private var messagesBox:Box;
        private var messages:Text;
        private var userList:Array;
        private var userScoreList:Array;

        private var _room:Object;

        public var _selected:Boolean;

        private var messageCount:int;

        public function RoomTab(menu:MenuMultiplayer, sprite:Sprite, width:Number, game:Boolean)
        {
            super(width, game ? 64 : 40, true, true);
            normalAlpha = 0.1;
            activeAlpha = 0.2;

            this.mpmenu = menu;
            this.sprite = sprite;

            title = new Text(" ", 10, "#FFFFFF", Text.CENTER);
            title.width = width;
            title.height = 18;
            addChild(title);

            users = new Text(" ", 10, "#FFFFFF", Text.CENTER);
            users.y = game ? 44 : 20;
            users.width = width;
            users.height = 18;
            addChild(users);

            messagesBox = new Box(18, 14, false, true);
            messagesBox.normalAlpha = 1;
            messagesBox.color = 0x2788a5;
            messagesBox.x = width - 10;
            messagesBox.y = -6;
            addChild(messagesBox);

            messages = new Text("0", 10, "#" + RoomChat.COLOUR_ORANGE.toString(16), Text.CENTER);
            messages.width = 18;
            messages.height = 14;
            messagesBox.addChild(messages);
            messagesBox.visible = false;
        }

        private function updateMessages():void
        {
            if (messageCount > 0)
                messages.text = messageCount.toString();
            messagesBox.visible = (messageCount > 0);
        }

        private function updateUsers():void
        {
            title.text = room.name;

            var text:String = "";
            if (room.playerCount > 0)
                text += room.playerCount + " Player" + (room.playerCount == 1 ? "" : "s");
            if (room.spectatorCount > 0)
                text += (room.playerCount > 0 ? " - " : "") + room.spectatorCount + " Spectator" + (room.spectatorCount == 1 ? "" : "s");
            users.text = text;

            if (room.isGame)
            {
                var gameplay:Object = room.connection.getRoomGameplay(room);
                for (var i:int = 0; i < room.maxPlayerCount; i++)
                {
                    var label:Text = userList[i];
                    var scoreLabel:Text = userScoreList[i];
                    var user:Object = null;
                    for each (var u:Object in room.users)
                    {
                        if (u.playerID == i + 1)
                            user = u;
                    }
                    if (user)
                    {
                        label.text = user.userName;
                        label.fontColor = "#" + RoomChat.COLOUR_WHITE.toString(16);
                        var ug:Object = gameplay["player" + user.playerID];
                        if (ug && ug.score > 0)
                        {
                            scoreLabel.visible = true;
                            scoreLabel.text = ug.score.toString();
                        }
                        else
                            scoreLabel.visible = false;
                    }
                    else
                    {
                        label.text = "[Waiting for Player]";
                        label.fontColor = "#" + RoomChat.COLOUR_RED.toString(16);
                        scoreLabel.visible = false;
                    }
                }
            }
        }

        private function onMessage(event:SFSEvent):void
        {
            if (!_selected && event.params.room == room && event.params.type == MultiplayerConnection.MESSAGE_PUBLIC)
            {
                messageCount++;
                updateMessages();
            }
        }

        private function onRoomUpdate(event:SFSEvent):void
        {
            if (event.params.room == room)
                updateUsers();
        }

        private function register():void
        {
            if (room)
            {
                room.connection.addEventListener(MultiplayerConnection.EVENT_ROOM_UPDATE, onRoomUpdate);
                room.connection.addEventListener(MultiplayerConnection.EVENT_ROOM_USER, onRoomUpdate);
                room.connection.addEventListener(MultiplayerConnection.EVENT_ROOM_USER_STATUS, onRoomUpdate);
                room.connection.addEventListener(MultiplayerConnection.EVENT_MESSAGE, onMessage);

                if (room.isGame)
                {
                    userList = new Array();
                    userScoreList = new Array();
                    var yoffset:int = 18;
                    for (var i:int = 0; i < room.maxPlayerCount; i++)
                    {
                        var userLabel:Text = new Text(" ", 10, "#FFFFFF", Text.LEFT);
                        userLabel.y = yoffset;
                        userLabel.x = 3;
                        userLabel.height = 16;
                        userLabel.width = width - 6;
                        addChild(userLabel);
                        userList.push(userLabel);

                        userLabel = new Text(" ", 10, "#FFFFFF", Text.RIGHT);
                        userLabel.x = 3;
                        userLabel.y = yoffset;
                        userLabel.height = 16;
                        userLabel.width = width - 6;
                        addChild(userLabel);
                        userScoreList.push(userLabel);

                        yoffset += 13;
                    }
                }

                updateUsers();
            }
        }

        private function unregister():void
        {
            if (room)
            {
                room.connection.removeEventListener(MultiplayerConnection.EVENT_ROOM_UPDATE, onRoomUpdate);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_ROOM_USER, onRoomUpdate);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_ROOM_USER_STATUS, onRoomUpdate);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_MESSAGE, onMessage);

                if (room.isGame)
                {
                    for each (var label:Text in userList)
                        label.parent.removeChild(label);
                    for each (label in userScoreList)
                        label.parent.removeChild(label);
                    userList = null;
                    userScoreList = null;
                }
            }
        }

        public function get room():Object
        {
            return _room;
        }

        public function set room(value:Object):void
        {
            unregister();
            _room = value;
            register();
        }

        public function get selected():Boolean
        {
            return _selected;
        }

        public function set selected(value:Boolean):void
        {
            _selected = value;
            if (value)
            {
                messageCount = 0;
                updateMessages();
            }
            normalAlpha = (_selected ? 0.3 : 0.1);
            activeAlpha = (_selected ? 0.3 : 0.2);
        }

        public function show():void
        {
            mpmenu.addChild(sprite);
            selected = true;
        }

        public function hide():void
        {
            if (sprite.parent)
                mpmenu.removeChild(sprite);
            selected = false;
        }
    }
}
