package
{
    import arc.mp.MultiplayerSingleton;
    import be.aboutme.airserver.AIRServer;
    import be.aboutme.airserver.endpoints.socket.SocketEndPoint;
    import be.aboutme.airserver.endpoints.socket.handlers.websocket.WebSocketClientHandlerFactory;
    import be.aboutme.airserver.messages.Message;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.SongPlayerBytes;
    import classes.StatTracker;
    import classes.User;
    import classes.chart.Song;
    import classes.filter.EngineLevelFilter;
    import com.flashfla.loader.DataEvent;
    import com.flashfla.net.DynamicURLLoader;
    import com.flashfla.utils.Screenshots;
    import fi.joniaromaa.adobeair.discordrpc.DiscordRpc;
    import flash.display.StageDisplayState;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filesystem.File;
    import flash.media.SoundTransform;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.system.Capabilities;
    import flash.utils.ByteArray;
    import game.GameOptions;
    import game.GameScoreResult;

    public class GlobalVariables extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:GlobalVariables = null;
        private var _loader:DynamicURLLoader;

        ///- Constants
        public static const LOAD_COMPLETE:String = "LoadComplete";
        public static const LOAD_ERROR:String = "LoadError";
        public static const HIGHSCORES_LOAD_COMPLETE:String = "HighscoresLoadComplete";
        public static const HIGHSCORES_LOAD_ERROR:String = "HighscoresLoadError";

        public var flashvars:Object;
        public var gameMain:Main;

        public var options:GameOptions;

        ///- Game Data
        public var TOTAL_GENRES:uint = 13;
        public var TOTAL_SONGS:uint = 0;
        public var TOTAL_PUBLIC_SONGS:uint = 0;
        public var HEALTH_JUDGE_ADD:int = 5;
        public var HEALTH_JUDGE_REMOVE:int = -5;
        public var TOTAL_STEPS:int = 31;
        public var BEAT_DELAY:int = -31;
        public var MAX_CREDITS:int = 120;
        public var SCORE_PER_CREDIT:int = 50000;
        public var MAX_DIFFICULTY:int = 120;
        public var DIFFICULTY_RANGES:Array = [[1, 120]];
        public var NONPUBLIC_GENRES:Array = [];
        public var TOKENS:Object = {};
        public var TOKENS_TYPE:Object = {};
        public var SCROLL_DIRECTIONS:Array = ["up", "down", "left", "right", "split", "split_down", "plus"];
        public var GAME_MODS:Array = ["hidden", "sudden", "blink", "----", "rotating", "rotate_cw", "rotate_ccw", "wave", "drunk", "tornado", "mini_resize", "tap_pulse", "----", "random", "scramble", "shuffle", "reverse"];
        public var VISUAL_MODS:Array = ["mirror", "dark", "hide", "mini", "columncolour", "halftime", "----", "nobackground"];
        public var songStartTime:String = "0";
        public var songStartHash:String = "0";
        public var songCache:Array = [];
        public var songHighscores:Object = {};

        public static var divisionColor:Array = [0xC27BA0, 0x8E7CC3, 0x6D9EEB, 0x93C47D, 0xCEA023, 0xE06666, 0x919C86, 0xD2C7AC, 0xBF0000];
        public static var divisionTitle:Array = ["Novice", "Intermediate", "Advanced", "Expert", "Master", "Guru", "Legendary", "Godly", "Developer"];
        public static var divisionLevel:Array = [0, 26, 50, 59, 69, 83, 94, 101, 122];

        ///- User Vars
        public var userSession:String = "0";
        public var activeUser:User;
        public var playerUser:User;

        ///- GamePlay
        public var songQueue:Array = [];
        public var totalSongQueue:Array = [];
        public var gameIndex:int = 0;
        public var replayHistory:Array = [];
        public var songResults:Vector.<GameScoreResult> = new <GameScoreResult>[];
        public var songResultRanks:Array = [];
        public var songRestarts:int;
        public var activeFilter:EngineLevelFilter;

        ///- Session Stats
        public var sessionStats:StatTracker = new StatTracker();
        public var songStats:StatTracker = new StatTracker();

        public var menuMusic:SongPlayerBytes;
        public var menuMusicSoundVolume:Number = 1;
        public var menuMusicSoundTransform:SoundTransform = new SoundTransform();

        ///- Air Options
        public var air_useLocalFileCache:Boolean = false;
        public var air_autoSaveLocalReplays:Boolean = false;
        public var air_useVSync:Boolean = true;
        public var air_useWebsockets:Boolean = false;
        public var air_saveWindowPosition:Boolean = false;
        public var air_saveWindowSize:Boolean = false;

        public var air_windowProperties:Object;
        public var file_replay_cache:FileCache = new FileCache("replays/cache.json", 1);

        private var websocket_server:AIRServer;
        private static var websocket_message:Message = new Message();

        private var _discord:DiscordRpc;

        ///- Constructor
        public function GlobalVariables(en:SingletonEnforcer)
        {
            if (en == null)
            {
                throw Error("Multi-Instance Blocked");
            }
        }

        public function loadAirOptions():void
        {
            air_useVSync = LocalOptions.getVariable("vsync", false);
            air_useLocalFileCache = LocalOptions.getVariable("use_local_file_cache", true);
            air_autoSaveLocalReplays = LocalOptions.getVariable("auto_save_local_replays", true);
            air_useWebsockets = LocalOptions.getVariable("use_websockets", false);
            air_saveWindowPosition = LocalOptions.getVariable("save_window_position", false);
            air_saveWindowSize = LocalOptions.getVariable("save_window_size", false);

            air_windowProperties = LocalOptions.getVariable("window_properties", {"x": 0, "y": 0, "width": 0, "height": 0});

            if (air_useWebsockets)
            {
                initWebsocketServer();
            }
        }

        public function loadUserSongData():void
        {
            // Export SQL to JSON
            var db_name:String = "dbinfo/" + (activeUser != null && activeUser.siteId > 0 ? activeUser.siteId : "0") + "_info.";
            var sql_file:File = AirContext.getAppFile(db_name + "db");
            var json_file:File = AirContext.getAppFile(db_name + "json");

            // Use JSON first
            if (json_file.exists)
            {
                var json_str:String = AirContext.readTextFile(json_file);
                if (json_str != null)
                {
                    try
                    {
                        SQLQueries.loadFromObject(JSON.parse(json_str));
                    }
                    catch (e:Error)
                    {

                    }
                }
            }
            // Fallback to SQL
            else if (sql_file.exists)
            {
                SQLQueries.exportToJSON(sql_file, function(data:Object):void
                {
                    SQLQueries.loadFromObject(data);
                    writeUserSongData();

                    // Create Backup File
                    var backupFile:File = AirContext.getAppFile(db_name + "db.bak");
                    for (var i:int = 0; i < 10; i++)
                    {
                        if (!backupFile.exists)
                        {
                            sql_file.moveToAsync(backupFile);
                            break;
                        }

                        backupFile = AirContext.getAppFile(db_name + "db.bak" + i);
                    }
                });
            }
        }

        public function writeUserSongData():void
        {
            var db_name:String = "dbinfo/" + (activeUser != null && activeUser.siteId > 0 ? activeUser.siteId : "0") + "_info.";
            var json_file:File = AirContext.getAppFile(db_name + "json");
            SQLQueries.writeFile(json_file);
        }

        public function websocketPortNumber(type:String):uint
        {
            if (websocket_server != null)
            {
                return websocket_server.getPortNumber(type);
            }
            return 0;
        }

        public function initWebsocketServer():Boolean
        {
            if (websocket_server == null)
            {
                websocket_server = new AIRServer();
                websocket_server.addEndPoint(new SocketEndPoint(21235, new WebSocketClientHandlerFactory()));

                // didn't start, remove reference
                if (!websocket_server.start())
                {
                    websocket_server.stop();
                    websocket_server = null;
                    return false;
                }
                return true;
            }
            return false;
        }

        public function destroyWebsocketServer():void
        {
            if (websocket_server != null)
            {
                websocket_server.stop();
                websocket_server = null;
            }
        }

        public function websocketSend(cmd:String, data:Object):void
        {
            if (websocket_server != null)
            {
                websocket_message.command = cmd;
                websocket_message.data = data;
                websocket_server.sendMessageToAllClients(websocket_message);
            }
        }

        public function initDiscord():void
        {
            _discord = new DiscordRpc();
            _discord.init(R3::DISCORD_APP_ID);
        }

        public function updatePresence(top:String = "", bottom:String = "", startTime:Number = 0, endTime:Number = 0):void
        {
            var sr:Number = Math.round(playerUser.skillRating * 100) / 100;
            var division:Number = getDivisionNumber(playerUser.skillRating);
            if (division > 0)
            {
                _discord.updatePresence(bottom, top, startTime, endTime, "logo", playerUser.name, "d" + division, "D" + division + " - Lv. " + playerUser.skillRating, "", 0, 0, "", "");
            }
            else
            {
                _discord.updatePresence(bottom, top, startTime, endTime, "logo", playerUser.name, "", "", "", 0, 0, "", "");
            }
        }

        public function onNativeProcessClose(e:Event):void
        {
            if (websocket_server != null)
            {
                websocket_server.stop();
            }
        }

        public function loadMenuMusic():void
        {
            menuMusicSoundVolume = menuMusicSoundTransform.volume = LocalOptions.getVariable("menu_music_volume", 1);

            // Load Existing Menu Music SWF
            if (AirContext.doesFileExist(Constant.MENU_MUSIC_PATH))
            {
                var file_bytes:ByteArray = AirContext.readFile(AirContext.getAppFile(Constant.MENU_MUSIC_PATH));
                if (file_bytes && file_bytes.length > 0)
                {
                    menuMusic = new SongPlayerBytes(file_bytes);
                }
            }
            // Convert MP3 if exist.
            else if (AirContext.doesFileExist(Constant.MENU_MUSIC_MP3_PATH))
            {
                var mp3Bytes:ByteArray = AirContext.readFile(AirContext.getAppFile(Constant.MENU_MUSIC_MP3_PATH));
                if (mp3Bytes && mp3Bytes.length > 0)
                {
                    menuMusic = new SongPlayerBytes(mp3Bytes, true);
                    LocalStore.setVariable("menu_music", "External MP3");
                }
            }
        }

        ///- Public
        //- Player Divisions
        public static function getDivisionColor(level:int):int
        {
            return divisionColor[getDivisionNumber(level)];
        }

        public static function getDivisionTitle(level:int):String
        {
            return divisionTitle[getDivisionNumber(level)];
        }

        public static function getDivisionNumber(level:int):int
        {
            var div:int;
            for (div = divisionLevel.length - 1; div >= 0; --div)
            {
                if (level >= divisionLevel[div])
                {
                    break;
                }
            }
            return div;
        }

        //- Song Data
        public function getSongFile(songInfo:SongInfo, preview:Boolean = false):Song
        {
            if (!preview && songInfo.engine == Playlist.instance.engine && (!songInfo.engine || !songInfo.engine.ignoreCache))
            {
                for (var s:int = 0; s < songCache.length; s++)
                {
                    var song:Song = songCache[s];
                    if (song != null && song.songInfo.level == songInfo.level)
                        return song;
                }
            }

            return loadSongFile(songInfo, preview);
        }

        private function loadSongFile(songInfo:SongInfo, preview:Boolean = false):Song
        {
            //- Only Cache 10 Songs
            var engineCache:Boolean = (songInfo.engine == Playlist.instance.engine) && (!songInfo.engine || !songInfo.engine.ignoreCache);
            if (!preview && songCache.length > 10 && engineCache)
                songCache.pop();

            //- Make new Song
            var song:Song = new Song(songInfo, preview);

            //- Push to cache
            if (!preview && engineCache)
                songCache.push(song);

            return song;
        }

        public function removeSongFile(song:Song):void
        {
            for (var s:int = 0; s < songCache.length; s++)
            {
                if (songCache[s] == song)
                {
                    song.unload();
                    songCache.removeAt(s);
                }
            }
        }

        public function removeSongFiles():void
        {
            for (var s:int = 0; s < songCache.length; s++)
                songCache[s].unload();

            songCache = [];

            const mpInstance:MultiplayerSingleton = MultiplayerSingleton.getInstance();
            if (mpInstance != null)
            {
                mpInstance.clearStatus();
            }
        }

        public static const SONG_ACCESS_PLAYABLE:int = 0;
        public static const SONG_ACCESS_CREDITS:int = 1;
        public static const SONG_ACCESS_PURCHASED:int = 2;
        public static const SONG_ACCESS_TOKEN:int = 3;
        public static const SONG_ACCESS_VETERAN:int = 4;
        public static const SONG_ACCESS_BANNED:int = 5;

        public function checkSongAccess(songInfo:SongInfo):int
        {
            if (songInfo == null || isNaN(songInfo.level))
                return SONG_ACCESS_BANNED;
            if (songInfo.credits > 0 && playerUser.credits < songInfo.credits)
                return SONG_ACCESS_CREDITS;
            if (songInfo.price > 0 && (songInfo.index >= playerUser.purchased.length || !playerUser.purchased[songInfo.index]))
                return SONG_ACCESS_PURCHASED;
            if (songInfo.engine == null && TOKENS[songInfo.level] != null && TOKENS[songInfo.level].unlock == 0)
                return SONG_ACCESS_TOKEN;
            if (songInfo.prerelease && !playerUser.isVeteran)
                return SONG_ACCESS_VETERAN;
            return SONG_ACCESS_PLAYABLE;
        }

        public static const SONG_ICON_NO_SCORE:int = 0;
        public static const SONG_ICON_UNFINISHED:int = 1;
        public static const SONG_ICON_PASSED:int = 2;
        public static const SONG_ICON_FC_STAR:int = 3;
        public static const SONG_ICON_FC:int = 4;
        public static const SONG_ICON_SDG:int = 5;
        public static const SONG_ICON_BLACKFLAG:int = 6;
        public static const SONG_ICON_BOOFLAG:int = 7;
        public static const SONG_ICON_AAA:int = 8;

        public static function getSongIconIndex(_songInfo:SongInfo, _rank:Object):int
        {
            var songIcon:int = 0;
            if (_rank)
            {
                var noteCount:int = _songInfo.note_count;
                var maxRawScore:int = _songInfo.score_raw;

                // Alt engine hack
                if (_rank.arrows > 0)
                {
                    noteCount = _rank.arrows;
                    maxRawScore = noteCount * 50;
                }

                // No Score
                if (_rank.score == 0)
                    songIcon = SONG_ICON_NO_SCORE;

                // Unfinished or Passed
                if (_rank.score > 0) {
                    if (_rank.perfect + _rank.good + _rank.average + _rank.miss < noteCount) {
                        songIcon = SONG_ICON_UNFINISHED;
                    } else {
                        songIcon = SONG_ICON_PASSED;
                    }
                }

                // FC* - When current score isn't FC but a FC has been achieved before.
                if (_rank.fcs > 0)
                    songIcon = SONG_ICON_FC_STAR;

                // FC
                if (_rank.perfect + _rank.good + _rank.average == noteCount && _rank.miss == 0 && _rank.maxcombo == noteCount)
                    songIcon = SONG_ICON_FC;

                // SDG
                if (maxRawScore - _rank.rawscore < 250)
                    songIcon = SONG_ICON_SDG;

                // BlackFlag
                if (_rank.perfect == noteCount - 1 && _rank.good == 1 && _rank.average == 0 && _rank.miss == 0 && _rank.boo == 0 && _rank.maxcombo == noteCount)
                    songIcon = SONG_ICON_BLACKFLAG;

                // BooFlag
                if (_rank.perfect == noteCount && _rank.good == 0 && _rank.average == 0 && _rank.miss == 0 && _rank.boo == 1 && _rank.maxcombo == noteCount)
                    songIcon = SONG_ICON_BOOFLAG;

                // AAA
                if (_rank.rawscore == maxRawScore)
                    songIcon = SONG_ICON_AAA;
            }
            return songIcon;
        }

        public static function getSongIconIndexBitmask(_songInfo:SongInfo, _rank:Object):int
        {
            var songIcon:int = SONG_ICON_NO_SCORE;
            if (_rank)
            {
                var noteCount:int = _songInfo.note_count;
                var maxRawScore:int = _songInfo.score_raw;

                // Alt engine hack
                if (_rank.arrows > 0)
                {
                    noteCount = _rank.arrows;
                    maxRawScore = noteCount * 50;
                }
                
                // Unfinished or Passed
                if (_rank.score > 0) {
                    if (_rank.perfect + _rank.good + _rank.average + _rank.miss < noteCount) {
                        songIcon |= (1 << SONG_ICON_UNFINISHED);
                    } else {
                        songIcon |= (1 << SONG_ICON_PASSED);
                    }
                }

                // FC* - When current score isn't FC but a FC has been achieved before.
                if (_rank.fcs > 0)
                    songIcon |= (1 << SONG_ICON_FC_STAR);

                // FC
                if (_rank.perfect + _rank.good + _rank.average == noteCount && _rank.miss == 0 && _rank.maxcombo == noteCount)
                    songIcon |= (1 << SONG_ICON_FC);

                // SDG
                if (maxRawScore - _rank.rawscore < 250)
                    songIcon |= (1 << SONG_ICON_SDG);

                // BlackFlag
                if (_rank.perfect == noteCount - 1 && _rank.good == 1 && _rank.average == 0 && _rank.miss == 0 && _rank.boo == 0 && _rank.maxcombo == noteCount)
                    songIcon |= (1 << SONG_ICON_BLACKFLAG);

                // BooFlag
                if (_rank.perfect == noteCount && _rank.good == 0 && _rank.average == 0 && _rank.miss == 0 && _rank.boo == 1 && _rank.maxcombo == noteCount)
                    songIcon |= (1 << SONG_ICON_BOOFLAG);

                // AAA
                if (_rank.rawscore == maxRawScore)
                    songIcon |= (1 << SONG_ICON_AAA);
            }
            return songIcon;
        }

        public static const SONG_ICON_TEXT:Array = ["<font color=\"#9C9C9C\">UNPLAYED</font>", "", "<font color=\"#9FC4B4\">PASS</font>", "<font color=\"#00FF00\">FC*</font>", "<font color=\"#00FF00\">FC</font>",
            "<font color=\"#F2A254\">SDG</font>", "<font color=\"#2C2C2C\">BLACKFLAG</font>",
            "<font color=\"#473218\">BOOFLAG</font>", "<font color=\"#FFFF38\">AAA</font>"];

        public static const SONG_ICON_COLOR:Array = ["#9C9C9C", "#FFFFFF", "#9FC4B4", "#00FF00", "#00FF00", "#F2A254", "#2C2C2C", "#473218", "#FFFF38"];

        public static const SONG_ICON_TEXT_FLAG:Array = ["Unplayed", "Unfinished", "Passed", "Full Combo*", "Full Combo", "Single Digit Good", "Blackflag", "Booflag", "AAA"];

        public static function getSongIcon(_songInfo:SongInfo, _rank:Object):String
        {
            return SONG_ICON_TEXT[getSongIconIndex(_songInfo, _rank)];
        }

        //- Hiscores
        /**
         * Returns the loaded Highscore for the specified level id.
         * @param	lvlID
         * @return	Object containing the highscores list, or null if no highscore were loaded.
         */
        public function getHighscores(lvlID:int):Object
        {
            if (songHighscores[lvlID])
                return songHighscores[lvlID];

            return null;
        }

        public function clearHighscores():void
        {
            songHighscores = {};
        }

        public function loadHighscores(lvlID:int, startIndex:int = 0):void
        {
            _loader = new DynamicURLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.SITE_HISCORES_URL) + "?d=" + new Date().getTime());
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = this.userSession;
            requestVars.level = lvlID;
            requestVars.start = startIndex;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.level = lvlID;
            _loader.load(req);
        }

        private function highscoreLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            var lvlID:int = e.target.level;
            var data:Object = JSON.parse(e.target.data);
            var hiscores:Object = songHighscores[lvlID];

            if (!hiscores)
                songHighscores[lvlID] = {};

            if (data.error == null)
            {
                for each (var item:Object in data)
                {
                    songHighscores[lvlID][item.id] = item;
                }
            }
            this.dispatchEvent(new DataEvent(GlobalVariables.HIGHSCORES_LOAD_COMPLETE, data));
        }

        private function highscoreLoadError(e:Event = null):void
        {
            removeLoaderListeners();
            this.dispatchEvent(new Event(GlobalVariables.HIGHSCORES_LOAD_ERROR));
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, highscoreLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, highscoreLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, highscoreLoadError);
        }

        private function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, highscoreLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, highscoreLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, highscoreLoadError);
        }

        //- ScreenShot Handling
        /**
         * Takes a screenshot of the stage and saves it to disk.
         */
        public function takeScreenShot(filename:String = null):void
        {
            Screenshots.takeScreenshot(gameMain, filename);
        }

        /**
         * Takes a screenshot of the stage and saves it to clipboard.
         */
        public function saveScreenshotToClipboard():void
        {
            Screenshots.saveToClipboard(gameMain);
        }

        public function logDebugError(id:String, params:Object = null):void
        {
            var output:String = id;
            if (params is Error)
            {
                var err:Error = (params as Error);
                output += "\n" + err.name + "\n" + err.message + "\n" + err.errorID + "\n" + err.getStackTrace();
            }
            else
            {
                output += "\n" + params;
            }

            var _debugLoader:URLLoader = new URLLoader();
            var req:URLRequest = new URLRequest(URLs.resolve(URLs.DEBUG_LOG_URL));
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = userSession;
            requestVars.error = output;
            requestVars.gameVersion = CONFIG::timeStamp;
            requestVars.gameSettings = Capabilities.serverString;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _debugLoader.dataFormat = URLLoaderDataFormat.TEXT;
            _debugLoader.load(req);
        }

        //- Full Screen
        public function toggleFullScreen(e:Event = null):void
        {
            if (gameMain.stage)
            {
                if (gameMain.stage.displayState == StageDisplayState.NORMAL)
                {
                    gameMain.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
                }
                else
                {
                    gameMain.stage.displayState = StageDisplayState.NORMAL;
                }
            }
        }



        public function unlockTokenById(type:String, id:String):void
        {
            try
            {
                TOKENS[TOKENS_TYPE[type][id].level].unlock = 1;
            }
            catch (err:Error)
            {
                Logger.error(this, "Attempted Unlock of Unknown Token: " + type + ", " + id);
            }
        }

        public static function get instance():GlobalVariables
        {
            if (_instance == null)
            {
                _instance = new GlobalVariables(new SingletonEnforcer());
            }

            return _instance;
        }
    }
}

class SingletonEnforcer
{
}
