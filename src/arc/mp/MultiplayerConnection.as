package arc.mp
{
    import flash.events.EventDispatcher;
    import flash.xml.XMLDocument;
    import flash.xml.XMLNode;
    import flash.xml.XMLNodeType;

    import it.gotoandplay.smartfoxserver.SmartFoxClient;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.Room;
    import it.gotoandplay.smartfoxserver.data.User;

    import arc.ArcGlobals;

    public class MultiplayerConnection extends EventDispatcher
    {
        private static const serverAddress:String = Constant.ROOT_URL;
        private static const serverPort:int = 8082;
        private static const serverDebug:Boolean = CONFIG::debug;

        public static const EVENT_ERROR:String = "ARC_EVENT_ERROR";
        public static const EVENT_CONNECTION:String = "ARC_EVENT_CONNECTION";
        public static const EVENT_LOGIN:String = "ARC_EVENT_LOGIN";
        public static const EVENT_SERVER_MESSAGE:String = "ARC_EVENT_SERVER_MESSAGE";
        public static const EVENT_MESSAGE:String = "ARC_EVENT_MESSAGE";
        public static const EVENT_ROOM_LIST:String = "ARC_EVENT_ROOM_LIST";
        public static const EVENT_ROOM_USER_STATUS:String = "ARC_EVENT_ROOM_USER_STATUS";
        public static const EVENT_ROOM_USER:String = "ARC_EVENT_ROOM_USER";
        public static const EVENT_ROOM_UPDATE:String = "ARC_EVENT_ROOM_UPDATE";
        public static const EVENT_ROOM_JOINED:String = "ARC_EVENT_ROOM_JOINED";
        public static const EVENT_ROOM_LEFT:String = "ARC_EVENT_ROOM_LEFT";
        public static const EVENT_USER_UPDATE:String = "ARC_EVENT_USER_UPDATE";

        public static const MESSAGE_PUBLIC:int = 0;
        public static const MESSAGE_PRIVATE:int = 1;

        public static const CLASS_ADMIN:int = 1;
        public static const CLASS_BAND:int = 2;
        public static const CLASS_FORUM_MOD:int = 3;
        public static const CLASS_CHAT_MOD:int = 4; // Chat Mod + Profile Mod
        public static const CLASS_MP_MOD:int = 5;
        public static const CLASS_LEGEND:int = 6;
        public static const CLASS_AUTHOR:int = 7; // R1 Music Producer, R1 Simfile Author
        public static const CLASS_VETERAN:int = 8; // Subscriber
        public static const CLASS_USER:int = 9;
        public static const CLASS_BANNED:int = 10;
        public static const CLASS_ANONYMOUS:int = 11;

        public static const COLOURS:Array = [0x000000, 0xFF0000, 0x6F0094, 0x91FF00, 0x91FF00, 0x91FF00, 0xFF007E, 0xFF9A00, 0x0033CC, 0x000000, 0xFFFFFF, 0x333333];
        public static const CLASS_LEGACY:Array = [0, CLASS_ADMIN, CLASS_BAND, CLASS_FORUM_MOD, CLASS_CHAT_MOD, CLASS_MP_MOD, CLASS_AUTHOR, CLASS_VETERAN, CLASS_USER, CLASS_BANNED, CLASS_ANONYMOUS];

        public static const STATUS_NONE:int = 0;
        public static const STATUS_CLEANUP:int = 1;
        public static const STATUS_PICKING:int = 2;
        public static const STATUS_LOADING:int = 3;
        public static const STATUS_LOADED:int = 4;
        public static const STATUS_PLAYING:int = 5;
        public static const STATUS_RESULTS:int = 6;

        public static const STATUS_VELOCITY:Array = [STATUS_NONE, STATUS_CLEANUP, STATUS_PICKING, STATUS_LOADING, STATUS_LOADED, STATUS_PLAYING, STATUS_RESULTS];
        public static const STATUS_LEGACY:Array = [STATUS_NONE, STATUS_PLAYING, STATUS_PICKING, STATUS_LOADING, STATUS_RESULTS, STATUS_LOADED];

        public static const GAME_UNKNOWN:int = -1;
        public static const GAME_LEGACY:int = 1;
        public static const GAME_VELOCITY:int = 2;
        public static const GAME_R3:int = 3;

        public static const MODE_NORMAL:int = 0;
        public static const MODE_BATTLE:int = 1;
        public static const MODE_SCORE_RAW:int = 0;
        public static const MODE_SCORE_COMBO:int = 1;

        public static const GAME_VERSIONS:Array = ["Prochat", "Legacy", "Velocity", "R^3"];
        public static const SERVER_ZONES:Array = ["ffr_embedd", "ffr_mp", "ffr_mp_velocity", "ffr_multiplayer"];
        public static const SERVER_EXTENSIONS:Array = ["ffr_embeddZoneExt", "ffr_MPZoneExt", "ffr_MPZoneExtVelo", "FFR_EXT"];

        // Info about the game...
        // setUserVars: (done on join)
        // 		MP_Class = 8
        // 			1 - ADMIN
        // 			2 - BAND
        // 			3 - SUPER_MOD
        // 			4 - CHAT_MOD
        // 			5 - MP_MOD
        // 			6 - LEGEND
        // 			7 - SIM_AUTHOR
        // 			8 - SUBSCRIBER
        // 			9 - USER
        // 			10 - BANNED
        // 			11 - ANONYMOUS
        // 		MP_Level = 17
        //
        // roomVars in legacy:
        // 		player1 = username
        // 		player2 = username
        // 		mpstats1 = None Selected Yet:0:0:0:0:0:0:0:0:0:0
        // 		mpstats2 = None Selected Yet:0:0:0:0:0:0:0:0:0:0
        // 		0: score (raw)
        // 		1: life bar, caps at 24
        // 		2: max combo
        // 		3: combo
        // 		4: perfect
        // 		5: good
        // 		6: average
        // 		7: miss
        // 		8: boo
        // 		9: status (1 = playing, 3 = loading, 4 = done/results)
        // 	playerRoomVars: see setUserVars
        //
        // 	xtRes: (When I joined a room as a spectator)
        // 		_cmd = specStatus
        // 		status = 0
        //		p2i = 15164 (my userid)
        //		p2n = arcnmx (my username)
        //		(the 2 is the userid)
        //
        //	roomvars in velocity:
        //		p1_perfect = 5a (hexadecimal string)
        //		The 1 is the userid, also: _good, _average, _boo, _miss, _combo, _maxcombo
        //		_levelid, _levelloading (out of 100)
        //		_state (0 = ?, 1 = ?, 2 = picking song, 3 = loading, 4 = playing)
        //
        //		p1_name = username
        //		p1_uid = _root.uid
        //
        //	userid is actually not a userid, but a 1 or 2 for player 1/2
        //	All of velo uses dec2hex() for numeric roomvars

        private var server:SmartFoxClient;

        public var connected:Boolean;
        public var currentUser:Object;
        public var rooms:Array;
        public var ghostRooms:Array;
        public var lobby:Object;

        public var mode:int;

        /* currentUser:
         * loggedIn:Boolean
         * userName:String
         * userClass:int (See MP_Class above)
         * userLevel:int
         * userID:int (dunno)
         * siteID:int (forum ID)
         */

        /* room:
         * roomID
         * maxSpectatorCount
         * maxUserCount
         * name
         * users:Array
         * isGame
         * isPrivate
         * isTemp
         * playerID (your playerID in the room)
         * isPlayer (otherwise spectator)
         * userCount
         * spectatorCount
         * variables:Object
         * isLimbo (dunno)
         * isJoined (if you're in the room)
         */

        /* user
         * room:Room
         * userID
         * userName
         * playerID
         * variables:Object
         * isPlayer
         */

        public function MultiplayerConnection(_mode:int = GAME_R3)
        {
            currentUser = new Object();
            rooms = new Array();
            ghostRooms = new Array();
            mode = _mode;

            server = new SmartFoxClient(serverDebug);

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
            server.addEventListener(SFSEvent.onRoomLeft, onRoomLeft);
            server.addEventListener(SFSEvent.onJoinRoom, onJoinRoom);
            server.addEventListener(SFSEvent.onJoinRoomError, onJoinRoomError);
            server.addEventListener(SFSEvent.onUserCountChange, onUserCountChange);
            server.addEventListener(SFSEvent.onUserEnterRoom, onUserEnterRoom);
            server.addEventListener(SFSEvent.onUserLeaveRoom, onUserLeaveRoom);
            server.addEventListener(SFSEvent.onUserVariablesUpdate, onUserVariablesUpdate);
        }

        public function connect():void
        {
            server.connect(serverAddress, serverPort);
        }

        public function disconnect():void
        {
            server.disconnect();
        }

        public function login(username:String, password:String):void
        {
            if (connected)
                server.login(SERVER_ZONES[mode], username, password);
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
                    server.sendModeratorMessage(message, SmartFoxClient.MODMSG_TO_USER, target.userID);
                else if (target.roomID != null)
                    server.sendModeratorMessage(message, SmartFoxClient.MODMSG_TO_ROOM, target.roomID);
            }
        }

        public function nukeRoom(room:Object):void
        {
            if (connected && room)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "nuke_room", {"room": room.roomID});
        }

        public function muteUser(user:Object, time:int = 2, ipBan:Boolean = false):void
        {
            if (connected && user)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "mute_user", {"user": user.userName, "bantime": time, "ip": (ipBan ? 1 : 0)});
        }

        public function banUser(user:Object, time:int = 2, ipBan:Boolean = false):void
        {
            if (connected && user)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "ban_user", {"user": user.userName, "bantime": time, "ip": (ipBan ? 1 : 0)});
        }

        public function getUserList(room:Object):void
        {
            if (connected && room)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "getUserList", {"room": room.roomID});
        }

        public function getUserVariables(... users):void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "getUserVariables", {"users": users});
        }

        public function getMultiplayerLevel():void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "getMultiplayerLevel", {});
        }

        public function reportSongStart(room:Object):void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "playerStart", {}, "xml", room.roomID);
        }

        public function reportSongEnd(room:Object):void
        {
            if (connected)
                server.sendXtMessage(SERVER_EXTENSIONS[mode], "playerFinish", {}, "xml", room.roomID);
        }

        public function refreshRooms():void
        {
            if (connected)
                server.getRoomList();
        }

        public function joinRoom(room:Object, player:Boolean = true, password:String = ""):void
        {
            player &&= !isPlayer();
            if (connected && room)
                server.joinRoom(room.roomID, password, !player, true);
        }

        public function leaveRoom(room:Object):void
        {
            if (connected && room)
            {
                clearRoomPlayer(room);
                server.leaveRoom(room.roomID);
            }
        }

        public function switchRole(room:Object):void
        {
            if (connected && room && room.isJoined)
            {
                if (room.user.isPlayer)
                    server.switchPlayer(room.roomID);
                else
                {
                    if (isPlayer())
                        eventError("You cannot be a player in more than one game");
                    else
                        server.switchSpectator(room.roomID);
                }
            }
        }

        public function createRoom(name:String, password:String = "", maxUsers:int = 2, maxSpectators:int = 100):void
        {
            if (connected && name)
            {
                var params:Object = new Object();
                params.name = (mode == GAME_R3) ? name : "[" + currentUser.userLevel + "] " + name;
                params.password = password;
                params.maxUsers = maxUsers;
                params.maxSpectators = maxSpectators;
                params.isGame = true;
                params.exitCurrentRoom = false;
                params.uCount = true;
                params.joinAsSpectator = isPlayer();
                if (mode == GAME_R3)
                {
                    params.vars = [{name: "GAME_LEVEL", val: currentUser.userLevel, persistent: true},
                        {name: "GAME_MODE", val: MODE_NORMAL, persistent: true},
                        {name: "GAME_SCORE", val: MODE_SCORE_RAW, persistent: true},
                        {name: "GAME_RANKED", val: true, persistent: true}];
                }
                server.createRoom(params);
            }
        }

        public function joinLobby():void
        {
            joinRoom(lobby);
        }

        public function sendMessage(room:Object, message:String, escape:Boolean = true):void
        {
            if (connected && room && message)
                server.sendPublicMessage(escape ? htmlEscape(message) : message, room.roomID);
        }

        public function sendPrivateMessage(user:Object, message:String, room:Object = null):void
        {
            if (connected && user && message)
                server.sendPrivateMessage(htmlEscape(message), user.userID, (room ? room.roomID : -1));
        }

        public function getRoomGameplay(room:Object):Object
        {
            var vars:Object = new Object();
            for each (var user:Object in room.users)
            {
                if (user.isPlayer)
                    vars["player" + user.playerID] = parseRoomVariablesForUser(room, user);
            }
            return vars;
        }

        public static function nameRoom(room:Object):String
        {
            return room.name + " (" + room.userCount + "/" + room.maxUserCount + ") - (" + room.spectatorCount + "/" + room.maxSpectatorCount + ")";
        }

        public static function hex2dec(hex:String):int
        {
            return parseInt(hex, 16);
        }

        public static function dec2hex(dec:int):String
        {
            return dec.toString(16).toUpperCase();
        }

        private function parseRoomVariablesForUser(room:Object, user:Object):Object
        {
            var ret:Object = new Object();
            var vars:Object = room.variables;
            var stats:Array;
            switch (mode)
            {
                case GAME_VELOCITY:
                    var prefix:String = "p" + user.playerID;
                    ret.maxCombo = hex2dec(vars[prefix + "_maxcombo"]);
                    ret.combo = hex2dec(vars[prefix + "_combo"]);
                    ret.perfect = hex2dec(vars[prefix + "_perfect"]);
                    ret.good = hex2dec(vars[prefix + "_good"]);
                    ret.average = hex2dec(vars[prefix + "_average"]);
                    ret.boo = hex2dec(vars[prefix + "_boo"]);
                    ret.miss = hex2dec(vars[prefix + "_miss"]);
                    ret.songID = hex2dec(vars[prefix + "_levelid"]);
                    ret.statusLoading = hex2dec(vars[prefix + "_levelloading"]);
                    ret.status = STATUS_VELOCITY[hex2dec(vars[prefix + "_state"])];
                    ret.siteID = hex2dec(vars[prefix + "_uid"]);
                    ret.userName = vars[prefix + "_name"];
                    ret.score = ret.perfect * 50 + ret.good * 25 + ret.average * 5 - ret.miss * 10 - ret.boo * 5;
                    ret.amazing = 0;
                    ret.life = 24;
                    break;
                case GAME_LEGACY:
                    stats = String(vars["mpstats" + user.playerID]).split(":");
                    ret.songName = stats[0] || "No Song Selected";
                    ret.score = int(stats[1]);
                    ret.life = int(stats[2]);
                    ret.maxCombo = int(stats[3]);
                    ret.combo = int(stats[4]);
                    ret.perfect = int(stats[5]);
                    ret.good = int(stats[6]);
                    ret.average = int(stats[7]);
                    ret.miss = int(stats[8]);
                    ret.boo = int(stats[9]);
                    ret.status = STATUS_LEGACY[int(stats[10])];
                    ret.amazing = 0;
                    var loading:Object = vars["arc_status_loading" + user.playerID];
                    if (loading != null)
                        ret.statusLoading = int(loading);
                    break;
                case GAME_R3:
                    stats = String(vars["P" + user.playerID + "_GAMESCORES"]).split(":");
                    ret.score = int(stats[0]);
                    ret.amazing = int(stats[1]);
                    ret.perfect = int(stats[2]);
                    ret.good = int(stats[3]);
                    ret.average = int(stats[4]);
                    ret.miss = int(stats[5]);
                    ret.boo = int(stats[6]);
                    ret.combo = int(stats[7]);
                    ret.maxCombo = int(stats[8]);
                    ret.status = int(vars["P" + user.playerID + "_STATE"]);
                    ret.songID = int(vars["P" + user.playerID + "_SONGID"]);
                    ret.statusLoading = int(vars["P" + user.playerID + "_SONGID_PROGRESS"]);
                    ret.life = int(vars["P" + user.playerID + "_GAMELIFE"]);
                    break;
            }
            var engine:Object = vars["arc_engine" + user.playerID];
            if (engine != null)
            {
                engine = JSONManager.decode(engine);
                ret.legacy_engineID = engine.engineID;
                ret.legacy_engine = ArcGlobals.instance.legacyEngine(ret.legacy_engineID);
                ret.legacy_songID = engine.songID;
                if (mode != GAME_LEGACY)
                    ret.legacy_songName = engine.songName;
                ret.legacy_sync = engine.sync;
                ret.legacy_songAuthor = engine.songAuthor;
                ret.legacy_stepAuthor = engine.stepAuthor;
                ret.legacy_ffrlURL = engine.ffrlURL;
                ret.legacy_type = engine.type;
            }
            return ret;
        }

        public function setRoomVariables(room:Object, data:Object, changeOwnership:Boolean = true):void
        {
            var varArray:Array = new Array();
            for (var name:String in data)
                varArray.push({name: name, val: data[name]});
            if (varArray.length > 0)
                server.setRoomVariables(varArray, room.roomID, changeOwnership);
        }

        private function clearRoomPlayer(room:Object):void
        {
            var vars:Object = new Object();
            if (room.isGame && room.isJoined && room.user.isPlayer)
            {
                var prefix:String = room.user.playerID;
                switch (mode)
                {
                    case GAME_R3:
                        prefix = "P" + prefix;
                        vars[prefix + "_NAME"] = null;
                        vars[prefix + "_UID"] = null;
                        break;
                    case GAME_VELOCITY:
                        prefix = "p" + prefix;
                        vars[prefix + "_name"] = null;
                        vars[prefix + "_uid"] = null;
                        break;
                    case GAME_LEGACY:
                        vars["player" + prefix] = null;
                        vars["mpstats" + prefix] = null;
                        break;
                }
                vars["arc_engine" + room.user.playerID] = null;
            }
            setRoomVariables(room, vars);
        }

        private function setRoomPlayer(room:Object):void
        {
            var vars:Object = new Object();
            if (room.isGame && room.isJoined && room.user.isPlayer)
            {
                var prefix:String = room.user.playerID;
                switch (mode)
                {
                    case GAME_R3:
                        prefix = "P" + prefix;
                        vars[prefix + "_NAME"] = currentUser.userName;
                        vars[prefix + "_UID"] = currentUser.siteID;
                        var opponent:Boolean = false;
                        for each (var user:Object in room.users)
                        {
                            if (user.isPlayer && user.userID != currentUser.userID)
                                opponent = true;
                        }
                        if (!opponent)
                            setRoomVariables(room, {"GAME_LEVEL": currentUser.userLevel}, false);
                        break;
                    case GAME_VELOCITY:
                        prefix = "p" + prefix;
                        vars[prefix + "_name"] = currentUser.userName;
                        vars[prefix + "_uid"] = dec2hex(currentUser.siteID);
                        break;
                    case GAME_LEGACY:
                        vars["player" + prefix] = currentUser.userName;
                        vars["mpstats" + prefix] = "No Song Selected:0:0:0:0:0:0:0:0:0:0";
                        break;
                }
            }
            setRoomVariables(room, vars);
        }

        private function updateUserVariables():void
        {
            var vars:Object = new Object();
            switch (mode)
            {
                case GAME_R3:
                    vars["UID"] = currentUser.siteID;
                    vars["GAME_VER"] = GAME_VERSIONS[GAME_R3];
                    vars["MP_LEVEL"] = currentUser.userLevel;
                    vars["MP_CLASS"] = currentUser.userClass;
                    vars["MP_COLOR"] = currentUser.userColour;
                    vars["MP_STATUS"] = currentUser.userStatus;
                    break;
                default:
                    vars["MP_Level"] = currentUser.userLevel;
                    vars["MP_Class"] = CLASS_LEGACY.indexOf(currentUser.userClass);
                    vars["MP_Color"] = currentUser.userColour;
                    break;
            }
            server.setUserVariables(vars);

            var foundSfsUser:User = null;
            for each (var sfsRoom:Room in server.getAllRooms())
            {
                for each (var sfsUser:User in sfsRoom.getUserList())
                {
                    if (sfsUser.getId() == currentUser.userID)
                    {
                        foundSfsUser = sfsUser;
                        break;
                    }
                }
            }
            updateUser(foundSfsUser);

            var found:Object = null;
            for each (var room:Object in rooms)
            {
                for each (var user:Object in room.users)
                {
                    if (user.userID == currentUser.userID)
                    {
                        found = user;
                        break;
                    }
                }
                if (found != null)
                    break;
            }
            eventUserUpdate(found);
        }

        public function setRoomGameplay(room:Object, data:Object):void
        {
            var vars:Object = new Object();
            if (room.isJoined && room.user.isPlayer)
            {
                switch (mode)
                {
                    case GAME_VELOCITY:
                        var prefix:String = "p" + room.user.playerID;
                        vars[prefix + "_maxcombo"] = dec2hex(data.maxCombo);
                        vars[prefix + "_combo"] = dec2hex(data.combo);
                        vars[prefix + "_perfect"] = dec2hex(data.amazing + data.perfect);
                        vars[prefix + "_good"] = dec2hex(data.good);
                        vars[prefix + "_average"] = dec2hex(data.average);
                        vars[prefix + "_boo"] = dec2hex(data.boo);
                        vars[prefix + "_miss"] = dec2hex(data.miss);
                        vars[prefix + "_levelid"] = dec2hex(data.song == null ? data.songID : int(data.song.level));
                        var statusLoading:int = data.statusLoading;
                        vars[prefix + "_levelloading"] = dec2hex(statusLoading);
                        vars[prefix + "_state"] = dec2hex(STATUS_VELOCITY.indexOf(data.status));
                        if (data.gameScoreRecorded != null)
                            vars["gameScoreRecorded"] = data.gameScoreRecorded;
                        break;
                    case GAME_LEGACY:
                        var status:int = data.status;
                        switch (status)
                        {
                            case STATUS_LOADED:
                                status = STATUS_PLAYING;
                                break;
                            case STATUS_PICKING:
                                status = STATUS_NONE;
                                break;
                        }
                        vars["mpstats" + room.user.playerID] = String((data.songName != null ? data.songName : data.song.name)).replace(/:/g, "") + ":" + int(data.score) + ":" + int(data.life) + ":" + int(data.maxCombo) + ":" + int(data.combo) + ":" + int(data.amazing + data.perfect) + ":" + int(data.good) + ":" + int(data.average) + ":" + int(data.miss) + ":" + int(data.boo) + ":" + STATUS_LEGACY.indexOf(status);
                        if (data.statusLoading != null)
                            vars["arc_status_loading" + room.user.playerID] = int(data.statusLoading);
                        else
                            vars["arc_status_loading" + room.user.playerID] = null;
                        break;
                    case GAME_R3:
                        vars["P" + room.user.playerID + "_GAMESCORES"] = int(data.score) + ":" + int(data.amazing) + ":" + int(data.perfect) + ":" + int(data.good) + ":" + int(data.average) + ":" + int(data.miss) + ":" + int(data.boo) + ":" + int(data.combo) + ":" + int(data.maxCombo);
                        vars["P" + room.user.playerID + "_STATE"] = int(data.status);
                        vars["P" + room.user.playerID + "_GAMELIFE"] = int(data.life * 24 / 100);
                        vars["P" + room.user.playerID + "_SONGID"] = (data.song == null ? data.songID : int(data.song.level));
                        vars["P" + room.user.playerID + "_SONGID_PROGRESS"] = int(data.statusLoading);
                        break;
                }
                if (data.song != null && data.song.engine != null)
                {
                    var engineVars:Object = {engineID: data.song.engine.id,
                            songID: data.song.levelid,
                            songAuthor: data.song.author,
                            stepAuthor: data.song.stepauthor,
                            ffrlURL: data.song.engine.songURL,
                            type: data.song.type};

                    if (mode != GAME_LEGACY)
                        engineVars.songName = data.song.name;
                    if (data.song.sync != null)
                        engineVars.sync = data.song.sync;

                    vars["arc_engine" + room.user.playerID] = JSONManager.encode(engineVars);
                }
                else if (data.song === null || (data.song && !data.song.engine))
                    vars["arc_engine" + room.user.playerID] = null;
            }
            setRoomVariables(room, vars);
        }

        private function parseUserVariables(user:Object):void
        {
            var vars:Object = user.variables;
            switch (mode)
            {
                case GAME_R3:
                    user.siteID = vars["UID"];
                    user.gameVersion = GAME_VERSIONS.indexOf(vars["GAME_VER"]);
                    user.userLevel = vars["MP_LEVEL"];
                    user.userClass = vars["MP_CLASS"];
                    user.userColour = vars["MP_COLOR"];
                    user.userStatus = vars["MP_STATUS"];
                    break;
                default:
                    user.userLevel = vars["MP_Level"];
                    user.userClass = CLASS_LEGACY[vars["MP_Class"]];
                    user.userColor = vars["MP_Color"];
                    break;
            }
        }

        public function isPlayer():Boolean
        {
            for each (var room:Object in rooms)
            {
                if (room.isGame && room.isJoined && room.user.isPlayer)
                    return true;
            }
            return false;
        }

        private function clearRooms():void
        {
            rooms = new Array();
        }

        private function removeRoom(sfsRoom:*):void
        {
            var room:Object = getRoom(sfsRoom);
            var index:int = rooms.indexOf(room);
            if (index >= 0)
                rooms.splice(index, 1);
        }

        private function addRoom(sfsRoom:*):void
        {
            if (!(sfsRoom is Room))
                sfsRoom = server.getRoom(sfsRoom);

            var room:Object = new Object();
            room.connection = this;
            room.roomID = sfsRoom.getId();
            room.maxSpectatorCount = sfsRoom.getMaxSpectators();
            room.maxUserCount = sfsRoom.getMaxUsers();
            room.name = sfsRoom.getName();
            room.users = new Array();
            room.isGame = sfsRoom.isGame();
            room.isPrivate = sfsRoom.isPrivate();
            room.isTemp = sfsRoom.isTemp();
            rooms.push(room);

            if (room.name == "Lobby")
                lobby = room;

            updateRoom(sfsRoom);
        }

        private function updateRoom(sfsRoom:*):void
        {
            if (!(sfsRoom is Room))
                sfsRoom = server.getRoom(sfsRoom);

            var room:Object = getRoom(sfsRoom);
            var user:Object;

            if (room == null)
                return;

            room.userCount = sfsRoom.getUserCount();
            room.spectatorCount = sfsRoom.getSpectatorCount();
            room.variables = sfsRoom.getVariables();
            room.isLimbo = sfsRoom.isLimbo();
            room.isJoined = false;
            room.user = null;
            room.users = room.users.filter(function(item:*, index:int, array:Array):Boolean
            {
                var ret:Boolean = sfsRoom.getUser(item.userID) != null;
                if (!ret)
                    item.room = null;
                return ret;
            });
            for each (var sfsUser:User in sfsRoom.getUserList())
            {
                if (getUser(room.roomID, sfsUser) == null)
                {
                    user = new Object();
                    user.room = room;
                    user.userID = sfsUser.getId();
                    user.userName = sfsUser.getName();
                    user.isModerator = sfsUser.isModerator();
                    room.users.push(user);
                }
            }
            for each (user in room.users)
            {
                sfsUser = sfsRoom.getUser(user.userID);
                user.playerID = sfsUser.getPlayerId();
                user.variables = sfsUser.getVariables();
                parseUserVariables(user);
                user.isPlayer = !sfsUser.isSpectator();
                if (user.userID == currentUser.userID)
                {
                    room.isJoined = true;
                    room.user = user;
                }
            }
            if (mode == GAME_R3)
                room.level = room.variables["GAME_LEVEL"];
            else
            {
                var name:Array = new RegExp("\\[(\\d+)\\] (.+)").exec(sfsRoom.getName());
                if (name)
                {
                    room.name = name[2];
                    room.level = parseInt(name[1]);
                }
            }
        }

        private function updateUser(sfsUser:User):void
        {
            for each (var room:Object in rooms)
            {
                for each (var user:Object in room.users)
                {
                    if (user.userID == sfsUser.getId())
                    {
                        user.variables = sfsUser.getVariables();
                        parseUserVariables(user);
                    }
                }
            }
        }

        private function findUser(sfsUser:User):Object
        {
            for each (var room:Object in rooms)
            {
                for each (var user:Object in room.users)
                {
                    if (user.userID == sfsUser.getId())
                        return user;
                }
            }

            return null;
        }

        private function getRoom(sfsRoom:*):Object
        {
            var roomId:int;
            if (sfsRoom is Room)
                roomId = Room(sfsRoom).getId();
            else
                roomId = int(sfsRoom);

            for each (var room:Object in rooms)
            {
                if (room.roomID == roomId)
                    return room;
            }

            return null;
        }

        private function getUser(sfsRoom:*, sfsUser:*):Object
        {
            var room:Object = getRoom(sfsRoom);
            var userId:int;
            if (sfsUser is User)
                userId = User(sfsUser).getId();
            else
                userId = int(sfsUser);

            for each (var user:Object in room.users)
            {
                if (user.userID == userId)
                    return user;
            }

            return null;
        }

        private function eventError(message:String):void
        {
            dispatchEvent(new SFSEvent(EVENT_ERROR, {message: message}));
        }

        private function eventConnection():void
        {
            dispatchEvent(new SFSEvent(EVENT_CONNECTION, {}));
        }

        private function eventLogin():void
        {
            dispatchEvent(new SFSEvent(EVENT_LOGIN, {}));
        }

        private function eventServerMessage(message:String, user:Object = null):void
        {
            dispatchEvent(new SFSEvent(EVENT_SERVER_MESSAGE, {message: stripMessage(message), user: user}));
        }

        private function eventMessage(type:int, room:Object, user:Object, message:String):void
        {
            dispatchEvent(new SFSEvent(EVENT_MESSAGE, {type: type, room: room, user: user, message: stripMessage(message)}));
        }

        private function eventRoomUserStatus(room:Object, user:Object):void
        {
            dispatchEvent(new SFSEvent(EVENT_ROOM_USER_STATUS, {room: room, user: user}));
        }

        private function eventRoomJoined(room:Object):void
        {
            dispatchEvent(new SFSEvent(EVENT_ROOM_JOINED, {room: room}));
        }

        private function eventRoomLeft(room:Object):void
        {
            dispatchEvent(new SFSEvent(EVENT_ROOM_LEFT, {room: room}));
        }

        private function eventRoomUpdate(room:Object, roomList:Boolean = false, changed:Array = null):void
        {
            dispatchEvent(new SFSEvent(EVENT_ROOM_UPDATE, {room: room, roomList: roomList, changed: (changed || [])}));
        }

        private function eventRoomUser(room:Object, user:Object):void
        {
            dispatchEvent(new SFSEvent(EVENT_ROOM_USER, {room: room, user: user}));
        }

        private function eventRoomList():void
        {
            dispatchEvent(new SFSEvent(EVENT_ROOM_LIST, {}));
        }

        private function eventUserUpdate(user:Object, changed:Array = null):void
        {
            dispatchEvent(new SFSEvent(EVENT_USER_UPDATE, {user: user, changed: (changed || [])}));
        }

        private function onConnection(event:SFSEvent):void
        {
            connected = event.params.success;

            eventConnection();

            if (!connected)
                eventError("Multiplayer Connection Error: " + event.params.error);
        }

        private function onConnectionLost(event:SFSEvent):void
        {
            connected = false;

            eventConnection();
            eventError("Multiplayer Connection Lost");
        }

        CONFIG::debug
        {
            private function onDebugMessage(event:SFSEvent):void
            {
                //trace("arc_msg: SFS: " + event.params.message);
            }
        }

        private function onCreateRoomError(event:SFSEvent):void
        {
            eventError("Create Room Failed: " + event.params.error);
        }

        private function onExtensionResponse(event:SFSEvent):void
        {
            var data:Object = event.params.dataObj;
            switch (data._cmd)
            {
                case "logOK":
                    currentUser.loggedIn = true;
                    currentUser.userName = data.name;
                    currentUser.userClass = (mode == GAME_R3 ? data.userclass : CLASS_LEGACY[data.userclass]);
                    currentUser.userColour = data.usercolor;
                    currentUser.userLevel = data.userlevel;
                    currentUser.userID = data.userID;
                    currentUser.siteID = data.siteID;
                    currentUser.isModerator = (data.mod || data.userclass == CLASS_ADMIN || data.userclass == CLASS_FORUM_MOD || data.userclass == CLASS_CHAT_MOD || data.userclass == CLASS_MP_MOD);
                    currentUser.userStatus = 0;

                    // HACK: SysHandler.handleLoginOk() is never called, so fill in some vars for SFS
                    server.myUserId = currentUser.userID;
                    server.myUserName = currentUser.userName;
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
            }
        }

        private function onLogout(event:SFSEvent):void
        {
            currentUser.loggedIn = false;
            eventLogin();
        }

        private function onAdminMessage(event:SFSEvent):void
        {
            eventServerMessage(htmlUnescape(event.params.message));
        }

        private function onModeratorMessage(event:SFSEvent):void
        {
            var user:Object = null;
            if (event.params.sender != null)
                user = findUser(event.params.sender);
            eventServerMessage(htmlUnescape(event.params.message), user);
        }

        private function onPlayerSwitched(event:SFSEvent):void
        {
            if (event.params.success)
            {
                var room:Object = getRoom(event.params.room);
                var user:Object = getUser(event.params.room, event.params.userId);
                if (user.userID == currentUser.userID)
                    clearRoomPlayer(room);
                updateRoom(event.params.room);
                eventRoomUserStatus(room, user);
            }
            else if (event.params.userId == currentUser.userID)
            {
                eventError("Spectate Failed");
            }
        }

        private function onSpectatorSwitched(event:SFSEvent):void
        {
            if (event.params.success)
            {
                var room:Object = getRoom(event.params.room);
                var user:Object = getUser(event.params.room, event.params.userId);
                updateRoom(event.params.room);
                if (user.userID == currentUser.userID)
                    setRoomPlayer(room);
                eventRoomUserStatus(room, user);
            }
            else if (event.params.userId == currentUser.userID)
            {
                eventError("Join Failed");
            }
        }

        private function onPrivateMessage(event:SFSEvent):void
        {
            if (event.params.userId == currentUser.userID)
                return; // XXX: Ignore PM events sent by yourself because they don't include the recipient for some stupid reason
            var room:Room = server.getRoom(event.params.roomId);
            var user:User = event.params.sender;
            if (user == null)
                user = room.getUser(event.params.userId);
            eventMessage(MESSAGE_PRIVATE, getRoom(room), getUser(room, user), htmlUnescape(event.params.message));
        }

        private function onPublicMessage(event:SFSEvent):void
        {
            var room:Room = server.getRoom(event.params.roomId);
            var user:User = event.params.sender;
            if (user == null)
                user = room.getUser(event.params.userId);
            eventMessage(MESSAGE_PUBLIC, getRoom(room), getUser(room, user), htmlUnescape(event.params.message));
        }

        private function onRoomListUpdate(event:SFSEvent):void
        {
            clearRooms();
            for each (var room:Room in event.params.roomList)
                addRoom(room);
            eventRoomList();
        }

        private function onRoomVariablesUpdate(event:SFSEvent):void
        {
            updateRoom(event.params.room);
            eventRoomUpdate(getRoom(event.params.room), event.params.roomList, event.params.changedVars);
        }

        private function onRoomAdded(event:SFSEvent):void
        {
            addRoom(event.params.room);
            eventRoomList();
        }

        private function onRoomDeleted(event:SFSEvent):void
        {
            var room:Object = getRoom(event.params.room);
            removeRoom(event.params.room);
            if (room.isJoined)
                ghostRooms.push(room);
            eventRoomList();
        }

        private function onRoomLeft(event:SFSEvent):void
        {
            var room:Object = getRoom(event.params.roomId);
            if (room == null)
            {
                for each (var ghost:Object in ghostRooms)
                {
                    if (ghost.roomID == event.params.roomId)
                    {
                        room = ghost;
                        ghostRooms = ghostRooms.filter(function(item:*, index:int, array:Array):Boolean
                        {
                            return item.roomID != ghost.roomID;
                        });
                        break;
                    }
                }
            }
            updateRoom(event.params.roomId);
            room.isJoined = false;
            eventRoomLeft(room);
        }

        private function onJoinRoom(event:SFSEvent):void
        {
            updateRoom(event.params.room);
            var room:Object = getRoom(event.params.room);
            setRoomPlayer(room);
            updateUserVariables();
            updateUser(event.params.room.getUserList()[currentUser.userID]);
            eventRoomJoined(room);
        }

        private function onJoinRoomError(event:SFSEvent):void
        {
            eventError("Join Failed: " + event.params.error);
        }

        private function onUserCountChange(event:SFSEvent):void
        {
            updateRoom(event.params.room);
            eventRoomUpdate(getRoom(event.params.room));
        }

        private function onUserEnterRoom(event:SFSEvent):void
        {
            updateRoom(event.params.roomId);
            eventRoomUser(getRoom(event.params.roomId), getUser(event.params.roomId, event.params.user));
            eventRoomUpdate(getRoom(event.params.roomId));
        }

        private function onUserLeaveRoom(event:SFSEvent):void
        {
            var user:Object = getUser(event.params.roomId, event.params.userId);
            var room:Object = getRoom(event.params.roomId);
            updateRoom(event.params.roomId);
            eventRoomUser(room, user);
            eventRoomUpdate(room);
        }

        private function onUserVariablesUpdate(event:SFSEvent):void
        {
            updateUser(event.params.user);
            eventUserUpdate(findUser(event.params.user), event.params.changedVars);
        }

        public static function htmlUnescape(str:String):String
        {
            try
            {
                return new XMLDocument(str).firstChild.nodeValue;
            }
            catch (error:Error)
            {
            }
            return str;
        }

        public static function htmlEscape(str:String):String
        {
            return XML(new XMLNode(XMLNodeType.TEXT_NODE, str)).toXMLString();
        }

        private static function stripMessage(str:String):String
        {
            while (str.length && str.charAt(str.length - 1) == '\n')
                str = str.substr(0, str.length - 1);
            while (str.length && str.charAt(0) == '\n')
                str = str.substr(1);
            return str;
        }
    }
}
