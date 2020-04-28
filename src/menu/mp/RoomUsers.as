package menu.mp
{
    import menu.mp.List;
    import flash.display.Sprite;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import arc.mp.MultiplayerConnection;
    import arc.mp.MultiplayerSingleton;
    import arc.mp.MultiplayerChat;

    public class RoomUsers extends Sprite
    {
        private var _room:Object;

        private var users:List;

        public function RoomUsers(width:Number, height:Number)
        {
            users = new List(width, height, "Users");
            addChild(users);
        }

        private function sortUsers():void
        {
            users.items.sort(function(ud1:Object, ud2:Object):int
            {
                var u1:Object = ud1.data;
                var u2:Object = ud2.data;
                var c1:int = u1.userColour || u1.userClass || MultiplayerConnection.CLASS_USER;
                var c2:int = u2.userColour || u2.userClass || MultiplayerConnection.CLASS_USER;
                if (c1 > c2)
                    return 1;
                else if (c1 < c2)
                    return -1;
                return u1.userName.toLowerCase().localeCompare(u2.userName.toLowerCase());
            });
            users.updateItems();
        }

        private function updateUser(user:Object):void
        {
            for each (var item:Object in users.items)
            {
                if (item.data.userID == user.userID)
                {
                    item.text = RoomChat.nameUser(user);
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
                items.push({text: RoomChat.nameUser(user), data: user});
            users.items = items;
            sortUsers();
        }

        private function onRoomUpdate(event:SFSEvent):void
        {
            if (event.params.room == room)
                updateUsers();
        }

        private function onUserUpdate(event:SFSEvent):void
        {
            updateUser(event.params.user);
        }

        private function register():void
        {
            if (room)
            {
                room.connection.addEventListener(MultiplayerConnection.EVENT_ROOM_USER, onRoomUpdate);
                room.connection.addEventListener(MultiplayerConnection.EVENT_ROOM_JOINED, onRoomUpdate);
                room.connection.addEventListener(MultiplayerConnection.EVENT_USER_UPDATE, onUserUpdate);
            }
        }

        private function unregister():void
        {
            if (room)
            {
                room.connection.removeEventListener(MultiplayerConnection.EVENT_ROOM_USER, onRoomUpdate);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_ROOM_JOINED, onRoomUpdate);
                room.connection.removeEventListener(MultiplayerConnection.EVENT_USER_UPDATE, onUserUpdate);
            }
        }

        public function set room(value:Object):void
        {
            unregister();
            _room = value;
            register();
        }

        public function get room():Object
        {
            return _room;
        }
    }
}
