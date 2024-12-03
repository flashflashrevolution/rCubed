package classes.mp
{
    import classes.Alert;
    import classes.Language;
    import classes.Site;
    import classes.SongInfo;
    import classes.mp.commands.IMPCommand;
    import classes.mp.commands.MPCFFRSong;
    import classes.mp.commands.MPCFFRSongRate;
    import classes.mp.commands.MPCRoomJoin;
    import classes.mp.commands.MPCommands;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.events.MPUserEvent;
    import classes.mp.pm.MPUserChatHistory;
    import classes.mp.room.MPRoom;
    import classes.mp.room.MPRoomFFR;
    import com.worlize.websocket.WebSocket;
    import com.worlize.websocket.WebSocketErrorEvent;
    import com.worlize.websocket.WebSocketEvent;
    import com.worlize.websocket.WebSocketMessage;
    import com.worlize.websocket.WebSocketURI;
    import flash.events.ErrorEvent;
    import flash.events.EventDispatcher;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    public class Multiplayer extends EventDispatcher
    {
        private static const _gvars:GlobalVariables = GlobalVariables.instance;
        private static const _lang:Language = Language.instance;
        private static const _site:Site = Site.instance;

        private static var _instance:Multiplayer = null;

        public static const SERVER_VERSION:uint = 3;

        private var _listeners:Array = [];

        private var DEBUG:Boolean = CONFIG::debug;
        private var AUTO_JOIN_LOBBY:Boolean = true;

        private var websocket:WebSocket;

        public static const VALID_GAME_TYPES:Array = ["ffr"];

        // Cache for Data
        public var users:Vector.<MPUser>;
        public var users_map:Dictionary;

        public var rooms:Vector.<MPRoom>;
        public var rooms_map:Dictionary;

        public var pms:Vector.<MPUserChatHistory>;
        public var pms_map:Dictionary;

        public var LOBBY:MPRoom;
        public var GAME_ROOM:MPRoom;

        public var SYSTEM_USER:MPUser;

        public var currentUser:MPUser;
        public var activeRooms:Vector.<MPRoom>;

        /**
         * Handles data syncing before server and client before informing the rest of the game.
         * It's based on keeping single references to Rooms/User/Teams to avoid passing data around.
         * Class data should only be modified due to server responsed and not by the client.
         * !!! Don't alter anything in this class directly. !!!
         * Responsible for the loss of Velocity's sanity.
         */
        public function Multiplayer(en:SingletonEnforcer)
        {
            if (en == null)
            {
                throw Error("Multi-Instance Blocked");
            }
        }

        /*
           public override function dispatchEvent(event:Event):Boolean
           {
           if (event is MPEvent)
           trace(event as MPEvent);

           return super.dispatchEvent(event);
           }
         */

        override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
        {
            super.addEventListener(type, listener, useCapture, priority, useWeakReference);
            _listeners.push([type, listener, useCapture, priority, useWeakReference]);
        }

        override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
        {
            super.removeEventListener(type, listener, useCapture);
            for (var i:Number = _listeners.length - 1; i >= 0; i--)
            {
                var lis:Array = _listeners[i];
                if (lis[0] == type && lis[1] == listener && lis[2] == useCapture)
                {
                    _listeners.splice(i, 1);
                }
            }
        }

        public function printDebugListeners():Array
        {
            return _listeners;
        }

        public function get connected():Boolean
        {
            return websocket != null && websocket.connected;
        }

        private function init():void
        {
            websocket = new WebSocket(new WebSocketURI(_site.data["game_mp_host"], _site.data["game_mp_port"]), "*", "r3");
            websocket.addEventListener(WebSocketEvent.CLOSED, handleWebSocketClosed);
            websocket.addEventListener(WebSocketEvent.OPEN, handleWebSocketOpen);
            websocket.addEventListener(WebSocketEvent.MESSAGE, handleWebSocketMessage);
            websocket.addEventListener(WebSocketErrorEvent.CONNECTION_FAIL, handleConnectionFail);
            websocket.addEventListener(WebSocketErrorEvent.ABNORMAL_CLOSE, handleConnectionFail);
            websocket.addEventListener(ErrorEvent.ERROR, handleErrorEvent);
        }

        /**
         * Connect to the Multiplayer Websocket.
         */
        public function connect():void
        {
            if (!websocket)
                init();

            if (!websocket.connected)
            {
                this.currentUser = null;
                this.users = new <MPUser>[];
                this.users_map = new Dictionary(true);

                this.rooms = new <MPRoom>[];
                this.rooms_map = new Dictionary(true);

                this.pms = new <MPUserChatHistory>[];
                this.pms_map = new Dictionary(true);

                this.activeRooms = new <MPRoom>[];
                this.LOBBY = null;
                this.GAME_ROOM = null;

                SYSTEM_USER = _userUpdateDirect({uid: 1});

                websocket.connect();
            }
        }

        public function disconnect():void
        {
            if (websocket)
                websocket.close();

            clearData();
            clearEvents();
        }

        private function clearData():void
        {
            this.currentUser = null;
            this.users = null;
            this.users_map = null;

            this.rooms = null;
            this.rooms_map = null;

            this.pms = null;
            this.pms_map = null;

            this.activeRooms = null;
            this.LOBBY = null;
            this.GAME_ROOM = null;
            this.SYSTEM_USER = null;
        }

        public function clearEvents():void
        {
            for (var i:Number = _listeners.length - 1; i >= 0; i--)
            {
                var lis:Array = _listeners[i];
                super.removeEventListener(lis[0], lis[1], lis[2]);
            }
            _listeners.length = 0;
        }

        private function handleWebSocketOpen(event:WebSocketEvent):void
        {
            dispatchEvent(new MPEvent(MPEvent.SOCKET_CONNECT, null));
        }

        private function handleWebSocketClosed(event:WebSocketEvent):void
        {
            dispatchEvent(new MPEvent(MPEvent.SOCKET_DISCONNECT, new MPSocketDataText("disconnect", "Disconnect")));
        }

        private function handleConnectionFail(event:WebSocketErrorEvent):void
        {
            //trace("Connection Failure: " + event.text);
            dispatchEvent(new MPEvent(MPEvent.SOCKET_ERROR, new MPSocketDataText("error", event.text)));
        }

        private function handleErrorEvent(event:ErrorEvent):void
        {
            //trace("Error Event: " + event.text);
            dispatchEvent(new MPEvent(MPEvent.SOCKET_ERROR, new MPSocketDataText("error", event.text)));
        }

        private function handleWebSocketMessage(event:WebSocketEvent):void
        {
            if (event == null)
                return;

            if (event.message.type == WebSocketMessage.TYPE_UTF8)
            {
                const tcmd:MPSocketDataText = MPSocketDataText.parse(event.message);
                //trace(command);

                if (!tcmd)
                    return;

                switch (tcmd.type)
                {
                    case 'sys':
                        return handleSysCommand(tcmd);

                    case 'room':
                        return handleRoomCommand(tcmd);

                    case 'user':
                        return handleUserCommand(tcmd);

                    case 'mode':
                        return handleModeCommand(tcmd);

                    default:
                        if (DEBUG)
                            trace(tcmd);
                        break;
                }
            }
            else if (event.message.type == WebSocketMessage.TYPE_BINARY)
            {
                const rcmd:MPSocketDataRaw = MPSocketDataRaw.parse(event.message);
                //trace(command);

                if (!rcmd)
                    return;

                switch (rcmd.type)
                {
                    case 1:
                        return handleSysRawCommand(rcmd);

                    case 2:
                        return handleRoomRawCommand(rcmd);

                    case 3:
                        return handleUserRawCommand(rcmd);

                    case 4:
                        return handleModeRawCommand(rcmd);

                    default:
                        if (DEBUG)
                            trace(rcmd);
                        break;
                }
            }
        }

        public function handleSysCommand(command:MPSocketDataText):void
        {
            switch (command.action)
            {
                case 'login_ok':
                    sysLoginOK(command);
                    break;

                case 'login_fail':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.SYS_LOGIN_FAIL, command));
                    disconnect();
                    break;

                case 'room_list':
                    sysRoomList(command);
                    break;

                case 'user_list':
                    sysUserList(command);
                    break;

                case 'room_error':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.SYS_ROOM_ERROR, command));
                    break;

                case 'user_error':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.SYS_USER_ERROR, command));
                    break;

                case 'alert':
                    sysAlert(command);
                    break;

                default:
                    dispatchEvent(new MPEvent(MPEvent.SYS_GENERAL_ERROR, command));
                    break;
            }
        }

        public function handleRoomCommand(command:MPSocketDataText):void
        {
            switch (command.action)
            {
                case 'update':
                    roomUpdate(command);
                    break;

                case 'message':
                    roomMessage(command);
                    break;

                case 'create_ok':
                    roomCreateOK(command);
                    break;

                case 'create_fail':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.ROOM_CREATE_FAIL, command));
                    break;

                case 'delete_ok':
                    roomDeleteOK(command);
                    break;

                case 'delete_fail':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.ROOM_DELETE_FAIL, command));
                    break;

                case 'join_ok':
                    roomJoinOK(command);
                    break;

                case 'join_fail':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.ROOM_JOIN_FAIL, command));
                    break;

                case 'leave_ok':
                    roomLeaveOK(command);
                    break;

                case 'leave_fail':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.ROOM_LEAVE_FAIL, command));
                    break;

                case 'edit_ok':
                    roomEditOK(command);
                    break;

                case 'edit_fail':
                    Alert.add(_lang.string("mp_error_" + (command.data as String).toLowerCase()), 240, Alert.RED);
                    dispatchEvent(new MPEvent(MPEvent.ROOM_EDIT_FAIL, command));
                    break;

                case 'user_join':
                    roomUserJoin(command);
                    break;

                case 'user_leave':
                    roomUserLeave(command);
                    break;

                case 'team_add':
                    roomTeamAdd(command);
                    break;

                case 'team_remove':
                    roomTeamRemove(command);
                    break;

                case 'team_captain':
                    roomTeamCaptain(command);
                    break;

                case 'team_update':
                    roomTeamUpdate(command);
                    break;

                default:
                    dispatchEvent(new MPEvent(MPEvent.SYS_GENERAL_ERROR, command));
                    break;
            }
        }

        public function handleUserCommand(command:MPSocketDataText):void
        {
            switch (command.action)
            {
                case 'message':
                    userMessage(command);
                    break;

                case 'room_invite':
                    userRoomInvite(command);
                    break;

                case 'block_update':
                    userBlockUpdate(command);
                    break;
            }

        }

        public function handleModeCommand(command:MPSocketDataText):void
        {
            roomModeCommand(command);
        }

        public function handleSysRawCommand(command:MPSocketDataRaw):void
        {
            switch (command.action)
            {
                default:
                    dispatchEvent(new MPEvent(MPEvent.SYS_GENERAL_ERROR, null));
                    break;
            }
        }

        public function handleRoomRawCommand(command:MPSocketDataRaw):void
        {
            switch (command.action)
            {
                default:
                    dispatchEvent(new MPEvent(MPEvent.SYS_GENERAL_ERROR, null));
                    break;
            }
        }

        public function handleUserRawCommand(command:MPSocketDataRaw):void
        {
            switch (command.action)
            {
                default:
                    dispatchEvent(new MPEvent(MPEvent.SYS_GENERAL_ERROR, null));
                    break;
            }
        }

        public function handleModeRawCommand(command:MPSocketDataRaw):void
        {
            roomModeRawCommand(command);
        }

        public function sendBytes(data:ByteArray):Boolean
        {
            if (!websocket.connected)
                return false;

            websocket.sendBytes(data);
            return true;
        }

        public function sendUTF(data:String):Boolean
        {
            if (!websocket.connected)
                return false;

            websocket.sendUTF(data);
            return true;
        }

        public function sendCommand(cmd:IMPCommand):Boolean
        {
            if (!websocket.connected)
                return false;

            websocket.sendUTF(cmd.toJSON());
            return true;
        }

        public function updateLobby():void
        {
            sendUTF(MPCommands.UPDATE_LOBBY);
        }

        public function updateRoomList():void
        {
            sendUTF(MPCommands.UPDATE_ROOM_LIST);
        }

        public function getRoom(uid:uint):MPRoom
        {
            if (rooms_map[uid] != null)
                return rooms_map[uid];

            return null;
        }

        public function setRoom(room:MPRoom):void
        {
            if (rooms_map[room.uid] == null)
            {
                rooms_map[room.uid] = room;
                rooms.push(room);

                _roomSort();
            }
        }

        public function getUser(uid:uint):MPUser
        {
            if (users_map[uid] != null)
                return users_map[uid];

            return null;
        }

        public function setUser(user:MPUser):void
        {
            if (users_map[user.uid] == null)
            {
                users.push(user);
                users_map[user.uid] = user;
            }
        }

        public function garbageCollection():void
        {
            _staleUsers();
        }

        private function _staleUsers():void
        {
            var i:Number;
            var user:MPUser;

            // Mark all Users as Stale
            for (i = users.length - 1; i >= 0; i--)
            {
                users[i].isStale = true;
            }

            // Set self as not stale
            currentUser.isStale = false;
            SYSTEM_USER.isStale = false;

            // Check References to User in Rooms
            for each (var room:MPRoom in rooms)
            {
                for each (user in room.users)
                {
                    user.isStale = false;
                }
            }

            // Delete Stale Users
            for (i = users.length - 1; i >= 0; i--)
            {
                user = users[i];

                if (user.isStale)
                {
                    delete users_map[user.uid];
                    users.splice(i, 1);
                }
            }
        }

        ///////////////////////////////////
        private function sysLoginOK(command:MPSocketDataText):void
        {
            this.currentUser = new MPUser();
            this.currentUser.update(command.data);

            this.users.push(this.currentUser);
            this.users_map[this.currentUser.uid] = this.currentUser;

            dispatchEvent(new MPEvent(MPEvent.SYS_LOGIN_OK, command));
        }

        private function sysRoomList(command:MPSocketDataText):void
        {
            var i:Number;
            var temp_rooms:Array = command.data as Array;
            var temp_room:MPRoom;

            // Mark all Rooms as Stale
            for (i = rooms.length - 1; i >= 0; i--)
            {
                rooms[i].isStale = true;
            }

            // Add / Update Existing Rooms
            for (i = temp_rooms.length - 1; i >= 0; i--)
            {
                _roomUpdateDirect(temp_rooms[i]);
            }

            // Delete Stale Rooms
            for (i = rooms.length - 1; i >= 0; i--)
            {
                if (rooms[i].isStale)
                {
                    delete rooms_map[rooms[i].uid];
                    rooms.splice(i, 1);
                }
            }

            //_roomSort();
            garbageCollection();

            // Find Lobby
            if (LOBBY == null)
            {
                for each (var room:MPRoom in this.rooms)
                {
                    if (room.type == "lobby")
                    {
                        LOBBY = room;
                        break;
                    }
                }

                if (AUTO_JOIN_LOBBY)
                    joinLobby();
            }

            dispatchEvent(new MPEvent(MPEvent.SYS_ROOM_LIST, command));
        }

        private function sysUserList(command:MPSocketDataText):void
        {
            var i:Number;
            var temp_users:Array = command.data as Array;
            var temp_user:MPUser;

            // Add / Update Existing Users
            for (i = temp_users.length - 1; i >= 0; i--)
                _userUpdateDirect(temp_users[i]);

            garbageCollection();

            dispatchEvent(new MPEvent(MPEvent.SYS_USER_LIST, command));
        }

        private function sysAlert(command:MPSocketDataText):void
        {
            var color:Number = command.data.color ? command.data.color : 0;
            var age:Number = command.data.age ? command.data.age : 120;

            if (command.data.lang != null)
                Alert.add(_lang.string(command.data.lang), age, color);
            else if (command.data.msg != null)
                Alert.add(command.data.msg, age, color);
        }

        private function roomUpdate(command:MPSocketDataText):void
        {
            _roomUpdateDirect(command.data);

            var room:MPRoom = rooms_map[command.data.uid];
            dispatchEvent(new MPRoomEvent(MPEvent.ROOM_UPDATE, command, room));
        }

        private function roomCreateOK(command:MPSocketDataText):void
        {
            _roomUpdateDirect(command.data);

            var room:MPRoom = rooms_map[command.data.uid];
            room.onJoin();
            activeRooms.push(room);

            if (room.type != "lobby")
                GAME_ROOM = room;

            dispatchEvent(new MPRoomEvent(MPEvent.ROOM_CREATE_OK, command, room));
        }

        private function roomJoinOK(command:MPSocketDataText):void
        {
            _roomUpdateDirect(command.data);

            var room:MPRoom = rooms_map[command.data.uid];
            room.onJoin();
            activeRooms.push(room);

            if (room.type != "lobby")
                GAME_ROOM = room;

            dispatchEvent(new MPRoomEvent(MPEvent.ROOM_JOIN_OK, command, room));
        }

        private function roomLeaveOK(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];
            room.onLeave();

            var idx:int = activeRooms.indexOf(room);
            if (idx != -1)
                activeRooms.splice(idx, 1);

            if (room == GAME_ROOM)
                GAME_ROOM = null;

            // Clear Extra Data from Room
            if (room)
                room.clearExtra();

            garbageCollection();
            dispatchEvent(new MPRoomEvent(MPEvent.ROOM_LEAVE_OK, command, room));
        }

        /**
         * Called when Room Delete command is OK.
         *
         */
        private function roomDeleteOK(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];

            if (_roomDeleteDirect(command.data))
            {
                var idx:int = activeRooms.indexOf(room);
                if (idx != -1)
                    activeRooms.splice(idx, 1);

                if (room == GAME_ROOM)
                    GAME_ROOM = null;

                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_DELETE_OK, command, room));
            }
            else
            {
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_DELETE_FAIL, command, room));
            }
        }

        /**
         * Called when a Room Edit command is OK.
         * Updates the cached room if it exist, or fails otherwise.
         */
        private function roomEditOK(command:MPSocketDataText):void
        {
            var uid:uint = command.data.uid;
            var room:MPRoom = rooms_map[uid];

            if (room)
            {
                room.update(command.data);
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_EDIT_OK, command, room));
            }
            else
            {
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_EDIT_FAIL, command, room));
            }
        }

        private function roomUserJoin(command:MPSocketDataText):void
        {
            var uid:uint = command.data.uid;
            var room:MPRoom = rooms_map[uid];
            var user:MPUser = _userUpdateDirect(command.data.user);

            if (!room)
                return;

            // Existing
            if (user)
                user.update(command.data.user);

            // New User
            else
            {
                user = new MPUser();
                user.update(command.data.user);
                users.push(user);
                users_map[user.uid] = user;
            }

            room.userJoin(user);

            dispatchEvent(new MPRoomEvent(MPEvent.ROOM_USER_JOIN, command, room, user));
        }

        private function roomUserLeave(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];
            var user:MPUser = users_map[command.data.userUID];

            if (room && user)
            {
                room.userLeave(user);
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_USER_LEAVE, command, room, user));
                garbageCollection();
            }
        }

        private function roomTeamUpdate(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];

            if (room)
            {
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_TEAM_UPDATE, command, room));
            }
        }

        private function roomTeamAdd(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];
            var user:MPUser = users_map[command.data.userUID];

            if (room && user)
            {
                room.userJoinTeam(user, command.data.teamUID, command.data.vars);
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_TEAM_ADD, command, room));
            }
        }

        private function roomTeamRemove(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];
            var user:MPUser = users_map[command.data.userUID];

            if (room && user)
            {
                room.userLeaveTeam(user, command.data.teamUID);
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_TEAM_REMOVE, command, room));
            }
        }

        private function roomTeamCaptain(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];
            var user:MPUser = users_map[command.data.userUID];

            if (room && user)
            {
                room.userTeamCaptain(user, command.data.teamUID);
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_TEAM_CAPTAIN, command, room));
            }
        }

        private function roomMessage(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];
            var user:MPUser = users_map[command.data.userUID];

            if (room && user && command.data.message)
            {
                dispatchEvent(new MPRoomEvent(MPEvent.ROOM_MESSAGE, command, room, user));
            }
        }

        private function roomModeCommand(command:MPSocketDataText):void
        {
            var room:MPRoom = rooms_map[command.data.uid];
            var user:MPUser = users_map[command.data.userUID];

            if (room)
            {
                room.modeCommand(command, user);
            }
        }

        private function roomModeRawCommand(command:MPSocketDataRaw):void
        {
            command.data.position = 2;
            var roomUID:Number = command.data.readUnsignedInt();
            var playerUID:Number = command.data.readUnsignedInt();

            var room:MPRoom = rooms_map[roomUID];
            var user:MPUser = users_map[playerUID];

            if (room)
            {
                room.modeRawCommand(command, user);
            }
        }

        private function userMessage(command:MPSocketDataText):void
        {
            var user_sender:MPUser = _userUpdateDirect(command.data.user);
            var user_chat:MPUser = users_map[command.data.uid];

            if (user_chat && user_sender && command.data.message)
            {
                _userGetHistory(user_chat).addMessage(user_chat, user_sender, command.data);
                _pmSort();
                dispatchEvent(new MPUserEvent(MPEvent.USER_MESSAGE, command, user_chat, user_sender));
            }
        }

        private function userRoomInvite(command:MPSocketDataText):void
        {
            var user_sender:MPUser = _userUpdateDirect(command.data.user);
            var user:MPUser = users_map[command.data.uid];

            if (user && user_sender && command.data.name && command.data.code)
            {
                _userGetHistory(user).addGameInvite(user, user_sender, command.data);
                _pmSort();
                dispatchEvent(new MPUserEvent(MPEvent.USER_ROOM_INVITE, command, user));
            }
        }

        private function userBlockUpdate(command:MPSocketDataText):void
        {
            currentUser.blockList = command.data.list;
            dispatchEvent(new MPEvent(MPEvent.USER_BLOCK_UPDATE, command));
        }

        private function _roomGetClass(room_data:Object):MPRoom
        {
            switch (room_data.type)
            {
                default:
                case 'lobby':
                    return new MPRoom();

                case 'ffr':
                    return new MPRoomFFR();
            }
        }

        /**
         * Create or Update an existing Room object within cache.
         * @param room_data Object Data containing room information.
         */
        private function _roomUpdateDirect(room_data:Object):MPRoom
        {
            var uid:uint = room_data.uid;
            var room:MPRoom = rooms_map[uid];

            // Existing
            if (room != null)
                room.update(room_data);

            // New Room
            else
            {
                room = _roomGetClass(room_data);
                room.update(room_data);
                rooms.push(room);
                rooms_map[room.uid] = room;
            }

            return room;
        }

        /**
         * Delete MP Room from server command.
         * @param room_data
         * @return
         */
        private function _roomDeleteDirect(room_data:Object):Boolean
        {
            var uid:uint = room_data.uid;
            var room:MPRoom = rooms_map[uid];

            // Clear Extra Data from Room.
            if (room)
            {
                room.clear();

                var i:Number = rooms.indexOf(room);
                rooms.splice(i, 1);
                delete rooms_map[room.uid];

                garbageCollection();
                return true;
            }
            return false;
        }

        /**
         * Sort the room list based on uid where Lobby is first.
         */
        private function _roomSort():void
        {
            rooms.sort(MPRoom.sort);
        }

        /**
         * Create or Update an existing User object within cache.
         * @param room_data Object Data containing room information.
         */
        private function _userUpdateDirect(user_data:Object):MPUser
        {
            var uid:uint = user_data.uid;
            var user:MPUser = users_map[uid];

            // Existing
            if (user != null)
                user.update(user_data);

            // New Room
            else
            {
                user = new MPUser();
                user.update(user_data);
                users.push(user);
                users_map[user.uid] = user;
            }

            return user;
        }

        /**
         * Get User chat history object, used for displaying PMs.
         * This uses site id instead of uid.
         * @param user
         * @return
         */
        private function _userGetHistory(user:MPUser):MPUserChatHistory
        {
            var history:MPUserChatHistory = pms_map[user.sid];

            // Create New
            if (history == null)
            {
                history = new MPUserChatHistory(user);
                pms.push(history);
                pms_map[user.sid] = history;
            }

            return history;
        }

        /**
         * Sort the chat history based on last message age.
         */
        private function _pmSort():void
        {
            pms.sort(MPUserChatHistory.sort);
        }

        ///////////////////////////////////
        public function joinLobby():void
        {
            if (LOBBY)
                joinRoom(LOBBY);
        }

        public function joinRoom(room:MPRoom, password:String = null):void
        {
            if (activeRooms.indexOf(room) == -1)
                sendCommand(new MPCRoomJoin(room, password));
        }

        public function get inGameRoom():Boolean
        {
            return connected && GAME_ROOM != null;
        }

        public function get isPlayerInRoom():Boolean
        {
            if (!connected || GAME_ROOM == null)
                return false;

            return GAME_ROOM.isPlayer(this.currentUser);
        }

        public function hasUnreadPM():Boolean
        {
            for each (var history:MPUserChatHistory in pms)
                if (history.newMessage)
                    return true;

            return false;
        }

        ///////////////////////////////////
        // FFR Binding Functions

        public function ffrUpdateRate():Boolean
        {
            if (!connected || GAME_ROOM == null || !(GAME_ROOM is MPRoomFFR))
                return false;

            if (GAME_ROOM.teamSpectator.contains(currentUser))
                return false;

            return sendCommand(new MPCFFRSongRate(GAME_ROOM as MPRoomFFR, _gvars.playerUser.songRate));
        }

        public function ffrSelectSong(song:SongInfo):Boolean
        {
            if (song == null || !connected || GAME_ROOM == null || !(GAME_ROOM is MPRoomFFR))
                return false;

            var cmd:MPCFFRSong = new MPCFFRSong(GAME_ROOM as MPRoomFFR);
            cmd.name = song.name;
            cmd.author = song.author;
            cmd.time = song.time;
            cmd.note_count = song.note_count;
            cmd.difficulty = song.difficulty;
            cmd.engine = song.engine;
            cmd.id = song.level;
            cmd.level_id = song.level_id;

            // File Loader
            if (song.engine && song.engine.id == "fileloader")
                cmd.engine = {"id": "fileloader",
                        "cacheID": song.engine.cache_id,
                        "chartID": song.engine.chart_id};


            return sendCommand(cmd);
        }

        ///////////////////////////////////
        public static function get instance():Multiplayer
        {
            if (_instance == null)
            {
                _instance = new Multiplayer(new SingletonEnforcer());
            }

            return _instance;
        }
    }
}

class SingletonEnforcer
{
}
