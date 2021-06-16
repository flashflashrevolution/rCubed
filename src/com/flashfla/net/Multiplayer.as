package com.flashfla.net
{
    import flash.events.EventDispatcher;

    import arc.ArcGlobals;
    import arc.mp.MultiplayerSingleton;
    import classes.Alert;
    import classes.Playlist;
    import classes.Room;
    import classes.User;
    import classes.Gameplay;

    import it.gotoandplay.smartfoxserver.SFSEvents.AdminMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ExtensionResponseSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.DebugMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.CreateRoomErrorSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.LogoutSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ModerationMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PlayerSwitchedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.SpectatorSwitchedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PrivateMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.PublicMessageSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomListUpdateSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomVariablesUpdateSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomAddedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.RoomDeletedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.LeftRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.JoinedRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.JoinRoomErrorSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserCountChangeSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserEnterRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserLeftRoomSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.UserVariablesUpdateSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ConnectionSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvents.ConnectionLostSFSEvent;
    import it.gotoandplay.smartfoxserver.SmartFoxClient;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import com.flashfla.net.events.ConnectionEvent;
    import com.flashfla.net.events.LoginEvent;
    import com.flashfla.net.events.ErrorEvent;
    import com.flashfla.net.events.ServerMessageEvent;
    import com.flashfla.net.events.MessageEvent;
    import com.flashfla.net.events.RoomUserEvent;
    import com.flashfla.net.events.RoomJoinedEvent;
    import com.flashfla.net.events.RoomLeftEvent;
    import com.flashfla.net.events.RoomUpdateEvent;
    import com.flashfla.net.events.RoomListEvent;
    import com.flashfla.net.events.UserUpdateEvent;
    import com.flashfla.net.events.GameStartEvent;
    import com.flashfla.net.events.GameResultsEvent;
    import com.flashfla.net.events.ExtensionResponseEvent;
    import com.flashfla.net.events.RoomUserStatusEvent;
    import com.flashfla.net.events.GameUpdateEvent;
    import com.flashfla.utils.StringUtil;

    public class Multiplayer extends EventDispatcher
    {
        private static const serverAddress:String = "flashflashrevolution.com";
        private static const serverPort:int = 8082;

        public static const EVENT_ERROR:String = "ARC_EVENT_ERROR";
        public static const EVENT_CONNECTION:String = "ARC_EVENT_CONNECTION";
        public static const EVENT_LOGIN:String = "ARC_EVENT_LOGIN";
        public static const EVENT_XT_RESPONSE:String = "ARC_EVENT_XT_RESPONSE";
        public static const EVENT_SERVER_MESSAGE:String = "ARC_EVENT_SERVER_MESSAGE";
        public static const EVENT_MESSAGE:String = "ARC_EVENT_MESSAGE";
        public static const EVENT_ROOM_LIST:String = "ARC_EVENT_ROOM_LIST";
        public static const EVENT_ROOM_USER_STATUS:String = "ARC_EVENT_ROOM_USER_STATUS";
        public static const EVENT_ROOM_USER:String = "ARC_EVENT_ROOM_USER";
        public static const EVENT_ROOM_UPDATE:String = "ARC_EVENT_ROOM_UPDATE";
        public static const EVENT_ROOM_JOINED:String = "ARC_EVENT_ROOM_JOINED";
        public static const EVENT_ROOM_LEFT:String = "ARC_EVENT_ROOM_LEFT";
        public static const EVENT_USER_UPDATE:String = "ARC_EVENT_USER_UPDATE";
        public static const EVENT_GAME_START:String = "ARC_EVENT_GAME_START";
        public static const EVENT_GAME_UPDATE:String = "ARC_EVENT_GAME_UPDATE";
        public static const EVENT_GAME_RESULTS:String = "ARC_EVENT_GAME_RESULTS";

        public static const MESSAGE_PUBLIC:int = 0;
        public static const MESSAGE_PRIVATE:int = 1;

        public static const CLASS_ADMIN:int = 1;
        public static const CLASS_BAND:int = 2;
        public static const CLASS_FORUM_MOD:int = 3;
        public static const CLASS_CHAT_MOD:int = 4; // Chat Mod + Profile Mod
        public static const CLASS_MP_MOD:int = 5;
        public static const CLASS_LEGEND:int = 6;
        public static const CLASS_AUTHOR:int = 7; // R1 Music Producer, R1 Simfile Author
        public static const CLASS_VETERAN:int = 8;
        public static const CLASS_USER:int = 9;
        public static const CLASS_BANNED:int = 10;
        public static const CLASS_ANONYMOUS:int = 11;

        public static const COLOURS:Array = [0x000000, 0xFF0000, 0x000000, 0x91FF00, 0x91FF00, 0x91FF00, 0x000000, 0x000000, 0x000000, 0x000000, 0x000000, 0x000000];

        public static const STATUS_NONE:int = 0;
        public static const STATUS_CLEANUP:int = 1;
        public static const STATUS_PICKING:int = 2;
        public static const STATUS_LOADING:int = 3;
        public static const STATUS_LOADED:int = -1; //this value CANNOT be >4 or else old versions dont work
        public static const STATUS_READY:int = 4; //Uses 4 since older versions used 4 for loaded (their ready equiv)
        public static const STATUS_PLAYING:int = 5;
        public static const STATUS_RESULTS:int = 6;

        public static const MODE_NORMAL:int = 0;
        public static const MODE_BATTLE:int = 1;
        public static const MODE_SCORE_RAW:int = 0;
        public static const MODE_SCORE_COMBO:int = 1;

        public static const GAME_VERSION:String = "R^3";
        public static const SERVER_ZONE:String = "ffr_multiplayer";
        public static const SERVER_EXTENSION:String = "FFR_EXT";

        private var server:SmartFoxClient;

        private var _rooms:Object;
        private var _lobby:Room;

        public var connected:Boolean;
        public var currentUser:User;

        public var ghostRooms:Vector.<Room>;

        public var inSolo:Boolean;

        public function Multiplayer()
        {
            _rooms = {};
            currentUser = new User(false, true);
            ghostRooms = new <Room>[];

            server = new SmartFoxClient(false); // CONFIG::debug);

            CONFIG::debug
            {
                server.addEventListener(SFSEvent.onDebugMessage, onDebugMessage);
            }
            server.addEventListener(SFSEvent.onConnection, onConnection);
            server.addEventListener(SFSEvent.onConnectionLost, onConnectionLost);
            server.addEventListener(SFSEvent.onCreateRoomError, onCreateRoomError);
            server.addEventListener(SFSEvent.onExtensionResponse, onExtensionResponse);
            server.addEventListener(SFSEvent.onLogout, onLogout);
            server.addEventListener(SFSEvent.onAdminMessage, onAdminMessage);
            server.addEventListener(SFSEvent.onModeratorMessage, onModeratorMessage);
            server.addEventListener(SFSEvent.onPlayerSwitched, onPlayerSwitched);
            server.addEventListener(SFSEvent.onSpectatorSwitched, onSpectatorSwitched);
            server.addEventListener(SFSEvent.onPublicMessage, onPublicMessage);
            server.addEventListener(SFSEvent.onPrivateMessage, onPrivateMessage);
            server.addEventListener(SFSEvent.onRoomListUpdate, onRoomListUpdate);
            server.addEventListener(SFSEvent.onRoomVariablesUpdate, onRoomVariablesUpdate);
            server.addEventListener(SFSEvent.onRoomAdded, onRoomAdded);
            server.addEventListener(SFSEvent.onRoomDeleted, onRoomDeleted);
            server.addEventListener(SFSEvent.onRoomLeft, onLeftRoom);
            server.addEventListener(SFSEvent.onJoinRoom, onJoinedRoom);
            server.addEventListener(SFSEvent.onJoinRoomError, onJoinRoomError);
            server.addEventListener(SFSEvent.onUserCountChange, onUserCountChange);
            server.addEventListener(SFSEvent.onUserEnterRoom, onUserEnterRoom);
            server.addEventListener(SFSEvent.onUserLeaveRoom, onUserLeftRoom);
            server.addEventListener(SFSEvent.onUserVariablesUpdate, onUserVariablesUpdate);
        }


        // =================================================== //
        // STATE ENCAPSULATION
        // =================================================== //

        public function get rooms():Vector.<Room>
        {
            var roomsVec:Vector.<Room> = new <Room>[];

            for (var idx:int in _rooms)
                roomsVec.push(_rooms[idx]);

            return roomsVec;
        }

        private function getRoom(room:Room):Room
        {
            return _rooms[room.id];
        }

        private function getRoomById(roomId:int):Room
        {
            return _rooms[roomId];
        }

        /**
         * The lobby room, if it exists.
         */
        public function get lobby():Room
        {
            if (_lobby)
                return _lobby;

            for each (var room:Room in rooms)
            {
                if (room.name == "Lobby")
                {
                    _lobby = room
                    return _lobby
                }
            }

            return null
        }

        public function set lobby(room:Room):void
        {
            _lobby = room;
        }


        // =================================================== //
        // STATE MANAGEMENT
        // =================================================== //

        /**
         * Updates a user's gameplay object from a given room's state
         * If the user isn't a player in that room, does nothing.
         */
        private function updateUserGameplayFromRoom(room:Room, user:User):void
        {
            if (!user)
                return;

            var playerIdx:int = room.getPlayerIndex(user);
            if (playerIdx <= 0)
            {
                user.gameplay = null;
                return;
            }

            var gameplay:Gameplay;
            if (user.gameplay)
                gameplay = user.gameplay;
            else
            {
                user.gameplay = new Gameplay();
                gameplay = user.gameplay;
            }

            var stats:Array;
            var previousStatus:int = gameplay.status;

            var prefix:String = "P" + playerIdx;

            gameplay.status = int(room.variables[prefix + "_STATE"]);
            if (gameplay.status <= STATUS_CLEANUP && gameplay.status != STATUS_LOADED)
            {
                if (previousStatus != gameplay.status)
                {
                    gameplay.reset();
                    room.variables["arc_engine" + playerIdx] = null;
                    eventUserUpdate(user);
                }
                return;
            }

            stats = String(room.variables[prefix + "_GAMESCORES"]).split(":");
            gameplay.score = int(stats[0]);
            gameplay.amazing = int(stats[1]);
            gameplay.perfect = int(stats[2]);
            gameplay.good = int(stats[3]);
            gameplay.average = int(stats[4]);
            gameplay.miss = int(stats[5]);
            gameplay.boo = int(stats[6]);
            gameplay.combo = int(stats[7]);
            gameplay.maxCombo = int(stats[8]);
            gameplay.songId = int(room.variables[prefix + "_SONGID"]);
            gameplay.statusLoading = int(room.variables[prefix + "_SONGID_PROGRESS"]);
            gameplay.life = int(room.variables[prefix + "_GAMELIFE"]);

            var engine:String = room.variables["arc_engine" + playerIdx];
            if (engine)
            {
                gameplay.songInfo = ArcGlobals.instance.legacyDecode(JSON.parse(engine));
                if (gameplay.songInfo)
                {
                    if (!("level" in gameplay.songInfo) || gameplay.songInfo.level < 0)
                        gameplay.songInfo.level = gameplay.songId || -1;
                }
            }
            else
            {
                var playlist:Playlist = Playlist.instanceCanon;
                if (gameplay.songId)
                    gameplay.songInfo = playlist.playList[gameplay.songId];
            }

            var replayString:String = room.variables["arc_replay" + playerIdx];
            if (replayString)
                gameplay.encodedReplay = replayString;
        }

        /**
         * Sets the `vars` of the current user.
         */
        private function setCurrentUserVariables():void
        {
            var vars:Array = [];

            vars["UID"] = currentUser.id;
            vars["GAME_VER"] = GAME_VERSION;
            vars["MP_LEVEL"] = currentUser.userLevel;
            vars["MP_CLASS"] = currentUser.userClass;
            vars["MP_COLOR"] = currentUser.userColor;
            vars["MP_STATUS"] = currentUser.userStatus;

            currentUser.variables = vars;
        }

        /**
         * Applies the user's `variables` values to its corresponding fields.
         */
        private function applyUserVariables(user:User):void
        {
            if (user != null)
            {
                var vars:Object = user.variables;

                user.siteId = vars["UID"];
                user.userLevel = vars["MP_LEVEL"];
                user.userClass = vars["MP_CLASS"];
                user.userColor = vars["MP_COLOR"];
                user.userStatus = vars["MP_STATUS"];
            }
        }

        private function removeRoom(room:Room):void
        {
            delete _rooms[room.id];
        }

        private function addRoom(room:Room):void
        {
            room.connection = this;
            _rooms[room.id] = room;

            if (room.name == "Lobby")
                lobby = room;

            updateRoom(room);
        }

        private function updateRoom(room:Room):void
        {
            if (room == null)
                return;

            // Do more specific updates if user is in room
            if (room.hasUser(currentUser))
            {
                var currentUserIsPlayer:Boolean = room.isPlayer(currentUser);
                var roomPlayers:Vector.<User> = room.players;

                // Update each player's gameplay
                var anyUserStatusChanged:Boolean = false;
                var anyPlayerStatusChanged:Boolean = false;
                var anyUserSongNameChanged:Boolean = false;
                for each (var user:User in roomPlayers)
                {
                    var previousUserStatus:int = user.gameplay ? user.gameplay.status ? user.gameplay.status : -1 : -1;
                    var previousSongName:String = user.gameplay ? user.gameplay.songInfo ? user.gameplay.songInfo.name : "" : "";

                    updateUserGameplayFromRoom(room, user);

                    if (previousUserStatus != user.gameplay.status)
                    {
                        anyUserStatusChanged = true;
                        if(room.isPlayer(user))
                            anyPlayerStatusChanged = true;
                    }

                    if (previousSongName != (user.gameplay.songInfo ? user.gameplay.songInfo.name : ""))
                        eventUserUpdate(user);
                }

                // Process gameplay status changes for game start/end
                if (room.isAllPlayersInStatus(STATUS_READY) && room.isAllPlayersSameSong())
                {
                    if(currentUserIsPlayer)
                    {
                        currentUser.gameplay.status = STATUS_PLAYING;

                        reportSongStart(room);
                        sendCurrentUserStatus(room);

                        eventGameStart(room);
                    }
                    else if(currentUser.isSpec)
                    {
                        room.songInfo = room.getPlayersSong()
                        MultiplayerSingleton.getInstance().spectateGame(room)
                    }
                }
                else if (room.isAllPlayersInStatus(STATUS_RESULTS) && anyPlayerStatusChanged)
                {
                    reportSongEnd(room);
                    eventGameResults(room);

                    eventUserUpdate(currentUser);
                }
            }

            // Update room metadata
            room.level = room.variables["GAME_LEVEL"];
            room.mode = room.variables["GAME_MODE"];
            room.scoreMode = room.variables["GAME_SCORE"];
            room.ranked = room.variables["GAME_RANKED"];
        }

        private function getRoomUserById(room:Room, userId:int):User
        {
            if (room == null)
                return null;

            return room.getUser(userId);
        }


        // =================================================== //
        // SERVER REQUESTS
        // =================================================== //

        public function connect():void
        {
            server.connect(serverAddress, serverPort);
        }

        public function disconnect(_inSolo:Boolean = false):void
        {
            inSolo = _inSolo;
            server.disconnect();
        }

        public function login(username:String, password:String):void
        {
            if (connected)
                server.login(SERVER_ZONE, username, password);
        }

        public function logout():void
        {
            if (connected)
                server.logout();
        }

        public function sendServerMessage(message:String, target:Object = null):void
        {
            if (connected)
            {
                if (target == null)
                    server.sendModeratorMessage(message, SmartFoxClient.MODMSG_TO_ZONE);
                else if (target.userID != null)
                    server.sendModeratorMessage(message, SmartFoxClient.MODMSG_TO_USER, target.id);
                else if (target.roomID != null)
                    server.sendModeratorMessage(message, SmartFoxClient.MODMSG_TO_ROOM, target.id);
            }
        }

        public function nukeRoom(room:Room):void
        {
            if (connected && room)
                server.sendXtMessage(SERVER_EXTENSION, "nuke_room", {"room": room.id}, SmartFoxClient.XTMSG_TYPE_XML, lobby.id);
        }

        public function muteUser(user:User, time:int = 2, ipBan:Boolean = false):void
        {
            if (connected && user)
                server.sendXtMessage(SERVER_EXTENSION, "mute_user", {"user": user.name, "bantime": time, "ip": (ipBan ? 1 : 0)}, SmartFoxClient.XTMSG_TYPE_XML, lobby.id);
        }

        public function banUser(user:User, time:int = 2, ipBan:Boolean = false):void
        {
            if (connected && user)
                server.sendXtMessage(SERVER_EXTENSION, "ban_user", {"user": user.name, "bantime": time, "ip": (ipBan ? 1 : 0)}, SmartFoxClient.XTMSG_TYPE_XML, lobby.id);
        }

        public function sendHTMLMessage(message:String, target:Object = null):void
        {
            if (connected)
            {
                if (target == null)
                    server.sendXtMessage(SERVER_EXTENSION, "html_message", {"m": message, "t": SmartFoxClient.MODMSG_TO_ZONE, "v": null});
                else if (target.id != null)
                    server.sendXtMessage(SERVER_EXTENSION, "html_message", {"m": message, "t": SmartFoxClient.MODMSG_TO_USER, "v": target.id});
                else if (target.id != null)
                    server.sendXtMessage(SERVER_EXTENSION, "html_message", {"m": message, "t": SmartFoxClient.MODMSG_TO_ROOM, "v": target.id});
            }
        }

        public function getUserList(room:Room):void
        {
            if (connected && room)
                server.sendXtMessage(SERVER_EXTENSION, "getUserList", {"room": room.id});
        }

        public function getUserVariables(... users):void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSION, "getUserVariables", {"users": users});
        }

        public function getMultiplayerLevel():void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSION, "getMultiplayerLevel", {});
        }

        public function reportSongStart(room:Room):void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSION, "playerStart", {}, "xml", room.id);
        }

        public function reportSongEnd(room:Room):void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSION, "playerFinish", {}, "xml", room.id);
        }

        public function refreshRooms():void
        {
            if (connected)
                server.getRoomList();
        }

        private function currentUserRoomCount():int
        {
            var userId:int = server.myUserId;
            var roomCount:int = 0;

            for each (var tempRoom:Room in rooms)
            {
                roomCount += (tempRoom.getUser(userId) != null ? 1 : 0);
            }

            return roomCount;
        }

        /**
         * Sends a request to the server to join a specific room as a player or not.
         * Optionally, provide a password.
         */
        public function joinRoom(room:Room, asPlayer:Boolean = true, password:String = ""):void
        {
            if (!connected || !room)
            {
                return;
            }

            if (currentUserRoomCount() > 1)
            {
                Alert.add("ERROR: Cannot join two rooms at a time.", 120);
                return;
            }

            if (room.isGameRoom)
            {
                asPlayer &&= room.userCount < Room.MAX_PLAYERS;
            }

            server.joinRoom(room.id, password, !asPlayer, true);
        }

        public function joinLobby():void
        {
            joinRoom(lobby, true);
        }

        /**
         * Sends a request to the server to leave a specific room.
         */
        public function leaveRoom(room:Room):void
        {
            if (connected && room)
            {
                clearCurrentUserRoomVariables(room);
                server.leaveRoom(room.id);
            }
        }

        /**
         * Attempts to switch the current user's state (player/spectator) in the given room.
         * If the user is trying to become a player, it must currently be a spectator
         * and not playing in any other room.
         */
        public function switchRole(room:Room):void
        {
            if (!connected || !room)
                return;

            if (room.isPlayer(currentUser))
            {
                // Cannot switch mode while playing
                if (currentUser.gameplay.status == STATUS_PLAYING)
                    return;

                server.switchPlayer(room.id);
            }
            else
            {
                // Cannot switch to player if already a player in another room
                if (currentUser.isPlayer)
                {
                    eventError("You cannot be a player in more than one game");
                    return;
                }

                // Cannot switch to player if player slots are filled
                if (room.playerCount >= 2)
                    return;

                server.switchSpectator(room.id);
            }
        }

        /**
         * Builds a request to create a new room and sends it to the server.
         */
        public function createRoom(name:String, password:String = "", maxUsers:int = 2, maxSpectators:int = 100):void
        {
            if (currentUserRoomCount() > 1)
            {
                Alert.add("ERROR: Cannot join two rooms at a time.", 120);
                return;
            }
            
            if (!connected || name.length <= 0)
            {
                return;
            }

            var params:Object = {};
            params.name = name;
            params.password = password;
            params.maxUsers = maxUsers;
            params.maxSpectators = maxSpectators;
            params.isGame = true;
            params.exitCurrentRoom = false;
            params.uCount = true;
            params.joinAsSpectator = currentUser.isPlayer;
            params.vars = [{name: "GAME_LEVEL", val: currentUser.userLevel, persistent: true},
                {name: "GAME_MODE", val: MODE_NORMAL, persistent: true},
                {name: "GAME_SCORE", val: MODE_SCORE_RAW, persistent: true},
                {name: "GAME_RANKED", val: true, persistent: true}];

            server.createRoom(params);
        }

        public function sendMessage(room:Room, message:String, escape:Boolean = true):void
        {
            if (connected && room && message)
                server.sendPublicMessage(escape ? StringUtil.htmlEscape(message) : message, room.id);
        }

        public function sendPrivateMessage(user:User, message:String, room:Room = null):void
        {
            if (connected && user && message)
                server.sendPrivateMessage(StringUtil.htmlEscape(message), user.id, (room ? room.id : -1));
        }

        /**
         * Formats and sends the room variables for the currentUser to the server.
         */
        public function sendRoomVariables(room:Room, data:Object, changeOwnership:Boolean = true):void
        {
            var varArray:Array = [];
            for (var name:String in data)
                varArray.push({name: name, val: data[name]});

            if (varArray.length > 0)
                server.setRoomVariables(varArray, room.id, changeOwnership);
        }

        /**
         * Formats empty room variables for the currentUser and sends them to the server.
         */
        private function clearCurrentUserRoomVariables(room:Room):void
        {
            if (!room.isGameRoom)
                return;

            var vars:Object = {};
            var currentUserIdx:int = room.getPlayerIndex(currentUser);

            if (currentUserIdx > 0)
            {
                var prefix:String = "P" + currentUserIdx;

                vars[prefix + "_NAME"] = null;
                vars[prefix + "_UID"] = null;
                vars[prefix + "_SONGID_PROGRESS"] = null;
                vars[prefix + "_SONGID"] = null;
                vars[prefix + "_STATE"] = null;

                vars["arc_engine" + currentUser.id] = null;
                vars["arc_replay" + currentUser.id] = null;

                // If no opponents, set the room's level to the currentUser's level
                // A player spectates and there is a player left.
                // A player spectates and there is no players left.
                var remainingPlayer:User = null;
                for each (var player:User in room.players)
                {
                    if (player.playerIdx != currentUserIdx)
                    {
                        remainingPlayer = player;
                    }
                }

                if (remainingPlayer != null)
                {
                    vars["GAME_LEVEL"] = remainingPlayer.userLevel;
                }
                else
                {
                    vars["GAME_LEVEL"] = -1;
                }
            }



            // Send room vars to server
            sendRoomVariables(room, vars);
        }

        /**
         * Sends the current user's "player" variables (if any) to the server.
         */
        private function sendCurrentUserRoomVariables(room:Room, joining:Boolean = true, handlingLeaver:Boolean = false):void
        {
            if (!room.isGameRoom)
            { 
                return;
            }

            var vars:Object = {};
            var currentUserIdx:int = room.getPlayerIndex(currentUser);

            if (currentUserIdx > 0)
            {
                var prefix:String = "P" + currentUserIdx;

                vars[prefix + "_NAME"] = currentUser.name;
                vars[prefix + "_UID"] = currentUser.id;

                // If no opponents, set the room's level to the currentUser's level
                if (joining || handlingLeaver && currentUser.isPlayer && room.level <= currentUser.userLevel)
                {
                    vars["GAME_LEVEL"] = currentUser.userLevel;
                }

                sendRoomVariables(room, vars);
            }
        }

        /**
         * Builds a request to update the current user's gameplay status
         * in the specified room and sends it to the server.
         */
        public function sendCurrentUserStatus(room:Room):void
        {
            if (!room.hasUser(currentUser))
                return;

            var vars:Object = {};
            var user:User = currentUser;
            var gameplay:Gameplay = currentUser.gameplay;
            var songEngine:Object = ArcGlobals.instance.legacyEncode(gameplay.songInfo);

            var prefix:String = "P" + user.playerIdx;

            // Ordering is important
            var gamescores:Array = [gameplay.score,
                gameplay.amazing,
                gameplay.perfect,
                gameplay.good,
                gameplay.average,
                gameplay.miss,
                gameplay.boo,
                gameplay.combo,
                gameplay.maxCombo];

            vars[prefix + "_GAMESCORES"] = StringUtil.join(":", gamescores);
            vars[prefix + "_STATE"] = int(gameplay.status);
            vars[prefix + "_GAMELIFE"] = int(gameplay.life * 24 / 100);
            vars[prefix + "_SONGID"] = (gameplay.songInfo == null ? gameplay.songId : int(gameplay.songInfo.level));
            vars[prefix + "_SONGID_PROGRESS"] = int(gameplay.statusLoading);

            if (songEngine)
                vars["arc_engine" + user.playerIdx] = JSON.stringify(songEngine);
            else if (gameplay.songInfo === null || (gameplay.songInfo && !gameplay.songInfo.engine))
                vars["arc_engine" + user.playerIdx] = null;

            vars["arc_replay" + user.playerIdx] = gameplay.encodedReplay || null;

            sendRoomVariables(room, vars);
        }

        /**
         * Builds a request to update the current user's gameplay score
         * in the specified room and sends it to the server.
         */
        public function sendCurrentUserScore(room:Room):void
        {
            if (!room.hasUser(currentUser))
                return;

            var vars:Object = {};
            var user:User = currentUser;
            var gameplay:Gameplay = currentUser.gameplay;

            var prefix:String = "P" + user.playerIdx;

            // Ordering is important
            var gamescores:Array = [gameplay.score,
                gameplay.amazing,
                gameplay.perfect,
                gameplay.good,
                gameplay.average,
                gameplay.miss,
                gameplay.boo,
                gameplay.combo,
                gameplay.maxCombo];

            vars[prefix + "_GAMESCORES"] = StringUtil.join(":", gamescores);
            vars[prefix + "_GAMELIFE"] = int(gameplay.life * 24 / 100);

            sendRoomVariables(room, vars);
        }


        // =================================================== //
        // MP EVENT DISPATCHERS
        // =================================================== //

        private function eventError(message:String):void
        {
            dispatchEvent(new ErrorEvent({message: message}));
        }

        private function eventConnection():void
        {
            dispatchEvent(new ConnectionEvent());
        }

        private function eventLogin():void
        {
            dispatchEvent(new LoginEvent());
        }

        private function eventServerMessage(message:String, user:User = null):void
        {
            dispatchEvent(new ServerMessageEvent({message: StringUtil.stripMessage(message), user: user}));
        }

        private function eventMessage(type:int, room:Room, user:User, message:String):void
        {
            dispatchEvent(new MessageEvent({msgType: type, room: room, user: user, message: StringUtil.stripMessage(message)}));
        }

        private function eventRoomUserStatus(room:Room, user:User):void
        {
            dispatchEvent(new RoomUserStatusEvent({room: room, user: user}));
        }

        private function eventRoomJoined(room:Room):void
        {
            dispatchEvent(new RoomJoinedEvent({room: room}));
        }

        private function eventRoomLeft(room:Room):void
        {
            dispatchEvent(new RoomLeftEvent({room: room}));
        }

        private function eventRoomUpdate(room:Room, roomList:Boolean = false):void
        {
            dispatchEvent(new RoomUpdateEvent({room: room, roomList: roomList}));
        }

        private function eventGameUpdate(user:User):void
        {
            dispatchEvent(new GameUpdateEvent({user: user}))
        }

        private function eventRoomUser(room:Room, user:User):void
        {
            dispatchEvent(new RoomUserEvent({room: room, user: user}));
        }

        private function eventRoomList():void
        {
            dispatchEvent(new RoomListEvent());
        }

        private function eventUserUpdate(user:User):void
        {
            dispatchEvent(new UserUpdateEvent({user: user}));
        }

        private function eventGameStart(room:Room):void
        {
            dispatchEvent(new GameStartEvent({room: room}));
        }

        private function eventGameResults(room:Room):void
        {
            dispatchEvent(new GameResultsEvent({room: room}));
        }


        // =================================================== //
        // SFS EVENT HANDLERS
        // =================================================== //

        private function onConnection(event:ConnectionSFSEvent):void
        {
            connected = event.success;

            if (connected)
            {
                _rooms = {};
                currentUser = new User();
                ghostRooms = new <Room>[];
            }

            eventConnection();

            if (!connected)
                eventError("Multiplayer Connection Error: " + event.error);
        }

        private function onConnectionLost(event:ConnectionLostSFSEvent):void
        {
            connected = false;

            eventConnection();
            if (inSolo == false)
                eventError("Multiplayer Connection Lost");
        }

        CONFIG::debug
        {
            private function onDebugMessage(event:DebugMessageSFSEvent):void
            {
                //trace("arc_msg: SFS: " + event.params.message);
            }
        }

        private function onCreateRoomError(event:CreateRoomErrorSFSEvent):void
        {
            eventError("Create Room Failed: " + event.error);
        }

        private function onExtensionResponse(event:ExtensionResponseSFSEvent):void
        {
            var data:Object = event.dataObj;
            switch (data._cmd)
            {
                case "logOK":
                    currentUser.loggedIn = true;
                    currentUser.name = data.name;
                    currentUser.userClass = data.userclass;
                    currentUser.userColor = data.usercolor;
                    currentUser.userLevel = data.userlevel;
                    currentUser.id = data.userID;
                    currentUser.siteId = int(data.siteID);
                    currentUser.isModerator = (data.mod || data.userclass == CLASS_ADMIN || data.userclass == CLASS_FORUM_MOD || data.userclass == CLASS_CHAT_MOD || data.userclass == CLASS_MP_MOD);
                    currentUser.isAdmin = (data.userclass == CLASS_ADMIN);
                    currentUser.userStatus = 0;

                    setCurrentUserVariables();

                    // TODO: Check the usage of these and if they're absolutely needed internally for SFS
                    server.myUserId = currentUser.id;
                    server.myUserName = currentUser.name;
                    server.amIModerator = currentUser.isModerator;
                    server.playerId = -1;

                    eventLogin();
                    refreshRooms();
                    break;
                case "logKO":
                    currentUser.loggedIn = false;

                    eventLogin();
                    eventError("Login Failed: " + data.err);
                    break;
                case "specStatus":
                    /*var player1:int = int(data.p1i);
                       var player2:int = int(data.p2i);
                       if (player1 > 0) {

                       }
                       data.status;
                       data.p2i;
                       data.p2n;*/
                    break;
                case "stop": // when someone closes a room apparently
                    //data.n; // username
                    break;
                case "html_message":
                    data.uid = getRoomUserById(data.rid, data.uid);
                    data.rid = getRoom(data.rid);
                    dispatchEvent(new ExtensionResponseEvent({data: data}));
                    break;
            }
        }

        private function onLogout(event:LogoutSFSEvent):void
        {
            currentUser.loggedIn = false;
            eventLogin();
        }

        private function onAdminMessage(event:AdminMessageSFSEvent):void
        {
            eventServerMessage(StringUtil.htmlUnescape(event.message));
        }

        private function onModeratorMessage(event:ModerationMessageSFSEvent):void
        {
            if (event.userId)
            {
                var user:User = getRoomById(event.roomId).getUser(event.userId);
                eventServerMessage(StringUtil.htmlUnescape(event.message), user);
            }
        }

        private function onPlayerSwitched(event:PlayerSwitchedSFSEvent):void
        {
            var room:Room = getRoomById(event.roomId);
            var user:User = event.userId == 0 ? currentUser : getRoomUserById(room, event.userId);

            if (!user)
                return;

            if (user == currentUser)
                clearCurrentUserRoomVariables(room);

            room.removePlayer(user.playerIdx);
            user.isPlayer = false;
            user.playerIdx = -1;
            user.gameplay = null;

            room.specCount += 1;
            room.userCount -= 1;

            updateRoom(room);

            eventRoomUserStatus(room, user);
        }

        private function onSpectatorSwitched(event:SpectatorSwitchedSFSEvent):void
        {
            var room:Room = getRoomById(event.roomId);
            var user:User = event.userId == 0 ? currentUser : getRoomUserById(room, event.userId);

            if (!user)
                return;

            var newPlayerIdx:int = room.addPlayer(user);
            if (newPlayerIdx > 0)
            {
                user.isPlayer = true;
                user.playerIdx = newPlayerIdx;
            }

            if (user == currentUser)
            {
                sendCurrentUserRoomVariables(room, true);
            }

            room.specCount -= 1;
            room.userCount += 1;

            updateRoom(room);

            eventRoomUserStatus(room, user);
        }

        private function onPrivateMessage(event:PrivateMessageSFSEvent):void
        {
            if (event.userId == currentUser.id)
                return; // Ignore PM events sent by yourself because they don't include the recipient for some stupid reason

            var room:Room = getRoomById(event.roomId);
            var user:User = getRoomUserById(room, event.userId);

            if (user)
                eventMessage(MESSAGE_PRIVATE, room, user, StringUtil.htmlUnescape(event.message));
        }

        private function onPublicMessage(event:PublicMessageSFSEvent):void
        {
            var room:Room = getRoomById(event.roomId);
            var user:User = getRoomUserById(room, event.userId);

            if (user)
                eventMessage(MESSAGE_PUBLIC, room, user, StringUtil.htmlUnescape(event.message));
        }

        private function onRoomListUpdate(event:RoomListUpdateSFSEvent):void
        {
            for each (var evtRoom:Room in event.roomList)
            {
                var room:Room = getRoom(evtRoom);
                if (!room)
                    addRoom(evtRoom);
                else
                {
                    room.userCount = evtRoom.userCount;
                    room.specCount = evtRoom.specCount;

                    eventRoomUpdate(room);
                }
            }

            eventRoomList();
        }

        private function onRoomVariablesUpdate(event:RoomVariablesUpdateSFSEvent):void
        {
            var room:Room = getRoom(event.room);

            if (!room)
                return;

            // Apply new vars to the room from the event
            room.applyVariablesFromOtherRoom(event.room);

            // If the current user is not in the room, dont bother updating states further
            if (!room.hasUser(currentUser))
                return;
            // If the room isn't a game room, nothing else needs to be done
            if (!room.isGameRoom)
                return;

            // Update the room state
            updateRoom(room);

            eventRoomUpdate(room, true);

            for each (var user:User in room.players)
            {
                var gameplay:Gameplay = user.gameplay;
                if (gameplay && gameplay.status == STATUS_PLAYING)
                {
                    eventGameUpdate(user);
                }
            }
        }

        private function onRoomAdded(event:RoomAddedSFSEvent):void
        {
            addRoom(event.room);
            eventRoomList();
        }

        private function onRoomDeleted(event:RoomDeletedSFSEvent):void
        {
            var room:Room = getRoomById(event.roomId);

            if (room.getPlayerIndex(currentUser) > 0)
            {
                currentUser.isPlayer = false;
                currentUser.playerIdx = -1;
            }

            removeRoom(room);
            if (room.hasUser(currentUser))
                ghostRooms.push(room);

            eventRoomList();
        }

        /**
         * Called when the current player has left a room
         */
        private function onLeftRoom(event:LeftRoomSFSEvent):void
        {
            var room:Room = getRoomById(event.roomId);
            if (room == null)
            {
                for each (var ghost:Room in ghostRooms)
                {
                    if (ghost.id == event.roomId)
                    {
                        room = ghost;
                        ghostRooms = ghostRooms.filter(function(item:Room, index:int, vec:Vector.<Room>):Boolean
                        {
                            return item.id != ghost.id;
                        });
                        break;
                    }
                }
            }
            else
            {
                if (room.removePlayer(currentUser.playerIdx))
                {
                    currentUser.isPlayer = false;
                    currentUser.playerIdx = -1;
                    currentUser.gameplay = null;
                }

                room.clearPlayers();
                room.clearUsers();
            }

            updateRoom(room);

            eventRoomLeft(room);
        }

        /**
         * Called when the current player has joined a room.
         * This event populates the joined room with a user list.
         */
        private function onJoinedRoom(event:JoinedRoomSFSEvent):void
        {
            var room:Room = getRoom(event.room);

            // Adds the users to the room
            for each (var user:User in event.users)
            {
                if (user.id == currentUser.id)
                {
                    // This is necessary since the server does not provide `vars` for the logged in user
                    // on `joinOK` events. These `vars` are only provided in the `logOK` part of a `xtRes` event.
                    server.setUserVariables(currentUser.variables);

                    room.addUser(currentUser);

                    // Current user always gets -1 as a playerIdx on room join, so attempt to add it to players
                    if (room.isGameRoom && !currentUser.isPlayer)
                    {
                        var newPlayerIdx:int = room.addPlayer(currentUser);

                        if (newPlayerIdx > 0)
                        {
                            currentUser.isPlayer = true;
                            currentUser.playerIdx = newPlayerIdx;
                        }
                    }
                }
                else
                {
                    applyUserVariables(user);

                    room.addUser(user);

                    // If the user has a positive playerIdx, insert it in the room's players
                    if (room.isGameRoom && user.playerIdx > 0)
                        room.setPlayer(user.playerIdx, user);
                }
            }

            updateRoom(room);

            sendCurrentUserRoomVariables(room, true);
            if (room.isPlayer(currentUser))
                sendCurrentUserStatus(room);

            // Propagate the events
            eventUserUpdate(currentUser);
            eventRoomJoined(room);
        }

        private function onJoinRoomError(event:JoinRoomErrorSFSEvent):void
        {
            eventError("Join Failed: " + event.error);
        }

        private function onUserCountChange(event:UserCountChangeSFSEvent):void
        {
            // TODO: See if this is necessary
        }

        /**
         * Called when another user enters any room that the current user is in
         */
        private function onUserEnterRoom(event:UserEnterRoomSFSEvent):void
        {
            var room:Room = getRoomById(event.roomId);
            var user:User = event.user;

            // TODO: Check if actually needed, since uVars is called right after
            applyUserVariables(user);

            room.addUser(user);

            // Always attempt to add a new user to a room as a player
            if (room.isGameRoom)
                if (room.setPlayer(user.playerIdx, user))
                    updateUserGameplayFromRoom(room, user);

            eventRoomUser(room, user);
            eventRoomUpdate(room);
        }

        /**
         * Called when another user leaves any room that the current user is in
         */
        private function onUserLeftRoom(event:UserLeftRoomSFSEvent):void
        {
            var room:Room = getRoomById(event.roomId);
            var user:User = getRoomUserById(room, event.userId);

            if (user)
            {
                var playerIdx:int = room.getPlayerIndex(user);
                if (playerIdx > 0 && room.removePlayer(playerIdx))
                    user.playerIdx = -1;

                room.removeUser(user.id);
            }

            if (currentUser.isPlayer)
            {
                sendCurrentUserRoomVariables(room, false, true);
            }

            eventRoomUser(room, user);
            eventRoomUpdate(room);
        }

        private function onUserVariablesUpdate(event:UserVariablesUpdateSFSEvent):void
        {
            for each (var room:Room in rooms)
            {
                var user:User = room.getUser(event.user.id);
                if (!user)
                    continue;

                user.setVariables(event.user.variables)
                applyUserVariables(user);

                eventUserUpdate(user);
                return;
            }
        }
    }
}
