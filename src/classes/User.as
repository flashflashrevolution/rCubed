package classes
{
    import arc.ArcGlobals;
    import assets.GameBackgroundColor;
    import classes.filter.EngineLevelFilter;
    import com.flashfla.utils.VectorUtil;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.media.SoundMixer;
    import flash.media.SoundTransform;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.ui.Keyboard;
    import sql.SQLSongUserInfo;

    public class User extends EventDispatcher
    {
        //- Constants
        public static const ADMIN_ID:int = 6;
        public static const DEVELOPER_ID:int = 83;
        public static const BANNED_ID:int = 8;
        public static const CHAT_MOD_ID:int = 24;
        public static const FORUM_MOD_ID:int = 5;
        public static const MULTI_MOD_ID:int = 44;
        public static const MUSIC_PRODUCER_ID:int = 46;
        public static const PROFILE_MOD_ID:int = 56;
        public static const SIM_AUTHOR_ID:int = 47;
        public static const VETERAN_ID:int = 49;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _loader:URLLoader;
        private var _isLoaded:Boolean = false;
        private var _isLoading:Boolean = false;
        private var _loadError:Boolean = false;

        //- SFS vars
        public var id:int;
        public var variables:Array;
        public var isSpec:Boolean;
        public var wantsToWatch:Boolean;

        //- User Vars
        public var name:String;
        public var siteId:int;
        public var hash:String;
        public var groups:Vector.<Number>;
        public var language:String = "us";
        public var playerIdx:int;

        public var userLevel:int;
        public var userClass:int;
        public var userColor:int;
        public var userStatus:int;

        public var joinDate:String;
        public var skillLevel:Number;
        public var skillRating:Number;
        public var gameRank:Number;
        public var gamesPlayed:Number;
        public var grandTotal:Number;
        public var credits:Number;
        public var purchased:Vector.<Boolean>;
        public var averageRank:Number;
        public var level_ranks:Object = {};
        public var avatar:Loader;
        public var startUpScreen:int = 0; // 0 = MP Connect + MP Screen   |   1 = MP Connect + Song List   |   2 = Song List
        public var loggedIn:Boolean;

        public var songQueues:Vector.<Object> = new <Object>[];
        public var filters:Vector.<EngineLevelFilter> = new <EngineLevelFilter>[];
        public var songRatings:Object = {};

        public var DISPLAY_LEGACY_SONGS:Boolean = false;
        public var DISPLAY_GENRE_FLAG:Boolean = true;
        public var DISPLAY_SONG_FLAG:Boolean = true;
        public var DISPLAY_SONG_NOTE:Boolean = true;

        //- Game Data
        public var GLOBAL_OFFSET:Number = 0;
        public var JUDGE_OFFSET:Number = 0;
        public var AUTO_JUDGE_OFFSET:Boolean = false;
        public var DISPLAY_JUDGE:Boolean = true;
        public var DISPLAY_JUDGE_ANIMATIONS:Boolean = true;
        public var DISPLAY_RECEPTOR_ANIMATIONS:Boolean = true;
        public var DISPLAY_HEALTH:Boolean = true;
        public var DISPLAY_GAME_TOP_BAR:Boolean = true;
        public var DISPLAY_GAME_BOTTOM_BAR:Boolean = true;
        public var DISPLAY_SCORE:Boolean = true;
        public var DISPLAY_COMBO:Boolean = true;
        public var DISPLAY_PACOUNT:Boolean = true;
        public var DISPLAY_ACCURACY_BAR:Boolean = true;
        public var DISPLAY_AMAZING:Boolean = true;
        public var DISPLAY_PERFECT:Boolean = true;
        public var DISPLAY_TOTAL:Boolean = true;
        public var DISPLAY_SCREENCUT:Boolean = false;
        public var DISPLAY_SONGPROGRESS:Boolean = true;
        public var DISPLAY_SONGPROGRESS_TEXT:Boolean = false;

        public var DISPLAY_MP_UI:Boolean = true;
        public var DISPLAY_MP_PA:Boolean = true;
        public var DISPLAY_MP_JUDGE:Boolean = true;
        public var DISPLAY_MP_COMBO:Boolean = true;

        public var DISPLAY_MP_TIMESTAMP:Boolean = false;
        public var judgeColors:Array = [0x78ef29, 0x12e006, 0x01aa0f, 0xf99800, 0xfe0000, 0x804100];
        public var comboColors:Array = [0x0099CC, 0x00AD00, 0xFCC200, 0xC7FB30, 0x6C6C6C, 0xF99800, 0xB06100, 0x990000, 0xDC00C2]; // Normal, FC, AAA, SDG, BlackFlag, AvFlag, BooFlag, MissFlag, RawGood
        public var enableComboColors:Vector.<Boolean> = new <Boolean>[true, true, true, false, false, false, false, false, false];
        public var gameColors:Array = [0x1495BD, 0x033242, 0x0C6A88, 0x074B62, 0x000000];
        public var noteColors:Array = ["red", "blue", "purple", "yellow", "pink", "orange", "cyan", "green", "white"];
        public var rawGoodTracker:Number = 0;

        public var autofailAmazing:int = 0;
        public var autofailPerfect:int = 0;
        public var autofailGood:int = 0;
        public var autofailAverage:int = 0;
        public var autofailMiss:int = 0;
        public var autofailBoo:int = 0;
        public var autofailRawGoods:Number = 0;
        public var autofailRestart:Boolean = false;

        public var keyLeft:int = Keyboard.LEFT;
        public var keyDown:int = Keyboard.DOWN;
        public var keyUp:int = Keyboard.UP;
        public var keyRight:int = Keyboard.RIGHT;
        public var keyRestart:int = Keyboard.SLASH;
        public var keyQuit:int = Keyboard.CONTROL;
        public var keyOptions:int = 145; // Scrolllock

        public var activeNoteskin:int = 1;
        public var activeMods:Array = [];
        public var activeVisualMods:Array = [];
        public var slideDirection:String = "up";
        public var judgeSpeed:Number = 1;
        public var gameSpeed:Number = 1.5;
        public var receptorGap:Number = 80;
        public var receptorAnimationSpeed:Number = 1;
        public var noteScale:Number = 1;
        public var gameVolume:Number = 1;
        public var screencutPosition:Number = 0.5;
        public var frameRate:int = 60;
        public var forceNewJudge:Boolean = false;
        public var songRate:Number = 1;

        public var gameplay:Gameplay;


        //- Permissions
        public var isActiveUser:Boolean;
        public var isGuest:Boolean;
        public var isPlayer:Boolean;
        public var isVeteran:Boolean;
        public var isAdmin:Boolean;
        public var isDeveloper:Boolean
        public var isForumBanned:Boolean;
        public var isGameBanned:Boolean;
        public var isProfileBanned:Boolean;
        public var isModerator:Boolean;
        public var isForumModerator:Boolean;
        public var isProfileModerator:Boolean;
        public var isChatModerator:Boolean;
        public var isMultiModerator:Boolean;
        public var isMusician:Boolean;
        public var isSimArtist:Boolean;

        ///- Constructor
        /**
         * Defines the creation of a new User object.
         *
         * @param	loadData Loads the user data on creation.
         * @param	isActiveUser Sets the active user flag.
         * @tiptext
         */
        public function User(loadData:Boolean = false, isActiveUser:Boolean = false, sfsId:int = -1):void
        {
            this.id = sfsId;
            this.variables = [];
            this.isSpec = false;
            this.wantsToWatch = false;
            this.isActiveUser = isActiveUser;

            if (loadData)
            {
                if (sfsId > -1)
                {
                    loadUser(sfsId);
                }
                else
                {
                    load();
                }
            }
        }

        public function refreshUser():void
        {
            _gvars.userSession = "0";
            _gvars.playerUser = new User(true, true);
            _gvars.activeUser = _gvars.playerUser;
        }

        ///- Public
        public function calculateAverageRank():void
        {
            var rankTotal:int = 0;
            for each (var levelRank:Object in this.level_ranks)
            {
                var genre:int = levelRank.genre;
                if (genre != 10 && genre != 12 && genre != 23)
                {
                    rankTotal += levelRank.rank;
                }
            }
            this.averageRank = (rankTotal / _gvars.TOTAL_PUBLIC_SONGS);
        }

        ///- Profile Loading
        public function isLoaded():Boolean
        {
            return _isLoaded && !_loadError;
        }

        public function isError():Boolean
        {
            return _loadError;
        }

        public function load():void
        {
            // Kill old Loading Stream
            if (_loader && _isLoading)
            {
                removeLoaderListeners();
                _loader.close();
            }

            Logger.info(this, "Main User Load Requested");
            _isLoaded = false;
            _loadError = false;
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.USER_INFO_URL) + "?d=" + new Date().getTime());
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = _gvars.userSession;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);
            _isLoading = true;
        }

        public function loadUser(userid:int):void
        {
            Logger.info(this, "Secondary User Load Requested");
            _isLoaded = false;
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.USER_INFO_LITE_URL) + "?d=" + new Date().getTime());
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.userid = userid;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);
            _isLoading = true;
        }

        private function profileLoadComplete(e:Event):void
        {
            Logger.success(this, "Profile Load Success");
            removeLoaderListeners();

            // Parse Response
            var _data:Object;
            var siteDataString:String = e.target.data;
            try
            {
                _data = JSON.parse(siteDataString);
            }
            catch (err:Error)
            {
                Logger.error(this, "Profile Parse Failure: " + Logger.exception_error(err));
                Logger.error(this, "Wrote invalid response data to log folder. [logs/user_main.txt]");
                AirContext.writeTextFile(AirContext.getAppFile("logs/user_main.txt"), siteDataString);

                _loadError = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
                return;
            }

            // Has Response
            loadUserData(_data);

            if (isActiveUser)
            {
                loadLevelRanks();
            }
            else
            {
                _isLoaded = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
            }
        }

        public function loadUserData(_data:Object):void
        {
            // Private
            if (isActiveUser)
            {
                this.hash = _data.hash;
                this.credits = _data.credits;
                setPurchasedString(_data["purchased"]);
                if (_data["song_ratings"] != null)
                    this.songRatings = _data["song_ratings"];
            }

            // Public
            this.name = _data["name"];
            this.siteId = _data["id"];
            this.groups = Vector.<Number>(VectorUtil.fromArr(_data["groups"]));
            this.joinDate = _data["joinDate"];
            this.gameRank = _data["gameRank"];
            this.gamesPlayed = _data["gamesPlayed"];
            this.grandTotal = _data["grandTotal"];
            this.skillLevel = _data["skillLevel"];
            this.skillRating = _data["skillRating"];

            setupPermissions();

            // Load Avatar
            loadAvatar();

            // Setup Settings from server or local
            if (_data["settings"] != null && !this.isGuest)
            {
                try
                {
                    settings = JSON.parse(_data.settings);
                }
                catch (err:Error)
                {
                    Logger.error(this, "Settings Parse Failure: " + Logger.exception_error(err));
                }
            }
            else
            {
                loadLocal();
            }
        }

        public function setPurchasedString(str:String):void
        {
            this.purchased = new <Boolean>[];
            for (var x:int = 1; x < str.length; x++)
            {
                this.purchased.push(str.charAt(x) == "1");
            }
        }

        private function profileLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Profile Load Failure: " + Logger.event_error(err));
            removeLoaderListeners();
            _loadError = true;
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, profileLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, profileLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, profileLoadError);
        }

        private function removeLoaderListeners():void
        {
            _isLoaded = false;
            _loader.removeEventListener(Event.COMPLETE, profileLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, profileLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, profileLoadError);
        }

        private function setupPermissions():void
        {
            this.isGuest = (this.siteId <= 2);
            this.isVeteran = VectorUtil.inVector(this.groups, new <Number>[VETERAN_ID]);
            this.isAdmin = VectorUtil.inVector(this.groups, new <Number>[ADMIN_ID]);
            this.isDeveloper = VectorUtil.inVector(this.groups, new <Number>[DEVELOPER_ID])
            this.isForumBanned = VectorUtil.inVector(this.groups, new <Number>[BANNED_ID]);
            this.isModerator = VectorUtil.inVector(this.groups, new <Number>[ADMIN_ID, FORUM_MOD_ID, CHAT_MOD_ID, PROFILE_MOD_ID, MULTI_MOD_ID]);
            this.isForumModerator = VectorUtil.inVector(this.groups, new <Number>[FORUM_MOD_ID, ADMIN_ID]);
            this.isProfileModerator = VectorUtil.inVector(this.groups, new <Number>[PROFILE_MOD_ID, ADMIN_ID]);
            this.isChatModerator = VectorUtil.inVector(this.groups, new <Number>[CHAT_MOD_ID, ADMIN_ID]);
            this.isMultiModerator = VectorUtil.inVector(this.groups, new <Number>[MULTI_MOD_ID, ADMIN_ID]);
            this.isMusician = VectorUtil.inVector(this.groups, new <Number>[MUSIC_PRODUCER_ID]);
            this.isSimArtist = VectorUtil.inVector(this.groups, new <Number>[SIM_AUTHOR_ID]);
        }

        public function loadAvatar():void
        {
            this.avatar = new Loader();
            if (isActiveUser && !isGuest)
            {
                this.avatar.contentLoaderInfo.addEventListener(Event.COMPLETE, avatarLoadComplete);

                function avatarLoadComplete(e:Event):void
                {
                    LocalStore.setVariable("uAvatar", LoaderInfo(e.target).bytes);
                    avatar.removeEventListener(Event.COMPLETE, avatarLoadComplete);
                }
            }
            this.avatar.load(new URLRequest(URLs.resolve(URLs.USER_AVATAR_URL) + "?uid=" + this.siteId + "&cHeight=99&cWidth=99"));
        }

        ///- Level Ranks
        public function loadLevelRanks():void
        {
            _loader = new URLLoader();
            addLoaderRanksListeners();

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.USER_RANKS_URL));
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = _gvars.userSession;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);
        }

        private function ranksLoadComplete(e:Event):void
        {
            Logger.success(this, "Ranks Load Success");
            removeLoaderRanksListeners();
            level_ranks = new Object();

            // Check Level ranks for Non-empty
            if (e.target.data != "")
            {
                var ranksTemp:Array = e.target.data.split(",");
                var rankLength:int = ranksTemp.length;
                for (var x:int = 0; x < rankLength; x++)
                {
                    // [0] = Level ID : [1] = Rank : [2] = Score : [3] = Genre : [4] = Results : [5] = Play Count : [6] = AAA Count : [7] = FC Count
                    var rankSplit:Array = ranksTemp[x].split(":");

                    // [0]'perfect' - [1]'good' - [2]'average' - [3]'miss' - [4]'boo' - [5]'maxcombo'
                    var scoreResults:Array = rankSplit[4].split("-");
                    for (var s:String in scoreResults)
                        scoreResults[s] = Number(scoreResults[s]);

                    level_ranks[Number(rankSplit[0])] = {"genre": Number(rankSplit[3]),
                            "rank": Number(rankSplit[1]),
                            "score": Number(rankSplit[2]),
                            "results": rankSplit[4],
                            "plays": Number(rankSplit[5]),
                            "aaas": Number(rankSplit[6]),
                            "fcs": Number(rankSplit[7]),
                            "perfect": scoreResults[0],
                            "good": scoreResults[1],
                            "average": scoreResults[2],
                            "miss": scoreResults[3],
                            "boo": scoreResults[4],
                            "maxcombo": scoreResults[5],
                            "rawscore": ((scoreResults[0] * 50) + (scoreResults[1] * 25) + (scoreResults[2] * 5) - (scoreResults[3] * 10) - (scoreResults[4] * 5))};
                }
            }
            _isLoaded = true;
            this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
        }

        private function ranksLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Ranks Load Failure: " + Logger.event_error(err));
            removeLoaderRanksListeners();
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderRanksListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, ranksLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, ranksLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, ranksLoadError);
        }

        private function removeLoaderRanksListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, ranksLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, ranksLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, ranksLoadError);
        }

        ///- Settings
        public function get settings():Object
        {
            return save(true);
        }

        public function set settings(_settings:Object):void
        {
            if (_settings == null)
                return;

            if (_settings.language != null)
                this.language = _settings.language;

            if (_settings.viewOffset != null)
                this.GLOBAL_OFFSET = _settings.viewOffset;

            if (_settings.judgeOffset != null)
                this.JUDGE_OFFSET = _settings.judgeOffset;

            if (_settings.autoJudgeOffset != null)
                this.AUTO_JUDGE_OFFSET = _settings.autoJudgeOffset;

            if (_settings.viewSongFlag != null)
                this.DISPLAY_SONG_FLAG = _settings.viewSongFlag;

            if (_settings.viewGenreFlag != null)
                this.DISPLAY_GENRE_FLAG = _settings.viewGenreFlag;

            if (_settings.viewSongNote != null)
                this.DISPLAY_SONG_NOTE = _settings.viewSongNote;

            if (_settings.viewJudge != null)
                this.DISPLAY_JUDGE = _settings.viewJudge;

            if (_settings.viewJudgeAnimations != null)
                this.DISPLAY_JUDGE_ANIMATIONS = _settings.viewJudgeAnimations;

            if (_settings.viewReceptorAnimations != null)
                this.DISPLAY_RECEPTOR_ANIMATIONS = _settings.viewReceptorAnimations;

            if (_settings.viewHealth != null)
                this.DISPLAY_HEALTH = _settings.viewHealth;

            if (_settings.viewGameTopBar != null)
                this.DISPLAY_GAME_TOP_BAR = _settings.viewGameTopBar;

            if (_settings.viewGameBottomBar != null)
                this.DISPLAY_GAME_BOTTOM_BAR = _settings.viewGameBottomBar;

            if (_settings.viewScore != null)
                this.DISPLAY_SCORE = _settings.viewScore;

            if (_settings.viewCombo != null)
                this.DISPLAY_COMBO = _settings.viewCombo;

            if (_settings.viewPACount != null)
                this.DISPLAY_PACOUNT = _settings.viewPACount;

            if (_settings.viewAccBar != null)
                this.DISPLAY_ACCURACY_BAR = _settings.viewAccBar;

            if (_settings.viewAmazing != null)
                this.DISPLAY_AMAZING = _settings.viewAmazing;

            if (_settings.viewPerfect != null)
                this.DISPLAY_PERFECT = _settings.viewPerfect;

            if (_settings.viewTotal != null)
                this.DISPLAY_TOTAL = _settings.viewTotal;

            if (_settings.viewScreencut != null)
                this.DISPLAY_SCREENCUT = _settings.viewScreencut;

            if (_settings.viewSongProgress != null)
                this.DISPLAY_SONGPROGRESS = _settings.viewSongProgress;

            if (_settings.viewSongProgressText != null)
                this.DISPLAY_SONGPROGRESS_TEXT = _settings.viewSongProgressText;

            if (_settings.viewMPUI != null)
                this.DISPLAY_MP_UI = _settings.viewMPUI;

            if (_settings.viewMPPA != null)
                this.DISPLAY_MP_PA = _settings.viewMPPA;

            if (_settings.viewMPCombo != null)
                this.DISPLAY_MP_COMBO = _settings.viewMPCombo;

            if (_settings.viewMPJudge != null)
                this.DISPLAY_MP_JUDGE = _settings.viewMPJudge;

            if (_settings.viewMPTimestamp != null)
                this.DISPLAY_MP_TIMESTAMP = _settings.viewMPTimestamp;

            if (_settings.viewLegacySongs != null)
                this.DISPLAY_LEGACY_SONGS = _settings.viewLegacySongs;

            if (_settings.keys[0] != null)
                this.keyLeft = _settings.keys[0];

            if (_settings.keys[1] != null)
                this.keyDown = _settings.keys[1];

            if (_settings.keys[2] != null)
                this.keyUp = _settings.keys[2];

            if (_settings.keys[3] != null)
                this.keyRight = _settings.keys[3];

            if (_settings.keys[4] != null)
                this.keyRestart = _settings.keys[4];

            if (_settings.keys[5] != null)
                this.keyQuit = _settings.keys[5];

            if (_settings.keys[6] != null)
                this.keyOptions = _settings.keys[6];

            if (_settings.noteskin != null)
                this.activeNoteskin = _settings.noteskin;

            if (_settings.direction != null)
                this.slideDirection = _settings.direction;

            if (_settings.speed != null)
                this.gameSpeed = _settings.speed;

            if (_settings.judgeSpeed != null)
                this.judgeSpeed = _settings.judgeSpeed;

            if (_settings.gap != null)
                this.receptorGap = _settings.gap;

            if (_settings.noteScale != null)
                this.noteScale = _settings.noteScale;

            if (_settings.screencutPosition != null)
                this.screencutPosition = _settings.screencutPosition;

            if (_settings.frameRate != null)
                this.frameRate = _settings.frameRate;

            if (_settings.songRate != null)
                this.songRate = _settings.songRate;

            if (_settings.autofailRestart != null)
                this.autofailRestart = _settings.autofailRestart;

            if (_settings.forceNewJudge != null)
                this.forceNewJudge = _settings.forceNewJudge;

            if (_settings.visual != null)
                this.activeVisualMods = _settings.visual;

            if (_settings.judgeColours != null)
                mergeIntoArray(this.judgeColors, _settings.judgeColours);

            if (_settings.comboColours != null)
                mergeIntoArray(this.comboColors, _settings.comboColours);

            if (_settings.enableComboColors != null)
                mergeIntoArray(this.enableComboColors, _settings.enableComboColors);

            if (_settings.gameColours != null)
                mergeIntoArray(this.gameColors, _settings.gameColours);

            if (_settings.noteColours != null)
                mergeIntoArray(this.noteColors, _settings.noteColours);

            if (_settings.rawGoodTracker != null)
                this.rawGoodTracker = _settings.rawGoodTracker;

            if (_settings.gameVolume != null)
                this.gameVolume = _settings.gameVolume;

            if (_settings.isolationOffset != null)
                _avars.configIsolationStart = _settings.isolationOffset;

            if (_settings.isolationLength != null)
                _avars.configIsolationLength = _settings.isolationLength;

            if (_settings.startUpScreen != null)
                this.startUpScreen = Math.max(0, Math.min(2, _settings.startUpScreen));

            if (_settings.filters != null)
                this.filters = doImportFilters(_settings.filters);

            if (_settings.songQueues != null)
            {
                this.songQueues = new <Object>[];
                for each (var queueItem:Object in _settings.songQueues)
                {
                    this.songQueues.push(new SongQueueItem(queueItem.name, queueItem.items));
                }
            }

            if (isActiveUser)
            {
                SoundMixer.soundTransform = new SoundTransform(this.gameVolume);

                // Setup Background Colors
                GameBackgroundColor.BG_LIGHT = gameColors[0];
                GameBackgroundColor.BG_DARK = gameColors[1];
                GameBackgroundColor.BG_STATIC = gameColors[2];
                GameBackgroundColor.BG_POPUP = gameColors[3];
                GameBackgroundColor.BG_STAGE = gameColors[4];
                (_gvars.gameMain.getChildAt(0) as GameBackgroundColor).redraw();
            }

            function mergeIntoArray(arr1:*, arr2:*):void
            {
                var minArrLen:int = Math.min(arr1.length, arr2.length);
                for (var i:int = 0; i < minArrLen; i++)
                {
                    arr1[i] = arr2[i];
                }
            }
        }

        public function save(returnObject:Boolean = false):Object
        {
            if (isGuest && !returnObject)
                return {};

            var gameSave:Object = {};
            gameSave.language = this.language;
            gameSave.viewOffset = this.GLOBAL_OFFSET;
            gameSave.judgeOffset = this.JUDGE_OFFSET;
            gameSave.autoJudgeOffset = this.AUTO_JUDGE_OFFSET;
            gameSave.viewGenreFlag = this.DISPLAY_GENRE_FLAG;
            gameSave.viewSongFlag = this.DISPLAY_SONG_FLAG;
            gameSave.viewSongNote = this.DISPLAY_SONG_NOTE;
            gameSave.viewJudge = this.DISPLAY_JUDGE;
            gameSave.viewHealth = this.DISPLAY_HEALTH;
            gameSave.viewJudgeAnimations = this.DISPLAY_JUDGE_ANIMATIONS;
            gameSave.viewReceptorAnimations = this.DISPLAY_RECEPTOR_ANIMATIONS;
            gameSave.viewGameTopBar = this.DISPLAY_GAME_TOP_BAR;
            gameSave.viewGameBottomBar = this.DISPLAY_GAME_BOTTOM_BAR;
            gameSave.viewScore = this.DISPLAY_SCORE;
            gameSave.viewCombo = this.DISPLAY_COMBO;
            gameSave.viewPACount = this.DISPLAY_PACOUNT;
            gameSave.viewAccBar = this.DISPLAY_ACCURACY_BAR;
            gameSave.viewAmazing = this.DISPLAY_AMAZING;
            gameSave.viewPerfect = this.DISPLAY_PERFECT;
            gameSave.viewTotal = this.DISPLAY_TOTAL;
            gameSave.viewScreencut = this.DISPLAY_SCREENCUT;
            gameSave.viewSongProgress = this.DISPLAY_SONGPROGRESS;
            gameSave.viewSongProgressText = this.DISPLAY_SONGPROGRESS_TEXT;
            gameSave.viewMPUI = this.DISPLAY_MP_UI;
            gameSave.viewMPPA = this.DISPLAY_MP_PA;
            gameSave.viewMPJudge = this.DISPLAY_MP_JUDGE;
            gameSave.viewMPCombo = this.DISPLAY_MP_COMBO;
            gameSave.viewMPTimestamp = this.DISPLAY_MP_TIMESTAMP;
            gameSave.viewLegacySongs = this.DISPLAY_LEGACY_SONGS;

            gameSave.keys = [this.keyLeft, this.keyDown, this.keyUp, this.keyRight, this.keyRestart, this.keyQuit, this.keyOptions];

            gameSave.judgeSpeed = this.judgeSpeed;
            gameSave.speed = this.gameSpeed;
            gameSave.direction = this.slideDirection;
            gameSave.noteskin = this.activeNoteskin;
            gameSave.gap = this.receptorGap;
            gameSave.noteScale = this.noteScale;
            gameSave.screencutPosition = this.screencutPosition;
            gameSave.autofailRestart = this.autofailRestart;
            gameSave.frameRate = this.frameRate;
            gameSave.forceNewJudge = this.forceNewJudge;
            gameSave.visual = this.activeVisualMods;
            gameSave.judgeColours = this.judgeColors;
            gameSave.comboColours = this.comboColors;
            gameSave.enableComboColors = this.enableComboColors;
            gameSave.gameColours = this.gameColors;
            gameSave.noteColours = this.noteColors;
            gameSave.rawGoodTracker = this.rawGoodTracker;
            gameSave.songQueues = this.songQueues;
            gameSave.gameVolume = this.gameVolume;
            gameSave.filters = doExportFilters(this.filters);
            gameSave.startUpScreen = this.startUpScreen;

            if (returnObject)
                return gameSave;

            //- Save to server
            _loader = new URLLoader();
            addLoaderSaveListeners();

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.USER_SAVE_SETTINGS_URL));
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = _gvars.userSession;
            requestVars.settings = JSON.stringify(gameSave);
            requestVars.action = "save";
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);

            return {};
        }

        private function settingSaveComplete(e:Event):void
        {
            Logger.success(this, "Settings Save Success");
            removeLoaderSaveListeners();
            this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
        }

        private function settingLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Settings Save Failure: " + Logger.event_error(err));
            removeLoaderSaveListeners();
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderSaveListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, settingSaveComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, settingLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, settingLoadError);
        }

        private function removeLoaderSaveListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, settingSaveComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, settingLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, settingLoadError);
        }

        public function saveLocal():void
        {
            LocalStore.setVariable("sEncode", JSON.stringify(save(true)));
            LocalStore.flush();
        }

        public function loadLocal():void
        {
            var encodedSettings:String = LocalStore.getVariable("sEncode", null);
            if (encodedSettings != null)
            {
                try
                {
                    settings = JSON.parse(encodedSettings);
                }
                catch (e:Error)
                {
                }
            }
        }

        public function getLevelRank(songInfo:SongInfo):Object
        {
            if (songInfo.engine)
                return ArcGlobals.instance.legacyLevelRanksGet(songInfo);

            if (level_ranks[songInfo.level] == null)
                return {"genre": 23,
                        "rank": 1,
                        "score": 0,
                        "results": "0-0-0-0-0-0",
                        "plays": 0,
                        "aaas": 0,
                        "fcs": 0,
                        "perfect": 0,
                        "good": 0,
                        "average": 0,
                        "miss": 0,
                        "boo": 0,
                        "maxcombo": 0,
                        "rawscore": 0};

            return level_ranks[songInfo.level];
        }

        public function getSongRating(songInfo:SongInfo):Number
        {
            if (songInfo.engine != null)
            {
                var sDetails:SQLSongUserInfo = SQLQueries.getSongDetails(songInfo.engine.id, songInfo.level_id);
                if (sDetails)
                    return sDetails.song_rating;

                return 0;
            }
            return songRatings[songInfo.level] != null ? songRatings[songInfo.level] : 0;
        }

        /**
         * Imports user filters from a save object.
         * @param	filtersIn Array of Filter objects.
         * @return Array of EngineLevelFilters.
         */
        private function doImportFilters(filtersIn:Array):Vector.<EngineLevelFilter>
        {
            if (isActiveUser)
                _gvars.activeFilter = null;

            var newFilters:Vector.<EngineLevelFilter> = new <EngineLevelFilter>[];
            var filter:EngineLevelFilter;
            for each (var item:Object in filtersIn)
            {
                filter = new EngineLevelFilter();
                filter.setup(item);
                newFilters.push(filter);

                if (filter.is_default)
                {
                    if (_gvars.activeFilter == null && isActiveUser)
                        _gvars.activeFilter = filter;
                    else
                        filter.is_default = false;
                }
            }
            return newFilters;
        }

        /**
         * Exports the user filters into an array of filter objects.
         * @param	filtersOut Array of EngineLevelFilter to export.
         * @return	Array of Filter Object.
         */
        private function doExportFilters(filtersOut:Vector.<EngineLevelFilter>):Array
        {
            var filters:Array = [];
            for each (var item:EngineLevelFilter in filtersOut)
            {
                var exportFilter:Object = item.export();
                if (exportFilter["filters"] && exportFilter["filters"].length > 0) // Don't export blank filters.
                    filters.push(exportFilter);
            }
            return filters;
        }

        /**
         * Set the User Variables.
         *
         * @param	o:	an object containing variables' key-value pairs.
         *
         * @exclude
         */
        public function setVariables(o:Object):void
        {
            /*
             * TODO: only string, number (int, uint) and boolean should be allowed
             */
            for (var key:String in o)
            {
                var v:* = o[key];
                if (v != null)
                    this.variables[key] = v;

                else
                    delete this.variables[key];
            }
        }
    }
}
