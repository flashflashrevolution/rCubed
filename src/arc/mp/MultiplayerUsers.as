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

        public function MultiplayerUsers(parent:DisplayObjectContainer, room:Room, ownerValue:DisplayObjectContainer = null, controlChatValue:MultiplayerChat = null)
        {
            super(parent);
            this.room = room;
            this.controlChat = controlChatValue;
            this.owner = ownerValue;

            if (owner == null)
                owner = parent;

            connection = MultiplayerSingleton.getInstance().connection;

            controlUsers = new List();
            controlUsers.listItemClass = ListItemDoubleClick;
            controlUsers.autoHideScrollBar = true;
            controlUsers.addEventListener(MouseEvent.DOUBLE_CLICK, function(event:MouseEvent):void
            {
                function e_sendPM(message:String):void
                {
                    connection.sendPrivateMessage(user, message, room);
                    if (controlChat != null)
                        controlChat.textAreaAddLine(MultiplayerChat.textFormatPrivateMessageOut(user, message));
                }
                var user:User = controlUsers.selectedItem.data;
                new Prompt(owner, 320, "PM " + user.name, 100, "SEND", e_sendPM);
            });
            addChild(controlUsers);

            setSize(200, 350);

            connection.addEventListener(Multiplayer.EVENT_LOGIN, function(event:LoginEvent):void
            {
                buildContextMenu();
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER, function(event:RoomUserEvent):void
            {
                if (event.room == room)
                    updateUsers();
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_JOINED, function(event:RoomJoinedEvent):void
            {
                if (event.room == room)
                    updateUsers();
            });
            connection.addEventListener(Multiplayer.EVENT_USER_UPDATE, function(event:UserUpdateEvent):void
            {
                updateUser(event.user);
            });

            buildContextMenu();

            resize();
        }

        public function resize():void
        {
            controlUsers.move(0, 0);
            controlUsers.setSize(width, height);
        }

        public function sortUsers():void
        {
            controlUsers.items.sort(function(ud1:Object, ud2:Object):int
            {
                var u1:Object = ud1.data;
                var u2:Object = ud2.data;
                var c1:int = u1.userLevel || u1.userLevel || 0;
                var c2:int = u2.userLevel || u2.userLevel || 0;
                if (c1 < c2)
                    return 1;
                else if (c1 > c2)
                    return -1;
                return u1.userName.toLowerCase().localeCompare(u2.userName.toLowerCase());
            });
            controlUsers.items = controlUsers.items;
        }

        public function updateUser(user:Object):void
        {
            for each (var item:Object in controlUsers.items)
            {
                if (item.data.userID == user.userID)
                {
                    item.label = MultiplayerChat.nameUser(user);
                    item.data = user;
                    sortUsers();
                    break;
                }
            }
        }

        public function updateUsers():void
        {
            var items:Array = [];
            for each (var user:User in room.userList)
                items.push({label: MultiplayerChat.nameUser(user), labelhtml: true, data: user});
            controlUsers.items = items;
            sortUsers();
            controlUsers.listItemClass = controlUsers.listItemClass;
        }

        public function buildContextMenu():void
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
                            controlChat.textAreaAddLine(MultiplayerChat.textFormatServerMessage(room.user, message));
                    }
                    var user:User = event.mouseTarget["data"]["data"];
                    new Prompt(owner, 320, "Moderator Message " + user.name, 100, "SEND", e_sendModMessage);
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
