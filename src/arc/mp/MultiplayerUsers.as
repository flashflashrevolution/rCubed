package arc.mp
{
    import Main;
    import menu.MenuPanel;
    import classes.Text;
    import classes.BoxButton;

    import arc.ArcGlobals;
    import arc.mp.ListItemDoubleClick;
    import arc.mp.MultiplayerPrompt;
    import arc.mp.MultiplayerChat;
    import com.flashfla.net.Multiplayer;

    import flash.ui.Keyboard;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.display.DisplayObjectContainer;

    import com.bit101.components.Component;
    import com.bit101.components.TextArea;
    import com.bit101.components.InputText;
    import com.bit101.components.List;
    import com.bit101.components.PushButton;

    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class MultiplayerUsers extends Component
    {
        private var controlUsers:List;
        private var controlChat:MultiplayerChat;
        private var owner:DisplayObjectContainer;

        public var room:Object;
        public var connection:Multiplayer;

        public function MultiplayerUsers(parent:DisplayObjectContainer, roomValue:Object, ownerValue:DisplayObjectContainer = null, controlChatValue:MultiplayerChat = null)
        {
            super(parent);
            this.room = roomValue;
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
                var user:Object = controlUsers.selectedItem.data;
                var pm:MultiplayerPrompt = new MultiplayerPrompt(owner, "PM " + user.userName);
                pm.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:SFSEvent):void
                {
                    connection.sendPrivateMessage(user, subevent.params.value, room);
                    if (controlChat != null)
                        controlChat.textAreaAddLine(MultiplayerChat.textFormatPrivateMessageOut(user, subevent.params.value));
                });
            });
            addChild(controlUsers);

            setSize(200, 350);

            connection.addEventListener(Multiplayer.EVENT_LOGIN, function(event:SFSEvent):void
            {
                buildContextMenu();
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER, function(event:SFSEvent):void
            {
                if (event.params.room == room)
                    updateUsers();
            });
            connection.addEventListener(Multiplayer.EVENT_ROOM_JOINED, function(event:SFSEvent):void
            {
                if (event.params.room == room)
                    updateUsers();
            });
            connection.addEventListener(Multiplayer.EVENT_USER_UPDATE, function(event:SFSEvent):void
            {
                updateUser(event.params.user);
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
            var items:Array = new Array();
            for each (var user:Object in room.users)
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
                    var user:Object = event.mouseTarget["data"]["data"];
                    var pm:MultiplayerPrompt = new MultiplayerPrompt(owner, "Moderator Message " + user.userName);
                    pm.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:SFSEvent):void
                    {
                        connection.sendServerMessage(subevent.params.value, user);
                        if (controlChat != null)
                            controlChat.textAreaAddLine(MultiplayerChat.textFormatServerMessage(room.user, subevent.params.value));
                    });
                });
                userMenu.customItems.push(userItem);
                userItem = new ContextMenuItem("Mute User");
                userItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    var user:Object = event.mouseTarget["data"]["data"];
                    var minutes:MultiplayerPrompt = new MultiplayerPrompt(owner, "Mute Duration (minutes) for " + user.userName);
                    minutes.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:SFSEvent):void
                    {
                        if (!isNaN(subevent.params.value))
                        {
                            connection.muteUser(user, parseInt(subevent.params.value));
                            if (controlChat != null)
                                controlChat.textAreaAddLine(MultiplayerChat.textFormatModeratorMute(user, subevent.params.value));
                        }
                    });
                });
                userMenu.customItems.push(userItem);
                userItem = new ContextMenuItem("Ban User");
                userItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
                {
                    var user:Object = event.mouseTarget["data"]["data"];
                    var minutes:MultiplayerPrompt = new MultiplayerPrompt(owner, "Ban Duration (minutes) for " + user.userName);
                    minutes.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:SFSEvent):void
                    {
                        if (!isNaN(subevent.params.value))
                        {
                            connection.banUser(user, parseInt(subevent.params.value));
                            if (controlChat != null)
                                controlChat.textAreaAddLine(MultiplayerChat.textFormatModeratorBan(user, subevent.params.value));
                        }
                    });
                });
                userMenu.customItems.push(userItem);
                controlUsers.contextMenu = userMenu;
            }
            else
                controlUsers.contextMenu = null;
        }
    }
}
