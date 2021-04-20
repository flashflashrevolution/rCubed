package arc.mp
{
    import arc.mp.ListItemDoubleClick;
    import arc.mp.MultiplayerChat;
    import classes.ui.Prompt;
    import classes.Room;
    import classes.User;
    import com.bit101.components.Component;
    import com.bit101.components.List;
    import com.flashfla.net.Multiplayer;
    import com.flashfla.net.events.LoginEvent;
    import com.flashfla.net.events.RoomUserEvent;
    import com.flashfla.net.events.RoomJoinedEvent;
    import com.flashfla.net.events.UserUpdateEvent;
    import flash.display.DisplayObjectContainer;
    import flash.events.ContextMenuEvent;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;

    public class MultiplayerUsers extends Component
    {
        private var controlUsers:List;
        private var controlChat:MultiplayerChat;
        private var owner:DisplayObjectContainer;

        public var room:Room;
        public var connection:Multiplayer;

        public function MultiplayerUsers(parent:DisplayObjectContainer, room:Room, owner:DisplayObjectContainer = null, controlChat:MultiplayerChat = null)
        {
            super(parent);
            this.room = room;
            this.controlChat = controlChat;
            this.owner = owner ? owner : parent;

            connection = MultiplayerSingleton.getInstance().connection;

            controlUsers = new List();
            controlUsers.listItemClass = ListItemDoubleClick;
            controlUsers.autoHideScrollBar = true;
            controlUsers.addEventListener(MouseEvent.DOUBLE_CLICK, onUserListDoubleClick);
            addChild(controlUsers);

            setSize(200, 350);

            connection.addEventListener(Multiplayer.EVENT_LOGIN, onLogin);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER, onRoomUser);
            connection.addEventListener(Multiplayer.EVENT_ROOM_JOINED, onRoomJoined);
            connection.addEventListener(Multiplayer.EVENT_USER_UPDATE, onUserUpdate);

            buildContextMenu();

            resize();
        }

        public function get currentUser():User
        {
            return connection.currentUser
        }

        public function resize():void
        {
            controlUsers.move(0, 0);
            controlUsers.setSize(width, height);
        }

        public function updateUsers():void
        {
            var items:Array = [];
            for each (var user:User in room.users)
                items.push({label: MultiplayerChat.nameUser(user), labelhtml: true, data: user});
            controlUsers.items = items;
            sortUsers();
            controlUsers.listItemClass = controlUsers.listItemClass;
        }

        private function onUserListDoubleClick(event:MouseEvent):void
        {
            function e_sendPM(message:String):void
            {
                connection.sendPrivateMessage(user, message, room);
                if (controlChat != null)
                    controlChat.textAreaAddLine(MultiplayerChat.textFormatPrivateMessageOut(user, message));
            }
            var user:User = controlUsers.selectedItem.data;
            new Prompt(owner, 320, "PM " + user.name, 100, "SEND", e_sendPM);
        }

        private function onLogin(event:LoginEvent):void
        {
            buildContextMenu();
        }

        private function onRoomUser(event:RoomUserEvent):void
        {
            if (event.room == room)
                updateUsers();
        }

        private function onRoomJoined(event:RoomJoinedEvent):void
        {
            if (event.room == room)
                updateUsers();
        }

        private function onUserUpdate(event:UserUpdateEvent):void
        {
            updateUser(event.user);
        }

        private function sortUsers():void
        {
            controlUsers.items.sort(function(ud1:Object, ud2:Object):int
            {
                var u1:User = ud1.data;
                var u2:User = ud2.data;
                var c1:int = u1.userLevel || u1.userLevel || 0;
                var c2:int = u2.userLevel || u2.userLevel || 0;
                if (c1 < c2)
                    return 1;
                else if (c1 > c2)
                    return -1;
                return u1.name.toLowerCase().localeCompare(u2.name.toLowerCase());
            });
            controlUsers.items = controlUsers.items;
        }

        private function updateUser(user:User):void
        {
            for each (var item:Object in controlUsers.items)
            {
                if (item.data.id == user.id)
                {
                    item.label = MultiplayerChat.nameUser(user);
                    item.data = user;
                    sortUsers();
                    break;
                }
            }
        }

        private function buildContextMenu():void
        {
            if (connection.currentUser.isModerator)
            {
                var userMenu:ContextMenu = new ContextMenu();
                var userItem:ContextMenuItem = new ContextMenuItem("Send Moderator Message");
                userItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    function e_sendModMessage(message:String):void
                    {
                        connection.sendServerMessage(message, user);
                        if (controlChat != null)
                            controlChat.textAreaAddLine(MultiplayerChat.textFormatServerMessage(currentUser, message));
                    }
                    var item:Object = event.mouseTarget["data"];

                    if (item)
                    {
                        var user:User = item["data"];
                        new Prompt(owner, 320, "Moderator Message " + user.name, 100, "SEND", e_sendModMessage);
                    }
                });
                userMenu.customItems.push(userItem);
                userItem = new ContextMenuItem("Mute User");
                userItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    function e_muteUser(minutesString:String):void
                    {
                        var minutes:Number = parseInt(minutesString);
                        if (!isNaN(minutes))
                        {
                            connection.muteUser(user, minutes);
                            if (controlChat != null)
                                controlChat.textAreaAddLine(MultiplayerChat.textFormatModeratorMute(user, minutes));
                        }
                    }
                    var user:User = event.mouseTarget["data"]["data"];
                    new Prompt(owner, 320, "Mute Duration (minutes) for " + user.name, 100, "MUTE", e_muteUser);
                });
                userMenu.customItems.push(userItem);
                userItem = new ContextMenuItem("Ban User");
                userItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    function e_banUser(minutesString:String):void
                    {
                        var minutes:Number = parseInt(minutesString);
                        if (!isNaN(minutes))
                        {
                            connection.banUser(user, minutes);
                            if (controlChat != null)
                                controlChat.textAreaAddLine(MultiplayerChat.textFormatModeratorBan(user, minutes));
                        }
                    }
                    var user:User = event.mouseTarget["data"]["data"];
                    new Prompt(owner, 320, "Ban Duration (minutes) for " + user.name, 100, "BAN", e_banUser);
                });
                userMenu.customItems.push(userItem);
                controlUsers.contextMenu = userMenu;
            }
            else
                controlUsers.contextMenu = null;
        }
    }
}
