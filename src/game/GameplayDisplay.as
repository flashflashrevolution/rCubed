package game
{
    import arc.ArcGlobals;
    import assets.GameBackgroundColor;
    import assets.gameplay.BarBottomNormal;
    import assets.gameplay.BarBottomSideways;
    import assets.gameplay.BarTopNormal;
    import assets.gameplay.BarTopSideways;
    import classes.Alert;
    import classes.GameNote;
    import classes.Language;
    import classes.Noteskins;
    import classes.chart.Note;
    import classes.chart.Song;
    import classes.mp.MPSocketDataRaw;
    import classes.mp.MPTeam;
    import classes.mp.MPUser;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCFFRPlaybackRequest;
    import classes.mp.commands.MPCFFRScoreUpdate;
    import classes.mp.commands.MPCFFRSongStart;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.events.MPRoomRawEvent;
    import classes.mp.mode.ffr.MPFFRState;
    import classes.mp.room.MPRoomFFR;
    import classes.replay.ReplayBinFrame;
    import classes.replay.ReplayNote;
    import classes.ui.BoxButton;
    import classes.ui.ProgressBar;
    import classes.user.UserSongData;
    import classes.user.UserSongNotes;
    import com.flashfla.utils.Average;
    import com.flashfla.utils.RollingAverage;
    import com.flashfla.utils.StringUtil;
    import com.flashfla.utils.TimeUtil;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.geom.Point;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.ui.Keyboard;
    import flash.ui.Mouse;
    import flash.utils.ByteArray;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import game.controls.AccuracyBar;
    import game.controls.Combo;
    import game.controls.Judge;
    import game.controls.LifeBar;
    import game.controls.MPFFRScoreCompare;
    import game.controls.NoteBox;
    import game.controls.PAWindow;
    import game.controls.RawGoods;
    import game.controls.Score;
    import game.controls.ScreenCut;
    import game.controls.TextStatic;
    import game.events.GamePlaybackEvent;
    import game.events.GamePlaybackFocusChange;
    import game.events.GamePlaybackReader;
    import game.events.GamePlaybackSpectatorEnd;
    import game.events.GamePlaybackSpectatorHit;
    import menu.MenuPanel;
    import menu.MenuSongSelection;
    import classes.mp.mode.ffr.MPMatchFFRUser;
    import classes.mp.mode.ffr.MPMatchFFR;
    import classes.mp.mode.ffr.MPMatchFFRTeam;

    public class GameplayDisplay extends MenuPanel
    {
        public static const GAME_WAIT:int = 0;
        public static const GAME_PLAY:int = 1;
        public static const GAME_END:int = 2;
        public static const GAME_RESTART:int = 3;
        public static const GAME_PAUSE:int = 4;
        public static const GAME_DISPOSE:int = 5;

        public static const LAYOUT_PROGRESS_BAR:String = "progressbar";
        public static const LAYOUT_PROGRESS_TEXT:String = "progresstext";
        public static const LAYOUT_RECEPTORS:String = "receptors";
        public static const LAYOUT_JUDGE:String = "judge";
        public static const LAYOUT_HEALTH:String = "health";
        public static const LAYOUT_SCORE:String = "score";
        public static const LAYOUT_COMBO:String = "combo";
        public static const LAYOUT_COMBO_TOTAL:String = "combototal";
        public static const LAYOUT_COMBO_STATIC:String = "combostatic";
        public static const LAYOUT_COMBO_TOTAL_STATIC:String = "combototalstatic";
        public static const LAYOUT_ACCURACY_BAR:String = "accuracybar";
        public static const LAYOUT_PA:String = "pa";
        public static const LAYOUT_RAWGOODS:String = "rawgoods";
        public static const LAYOUT_RAWGOODS_STATIC:String = "rawgoodsstatic";
        public static const LAYOUT_MP_FFR_SCORE:String = "mpffrscore";

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _mp:Multiplayer = Multiplayer.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _noteskins:Noteskins = Noteskins.instance;
        private var _lang:Language = Language.instance;

        private var _loader:URLLoader;
        public var _keyDown:Object;

        public var song:Song;
        public var options:GameOptions;

        public var reverseMod:Boolean;
        public var sideScroll:Boolean;
        public var defaultLayout:Object;

        public var btnExitEditor:BoxButton;
        public var btnResetEditor:BoxButton;

        public var bgTopBar:Sprite;
        public var bgBottomBar:Sprite;

        public var uiNoteField:NoteBox;
        public var uiProgressDisplay:ProgressBar;
        public var uiProgressDisplayText:TextStatic;
        public var uiScore:Score;
        public var uiAccuracyBar:AccuracyBar;
        public var uiPAWindow:PAWindow;
        public var uiCombo:Combo;
        public var uiComboStatic:TextStatic;
        public var uiLifebar:LifeBar;
        public var uiJudge:Judge;
        public var uiRawGoods:RawGoods;
        public var uiRawGoodsStatic:TextStatic;
        public var uiNoteCount:Combo;
        public var uiNoteCountStatic:TextStatic;
        public var uiScreenCut:ScreenCut;
        public var uiSongBackground:MovieClip;

        public var accuracy:Average;
        public var songOffset:RollingAverage;
        public var frameRate:RollingAverage;

        public var absoluteStart:int = 0;
        public var absolutePosition:int = 0;
        public var songPausePosition:int = 0;
        public var songDelay:int = 0;
        public var songDelayStarted:Boolean = false;
        public var judgeSettings:Vector.<JudgeNode>;

        public var GAME_FRAME:int = 0;
        public var GAME_TIME:int = 0;

        public var GLOBAL_OFFSET_MS:int = 0;
        public var GLOBAL_OFFSET_FRAMES:int = 0;
        public var JUDGE_OFFSET_MS:int = 0;
        public var JUDGE_OFFSET_FRAMES:int;

        public var quitDoubleTap:int = -1;

        public var gameLastNoteFrame:Number;
        public var gameFirstNoteFrame:Number;

        public var gameLife:int;
        public var gameScore:int;
        public var gameRawGoods:Number;
        public var gameReplay:Array;
        public var autoplayCount:int;

        /** Contains a list of scores or other flags used in replay_hit.
         * The value is either:
         * [100]  Amazing
         * [50]   Perfect
         * [25]   Good
         * [5]    Average
         * [0]    Miss & Boo
         * [-5]   Missed Note After End Game
         * [-10]  End of Replay Hit Tag
         */
        public var gameReplayHit:Array;

        public var binReplayNotes:Vector.<ReplayBinFrame>;
        public var binReplayBoos:Vector.<ReplayBinFrame>;

        public var gameHistory:Vector.<GamePlaybackEvent>;

        public var replayPressCount:Number = 0;

        public var hitAmazing:int;
        public var hitPerfect:int;
        public var hitGood:int;
        public var hitAverage:int;
        public var hitMiss:int;
        public var hitBoo:int;
        public var hitCombo:int;
        public var hitMaxCombo:int;

        public var noteBoxOffset:Point = new Point();
        public var noteBoxPositionDefault:Object;

        public var GAME_STATE:uint = GAME_WAIT;

        public var SOCKET_SONG_MESSAGE:Object = {};
        public var SOCKET_SCORE_MESSAGE:Object = {};

        // Anti-GPU Rampdown Hack
        public var GPU_PIXEL_BMD:BitmapData;
        public var GPU_PIXEL_BITMAP:Bitmap;

        // Multiplayer
        public var isMultiplayer:Boolean = false;
        public var isMultiplayerSpectator:Boolean = false;
        public var spectatorHistoryUpdate:Boolean = false;
        public var spectatorHistory:Vector.<GamePlaybackEvent>;
        public var spectatorHistoryLastCount:Number;
        public var spectatorHistoryBuffer:ByteArray;
        public var spectatorPlayerVars:MPFFRState;
        public var mpUpdateTimer:Timer;
        public var mpSpectatorTimer:Timer;
        public var mpFFRRoom:MPRoomFFR;
        public var mpuiFFRScores:MPFFRScoreCompare;

        public function GameplayDisplay(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            options = _gvars.options;
            song = options.song;
            song.handleDirty(options);

            if (!options.isEditor && song.chart.Notes.length == 0)
            {
                Alert.add(_lang.string("error_chart_has_no_notes"), 120, Alert.RED);
                switchTo(Main.GAME_MENU_PANEL);
                return false;
            }

            // --- Multiplayer
            if (!options.isEditor && !options.replay && options.isMultiplayer)
            {
                _mp.addEventListener(MPEvent.SOCKET_DISCONNECT, destroyMultiplayer);
                _mp.addEventListener(MPEvent.SOCKET_ERROR, destroyMultiplayer);
                _mp.addEventListener(MPEvent.ROOM_LEAVE_OK, destroyMultiplayer);
                _mp.addEventListener(MPEvent.ROOM_DELETE_OK, destroyMultiplayer);

                if (_mp.GAME_ROOM is MPRoomFFR)
                {
                    mpFFRRoom = _mp.GAME_ROOM as MPRoomFFR;
                    mpFFRRoom.lastMatchIndex = -1;
                    _mp.addEventListener(MPEvent.FFR_SCORE_UPDATE, e_mpFFRScoreUpdate);

                    if (options.isSpectator && options.spectatorUser != null)
                    {
                        isMultiplayerSpectator = true;
                        spectatorPlayerVars = mpFFRRoom.getPlayerVariables(options.spectatorUser);
                        _mp.addEventListener(MPEvent.FFR_GET_PLAYBACK, e_mpFFRPlaybackUpdate)
                    }
                    else if (mpFFRRoom.getPlayerState(_mp.currentUser) == "loading")
                    {
                        isMultiplayer = true;

                        var noteskinData:String = options.noteskin == 0 ? _noteskins.lastCustomNoteskin : null;
                        _mp.sendCommand(new MPCFFRSongStart(mpFFRRoom, options.settingsEncode(), options.layout, noteskinData));
                    }
                }
            }

            if (options.isEditor)
            {
                if (options.isSpectator)
                    isMultiplayerSpectator = true;

                mpFFRRoom = new MPRoomFFR();

                var fakeMPPlayer:MPUser = new MPUser();
                fakeMPPlayer.update({"uid": 0, "name": "Velocity"});

                var fakeMatch:MPMatchFFR = new MPMatchFFR(mpFFRRoom);
                mpFFRRoom.activeMatch = fakeMatch;

                var fakePlayer:MPMatchFFRUser = new MPMatchFFRUser(mpFFRRoom, fakeMPPlayer);
                fakePlayer.raw_score = 50000;
                fakePlayer.good = 86;
                fakePlayer.average = 69;
                fakePlayer.miss = 76;
                fakePlayer.boo = 79;
                fakeMatch.users.push(fakePlayer);

                var fakeTeam:MPMatchFFRTeam = new MPMatchFFRTeam();
                fakeTeam.users.push(fakePlayer);
                fakeMatch.teams.push(fakeTeam);
            }

            // --- Per Song Options
            var perSongOptions:UserSongData = UserSongNotes.getSongUserInfo(song.songInfo);
            if (perSongOptions != null && !options.isEditor && !options.replay)
            {
                options.fill(); // Reset

                // Custom Offsets
                if (perSongOptions.set_custom_offsets)
                {
                    options.offsetJudge = perSongOptions.offset_judge;
                    options.offsetGlobal = perSongOptions.offset_music;
                }

                // Invert Mirror Mod
                if (perSongOptions.set_mirror_invert)
                {
                    if (options.modEnabled("mirror"))
                    {
                        options.mods.removeAt(options.mods.indexOf("mirror"));
                        delete options.modCache["mirror"];
                    }
                    else
                    {
                        options.mods.push("mirror");
                        options.modCache["mirror"] = true;
                    }
                }
            }
            // --- End Per Song Settings

            // --- Update RG values for Personal Best or AAA Equiv autofail/tracking if active
            if (options.personalBestMode || options.personalBestTracker || options.autofail[7] != 0)
            {
                var infoRanks:Object = _gvars.playerUser.getLevelRank(song.songInfo);
                var rawScoreMax:Number = song.songInfo.score_raw;

                if (rawScoreMax == 0)
                    rawScoreMax = song.chart.Notes.length * 50; // Alt engine hack as they often don't have a note count or raw max saved...

                if (infoRanks != null) // Alt engine will return null here if the song is unplayed, and if unplayed then we don't need to autofail them
                {
                    var rawDifference:Number = rawScoreMax - infoRanks.rawscore;

                    if (options.personalBestMode)
                        options.autofail[6] = rawDifference / 25;

                    if (options.personalBestTracker)
                        options.rawGoodTracker = rawDifference / 25;
                }

                if (options.autofail[7] != 0 && song.songInfo.engine == null) // Don't bother processing this if it's an Alt Engine
                {
                    // first check if the song can even meet that equiv, if not then set the autofail at non-AAA
                    if (song.songInfo.difficulty <= options.autofail[7])
                    {
                        options.autofail[6] = 0.2; //one boo's worth of RG, any non-AAA judgement will cause autofail
                    }
                    else
                    {
                        // need to convert the AAA equiv to a raw good max on this particular song to use for autofail
                        var calculatedRawGoods:Number = SkillRating.getRawGoodsFromEquiv(song.songInfo, options.autofail[7]);

                        // now set the autofail to that value
                        options.autofail[6] = calculatedRawGoods;
                    }
                }
            }
            // --- End Personal Best tracking

            return true;
        }

        override public function stageAdd():void
        {
            if (_gvars.menuMusic)
                _gvars.menuMusic.stop();

            if (MenuSongSelection.previewMusic)
                MenuSongSelection.previewMusic.stop();

            // Init Core
            initGameVars();
            initCore();
            initMultiplayer();

            // Preload next Song
            if (_gvars.songQueue.length > 0)
                _gvars.getSongFile(_gvars.songQueue[0]);

            // Stage Properties
            _gvars.gameMain.disablePopups = true;

            stage.focus = this.stage;
            stage.frameRate = options.frameRate;

            if (!options.isEditor && !options.replay && !isMultiplayerSpectator)
                Mouse.hide();

            if (song.songInfo && song.songInfo.name)
                stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE + " - " + StringUtil.stripHtml(song.songInfo.name);

            // Prebuild Websocket Message, this is updated instead of creating a new object every message.
            SOCKET_SONG_MESSAGE = {"player": {
                        "settings": options.settingsEncode(),
                        "name": _gvars.activeUser.name,
                        "userid": _gvars.activeUser.siteId,
                        "avatar": URLs.resolve(URLs.USER_AVATAR_URL) + "?uid=" + _gvars.activeUser.siteId,
                        "skill_rating": _gvars.activeUser.skillRating,
                        "skill_level": _gvars.activeUser.skillLevel,
                        "game_rank": _gvars.activeUser.gameRank,
                        "game_played": _gvars.activeUser.gamesPlayed,
                        "game_grand_total": _gvars.activeUser.grandTotal
                    },
                    "engine": (song.songInfo.engine == null ? null : {"id": song.songInfo.engine.id,
                            "name": song.songInfo.engine.name,
                            "config": song.songInfo.engine.config_url,
                            "domain": song.songInfo.engine.domain})
                    ,
                    "song": {
                        "name": song.songInfo.name,
                        "level": song.songInfo.level,
                        "difficulty": song.songInfo.difficulty,
                        "style": song.songInfo.style,
                        "author": song.songInfo.author,
                        "author_url": song.songInfo.author_url,
                        "stepauthor": song.songInfo.stepauthor,
                        "credits": song.songInfo.credits,
                        "genre": song.songInfo.genre,
                        "nps_min": song.songInfo.min_nps,
                        "nps_max": song.songInfo.max_nps,
                        // TODO: Check these fields
                        //"release_date": song.songInfo.releasedate,
                        //"song_rating": song.songInfo.song_rating,
                        // Trust the chart, not the playlist.
                        "time": song.chartTimeFormatted,
                        "time_seconds": song.chartTime,
                        "note_count": song.totalNotes,
                        "nps_avg": (song.totalNotes / song.chartTime)
                    },
                    "best_score": _gvars.activeUser.getLevelRank(song.songInfo)};

            SOCKET_SCORE_MESSAGE = {"amazing": 0,
                    "perfect": 0,
                    "good": 0,
                    "average": 0,
                    "miss": 0,
                    "boo": 0,
                    "score": 0,
                    "combo": 0,
                    "maxcombo": 0,
                    "restarts": 0,
                    "last_hit": null};

            // Set Defaults for Editor Mode
            if (options.isEditor)
            {
                SOCKET_SONG_MESSAGE["song"]["name"] = "Editor Mode";
                SOCKET_SONG_MESSAGE["song"]["author"] = "rCubed Engine";
                SOCKET_SONG_MESSAGE["song"]["difficulty"] = 0;
                SOCKET_SONG_MESSAGE["song"]["time"] = "10:00";
                SOCKET_SONG_MESSAGE["song"]["time_seconds"] = 600;
            }

            // Init Game
            interfaceBuild();
            interfaceSetup();
            initPlayerVars();

            // Add onEnterFrame Listeners
            if (options.isEditor)
            {
                options.isAutoplay = true;
                stage.addEventListener(Event.ENTER_FRAME, e_onFrameEditor, false, int.MAX_VALUE - 10, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, e_onKeyDownEditor, false, int.MAX_VALUE - 10, true);
            }
            else
            {
                stage.addEventListener(Event.ENTER_FRAME, e_onFrame, false, int.MAX_VALUE - 10, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, e_onKeyDown, true, int.MAX_VALUE - 10, true);
                stage.addEventListener(KeyboardEvent.KEY_UP, e_onKeyUp, true, int.MAX_VALUE - 10, true);

                    //stage.nativeWindow.addEventListener(Event.ACTIVATE, e_onWindowFocus);
                    //stage.nativeWindow.addEventListener(Event.DEACTIVATE, e_onWindowFocus);
            }

            if (!isMultiplayerSpectator)
            {
                GAME_STATE = GAME_PLAY;
                initSongStart();
            }
        }

        override public function stageRemove():void
        {
            trace("[GameplayDisplay] stageRemove");
            // Reset Window Title
            stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE;

            stage.frameRate = 60;

            if (options.isEditor)
            {
                _gvars.activeUser.screencutPosition = options.screencutPosition;
                stage.removeEventListener(Event.ENTER_FRAME, e_onFrameEditor);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, e_onKeyDownEditor);
            }
            else
            {
                stage.removeEventListener(Event.ENTER_FRAME, e_onFrame);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, e_onKeyDown, true);
                stage.removeEventListener(KeyboardEvent.KEY_UP, e_onKeyUp, true);

                    //stage.nativeWindow.removeEventListener(Event.ACTIVATE, e_onWindowFocus);
                    //stage.nativeWindow.removeEventListener(Event.DEACTIVATE, e_onWindowFocus);
            }

            destroyMultiplayer();

            _gvars.gameMain.disablePopups = false;

            // Disable Editor mode when leaving editor.
            options.isEditor = false;

            Mouse.show();
        }

        public function destroyMultiplayer(e:MPEvent = null):void
        {
            if (options.isEditor)
                return;

            if (isMultiplayer || isMultiplayerSpectator)
            {
                _mp.removeEventListener(MPEvent.SOCKET_DISCONNECT, destroyMultiplayer);
                _mp.removeEventListener(MPEvent.SOCKET_ERROR, destroyMultiplayer);
                _mp.removeEventListener(MPEvent.ROOM_LEAVE_OK, destroyMultiplayer);
                _mp.removeEventListener(MPEvent.ROOM_DELETE_OK, destroyMultiplayer);
                Flags.VALUES[Flags.MP_MENU_RETURN] = true;
            }

            if (spectatorHistory != null)
            {
                spectatorHistory = null;
                spectatorHistoryLastCount = 0;
                spectatorHistoryBuffer = null;
            }

            if (mpUpdateTimer != null)
            {
                mpUpdateTimer.stop();
                mpUpdateTimer.removeEventListener(TimerEvent.TIMER, e_onMPTimerTick);
                mpUpdateTimer = null;
            }

            if (mpSpectatorTimer != null)
            {
                mpSpectatorTimer.stop();
                mpSpectatorTimer.removeEventListener(TimerEvent.TIMER, e_onSpectatorTimerTick);
                mpSpectatorTimer = null;
            }

            if (mpFFRRoom != null)
            {
                _mp.removeEventListener(MPEvent.FFR_SCORE_UPDATE, e_mpFFRScoreUpdate);
                _mp.removeEventListener(MPEvent.FFR_GET_PLAYBACK, e_mpFFRPlaybackUpdate);
                mpFFRRoom = null;
            }

            isMultiplayer = false;
            isMultiplayerSpectator = false;
        }

        /*#########################################################################################*\
         *       _____       _ _   _       _ _
         *       \_   \_ __ (_) |_(_) __ _| (_)_______
         *	     / /\/ '_ \| | __| |/ _` | | |_  / _ \
         *	  /\/ /_ | | | | | |_| | (_| | | |/ /  __/
         *	  \____/ |_| |_|_|\__|_|\__,_|_|_/___\___|
         *
           \*#########################################################################################*/

        public function initCore():void
        {
            // Bound Isolation Note Mod
            if (options.isolationOffset >= song.chart.Notes.length)
                options.isolationOffset = song.chart.Notes.length - 1;

            // Song
            song.updateMusicOffset();
            if (song.background && !options.modEnabled("nobackground"))
            {
                uiSongBackground = song.background as MovieClip;
                uiSongBackground.x = 115;
                uiSongBackground.y = 42.5;
                addChild(uiSongBackground);
            }

            songDelay = song.mp3Frame / options.songRate * 1000 / 30 - GLOBAL_OFFSET_MS;
        }

        public function initGameVars():void
        {
            // Force no Judge on SongPreviews
            if (options.replay && options.replay.isPreview)
            {
                options.offsetJudge = 0;
                options.offsetGlobal = 0;
                options.isAutoplay = true;
            }

            reverseMod = options.modEnabled("reverse");
            sideScroll = (options.scrollDirection == "left" || options.scrollDirection == "right");

            JUDGE_OFFSET_FRAMES = Math.round(options.offsetJudge);
            GLOBAL_OFFSET_FRAMES = Math.round(options.offsetGlobal);

            GLOBAL_OFFSET_MS = (options.offsetGlobal - GLOBAL_OFFSET_FRAMES) * 1000 / 30;
            JUDGE_OFFSET_MS = options.offsetJudge * 1000 / 30;

            judgeSettings = buildJudgeNodes(options.judgeWindow ? options.judgeWindow : Constant.JUDGE_WINDOW);

            songOffset = new RollingAverage(1, _avars.configMusicOffset);
        }

        public function initSongStart(postStart:Boolean = true):void
        {
            // Post Start Time
            if (postStart && !_gvars.activeUser.isGuest && !options.replay && !options.isEditor && !options.isSpectator && song.songInfo.engine == null)
            {
                Logger.debug(this, "Posting Start of level " + song.id);
                _loader = new URLLoader();
                addLoaderListeners();

                var req:URLRequest = new URLRequest(URLs.resolve(URLs.SONG_START_URL));
                var requestVars:URLVariables = new URLVariables();
                Constant.addDefaultRequestVariables(requestVars);
                requestVars.session = _gvars.userSession;
                requestVars.id = song.id;
                requestVars.restarts = _gvars.songRestarts;
                req.data = requestVars;
                req.method = URLRequestMethod.POST;
                _loader.dataFormat = URLLoaderDataFormat.VARIABLES;
                _loader.load(req);
            }

            absoluteStart = getTimer();

            // Handle Early Charts - Pad Charts till atleast 2 seconds before first note.
            if (song != null && song.totalNotes > 0 && options.isolationOffset == 0)
            {
                var firstNote:Note = song.getNote(0);
                if (firstNote.time < 2)
                    absoluteStart += (2 - firstNote.time) * 1000;
            }

            // Websocket
            if (_gvars.air_useWebsockets)
            {
                SOCKET_SCORE_MESSAGE["amazing"] = hitAmazing;
                SOCKET_SCORE_MESSAGE["perfect"] = hitPerfect;
                SOCKET_SCORE_MESSAGE["good"] = hitGood;
                SOCKET_SCORE_MESSAGE["average"] = hitAverage;
                SOCKET_SCORE_MESSAGE["boo"] = hitBoo;
                SOCKET_SCORE_MESSAGE["miss"] = hitMiss;
                SOCKET_SCORE_MESSAGE["combo"] = hitCombo;
                SOCKET_SCORE_MESSAGE["maxcombo"] = hitMaxCombo;
                SOCKET_SCORE_MESSAGE["score"] = gameScore;
                SOCKET_SCORE_MESSAGE["last_hit"] = null;
                SOCKET_SCORE_MESSAGE["restarts"] = _gvars.songRestarts;
                _gvars.websocketSend("NOTE_JUDGE", SOCKET_SCORE_MESSAGE);
                _gvars.websocketSend("SONG_START", SOCKET_SONG_MESSAGE);
            }
        }

        public function initPlayerVars():void
        {
            // Game Vars
            _keyDown = {};
            gameLife = 50;
            gameScore = 0;
            gameRawGoods = 0;
            gameReplay = [];
            gameReplayHit = [];
            autoplayCount = 0;

            hitAmazing = 0;
            hitPerfect = 0;
            hitGood = 0;
            hitAverage = 0;
            hitMiss = 0;
            hitBoo = 0;
            hitCombo = 0;
            hitMaxCombo = 0;

            // Replay
            replayPressCount = 0;

            binReplayNotes = new Vector.<ReplayBinFrame>(song.totalNotes, true);
            binReplayBoos = new <ReplayBinFrame>[];
            gameHistory = new <GamePlaybackEvent>[];

            // Prefill Replay
            for (var i:int = song.totalNotes - 1; i >= 0; i--)
                binReplayNotes[i] = new ReplayBinFrame(NaN, song.getNote(i).direction, i);

            if (song != null && song.totalNotes > 0)
            {
                gameLastNoteFrame = song.getNote(song.totalNotes - 1).frame + Math.ceil(song.songInfo.time_end * 30);
                gameFirstNoteFrame = song.getNote(0).frame;
            }

            absoluteStart = getTimer();
            absolutePosition = 0;
            GAME_TIME = 0;
            GAME_FRAME = 0;

            songOffset = new RollingAverage(options.frameRate * 4, _avars.configMusicOffset);
            frameRate = new RollingAverage(options.frameRate * 4, options.frameRate);
            accuracy = new Average();

            songDelayStarted = false;

            if (options.isAutoplay)
                autoplayCount++;

            // Update UI
            updateFieldVars();

            if (uiNoteCount)
                uiNoteCount.update(song.totalNotes);

            if (uiLifebar)
                uiLifebar.health = gameLife;

            if (uiProgressDisplayText)
                uiProgressDisplayText.update(TimeUtil.convertToHMSS(Math.ceil(gameLastNoteFrame / 30)));
        }

        public function initMultiplayer():void
        {
            if (options.isEditor)
                return;

            if (isMultiplayer || isMultiplayerSpectator)
            {
                spectatorHistory = new <GamePlaybackEvent>[];
                spectatorHistoryLastCount = 0;
                spectatorHistoryBuffer = new ByteArray();
            }

            if (isMultiplayer)
            {
                mpUpdateTimer = new Timer(200);
                mpUpdateTimer.addEventListener(TimerEvent.TIMER, e_onMPTimerTick);
                mpUpdateTimer.start();
            }

            if (isMultiplayerSpectator)
            {
                mpSpectatorTimer = new Timer(1000);
                mpSpectatorTimer.addEventListener(TimerEvent.TIMER, e_onSpectatorTimerTick);
                mpSpectatorTimer.start();
            }

        }

        public function siteLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            var data:URLVariables = e.target.data;
            Logger.success(this, "Post Start Load Success = " + data.result);
            if (data.result == "success")
            {
                _gvars.songStartTime = data.current_date;
                _gvars.songStartHash = data.current_time;
            }
        }

        public function siteLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Post Start Load Failure: " + Logger.event_error(err));
            removeLoaderListeners();
        }

        /*#########################################################################################*\
         *        __                 _
         *       /__\_   _____ _ __ | |_ ___
         *      /_\ \ \ / / _ \ '_ \| __/ __|
         *     //__  \ V /  __/ | | | |_\__ \
         *     \__/   \_/ \___|_| |_|\__|___/
         *
           \*#########################################################################################*/

        public function e_onWindowFocus(e:Event):void
        {
            if (e.type == Event.ACTIVATE)
                gameHistory.push(new GamePlaybackFocusChange(gameHistory.length, GAME_TIME, true));
            else
                gameHistory.push(new GamePlaybackFocusChange(gameHistory.length, GAME_TIME, false));
        }

        public function e_onFrame(e:Event):void
        {
            // UI Updates
            if (uiJudge != null)
                uiJudge.updateJudge(e);

            // Gameplay Logic
            switch (GAME_STATE)
            {
                case GAME_PLAY:
                    var lastAbsolutePosition:int = absolutePosition;
                    absolutePosition = getTimer() - absoluteStart;

                    if (!songDelayStarted)
                    {
                        if (absolutePosition >= songDelay)
                        {
                            songDelayStarted = true;
                            song.start();
                        }
                    }

                    var songPosition:int = song.getPosition() + songDelay;
                    if (song.musicIsPlaying && songPosition > 100)
                        songOffset.addValue(songPosition - absolutePosition);

                    frameRate.addValue(1000 / (absolutePosition - lastAbsolutePosition));

                    GAME_TIME = Math.round(absolutePosition + songOffset.value);

                    var targetProgress:int = Math.round(GAME_TIME * 30 / 1000 - 0.5);
                    var threshold:int = Math.round(1 / (frameRate.value / 60));
                    if (threshold < 1)
                        threshold = 1;
                    if (options.replay)
                        threshold = 0x7fffffff;

                    //Logger.debug("GP", "lAP: " + lastAbsolutePosition + " | aP: " + absolutePosition + " | sDS: " + songDelayStarted + " | sD: " + songDelay + " | sOv: " + songOffset.value + " | sGP: " + song.getPosition() + " | sP: " + songPosition + " | gP: " + GAME_TIME + " | tP: " + targetProgress + " | t: " + threshold);

                    while (GAME_FRAME < targetProgress && threshold-- > 0)
                        logicTick();

                    if (reverseMod)
                        stopClips(uiSongBackground, 2 + song.musicStartFrames - GLOBAL_OFFSET_FRAMES + GAME_FRAME * options.songRate);
                    else
                        stopClips(uiSongBackground, 2 + song.musicStartFrames - GLOBAL_OFFSET_FRAMES + GAME_FRAME * options.songRate);

                    if (options.modEnabled("tap_pulse"))
                    {
                        noteBoxOffset.x = Math.max(Math.min(Math.abs(noteBoxOffset.x) < 0.5 ? 0 : (noteBoxOffset.x * 0.992), uiNoteField.positionOffsetMax.max_x), uiNoteField.positionOffsetMax.min_x);
                        noteBoxOffset.y = Math.max(Math.min(Math.abs(noteBoxOffset.y) < 0.5 ? 0 : (noteBoxOffset.y * 0.992), uiNoteField.positionOffsetMax.max_y), uiNoteField.positionOffsetMax.min_y);

                        uiNoteField.x = noteBoxPositionDefault.x + noteBoxOffset.x;
                        uiNoteField.y = noteBoxPositionDefault.y + noteBoxOffset.y;
                    }

                    uiNoteField.update(GAME_TIME);

                    if (uiProgressDisplay)
                        uiProgressDisplay.update(GAME_FRAME / gameLastNoteFrame, false);
                    break;

                case GAME_END:
                    endGame();
                    break;

                case GAME_RESTART:
                    restartGame();
                    break;
            }

            e.stopImmediatePropagation();
        }

        public function e_onKeyUp(e:KeyboardEvent):void
        {
            const keyCode:int = e.keyCode;
            const pressTime:int = getTimer() - absoluteStart + songOffset.value;

            //gameHistory.push(new GameKeyUpEvent(gameHistory.length, pressTime, keyCode));

            // Set Key as used.
            _keyDown[keyCode] = false;

            e.stopImmediatePropagation();
        }

        public function e_onKeyDown(e:KeyboardEvent):void
        {
            const keyCode:int = e.keyCode;
            const pressTime:int = getTimer() - absoluteStart + songOffset.value;

            //gameHistory.push(new GameKeyDownEvent(gameHistory.length, pressTime, keyCode));

            // Don't allow key presses unless the key is up.
            if (_keyDown[keyCode])
                return;

            // Set Key as used.
            _keyDown[keyCode] = true;

            // Handle judgement of key presses.
            if (gameLife > 0)
            {
                if (!options.replay)
                {
                    var dir:String = null;
                    switch (keyCode)
                    {
                        case _gvars.activeUser.keyLeft:
                            dir = "L";
                            break;

                        case _gvars.activeUser.keyRight:
                            dir = "R";
                            break;

                        case _gvars.activeUser.keyUp:
                            dir = "U";
                            break;

                        case _gvars.activeUser.keyDown:
                            dir = "D";
                            break;
                    }

                    if (dir != null)
                    {
                        judgeScorePosition(dir, pressTime);

                        if (isMultiplayer)
                            spectatorHistory.push(new GamePlaybackSpectatorHit(spectatorHistory.length, pressTime, dir));
                    }
                }
            }

            // Game Restart
            if (keyCode == _gvars.playerUser.keyRestart && !options.isMultiplayer)
            {
                GAME_STATE = GAME_RESTART;
            }

            // Quit
            else if (keyCode == _gvars.playerUser.keyQuit)
            {
                if (_gvars.songQueue.length > 0)
                {
                    if (quitDoubleTap > 0)
                    {
                        _gvars.songQueue.length = 0;
                        GAME_STATE = GAME_END;
                    }
                    else
                    {
                        quitDoubleTap = options.frameRate / 4;
                    }
                }
                else
                {
                    GAME_STATE = GAME_END;
                }
            }

            // Pause
            else if (keyCode == 19 && (CONFIG::debug || _gvars.playerUser.isAdmin || _gvars.playerUser.isDeveloper || options.replay))
            {
                togglePause();
            }

            // Auto-Play
            else if (e.ctrlKey && keyCode == Keyboard.F8)
            {
                options.isAutoplay = !options.isAutoplay;
                autoplayCount++;
                Alert.add("Bot Play: " + options.isAutoplay, 120, Alert.RED);
            }

            e.stopImmediatePropagation();
        }

        public function e_progressMouseClick(e:MouseEvent):void
        {
            var seek:int = (e.localX / e.target.width) * gameLastNoteFrame;
            if (seek < GAME_FRAME)
                restartGame();

            absoluteStart = getTimer();
            songOffset.reset(seek * 1000 / 30);
            song.start(seek * 1000 / 30);

            while (GAME_FRAME < seek)
                logicTick();

            songDelayStarted = true;
        }

        public function e_onFrameEditor(e:Event):void
        {
            // State 0 = Gameplay
            if (GAME_STATE == GAME_PLAY)
            {
                GAME_TIME = getTimer() - absoluteStart;
                var targetProgress:int = Math.round(GAME_TIME * 30 / 1000);

                // Update Notes
                while (GAME_FRAME < targetProgress)
                {
                    logicTick();
                }

                uiNoteField.update(GAME_TIME);
            }
            // State 1 = End Game
            else if (GAME_STATE == GAME_END)
            {
                endGame();
                return;
            }
        }

        public function e_onKeyDownEditor(e:KeyboardEvent):void
        {
            if (uiNoteField == null)
                return;

            var keyCode:int = e.keyCode;
            var dir:String = "";

            if (keyCode == _gvars.playerUser.keyQuit)
            {
                GAME_STATE = GAME_END;
                return;
            }

            switch (keyCode)
            {
                case _gvars.playerUser.keyLeft:
                    dir = "L";
                    break;

                case _gvars.playerUser.keyRight:
                    dir = "R";
                    break;

                case _gvars.playerUser.keyUp:
                    dir = "U";
                    break;

                case _gvars.playerUser.keyDown:
                    dir = "D";
                    break;
            }

            if (dir != "")
                uiNoteField.spawnArrow(new Note(dir, (GAME_FRAME + 31) / 30, "red", GAME_FRAME + 31), (GAME_FRAME + JUDGE_OFFSET_FRAMES + 5) / 30 * 1000);
        }

        /*#########################################################################################*\
         *	   ___                         ___                 _   _
         *	  / _ \__ _ _ __ ___   ___    / __\   _ _ __   ___| |_(_) ___  _ __  ___
         *	 / /_\/ _` | '_ ` _ \ / _ \  / _\| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         *	/ /_\\ (_| | | | | | |  __/ / /  | |_| | | | | (__| |_| | (_) | | | \__ \
         *	\____/\__,_|_| |_| |_|\___| \/    \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
         *
           \*#########################################################################################*/
        public function e_onMPTimerTick(e:Event = null):void
        {
            if (mpFFRRoom == null)
                return;

            //_mp.sendCommand(new MPCFFRSongProgress(mpFFRRoom, GAME_TIME));

            if (spectatorHistoryLastCount != spectatorHistory.length)
            {
                spectatorHistoryBuffer.length = 0;

                // Score
                _mp.sendCommand(new MPCFFRScoreUpdate(mpFFRRoom, gameScore, hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo, hitCombo, hitMaxCombo));

                // Spectator Playback
                const newEvents:int = spectatorHistory.length - spectatorHistoryLastCount;
                spectatorHistoryBuffer.writeByte(MPEvent.RAW_TYPE_MODE);
                spectatorHistoryBuffer.writeByte(MPEvent.FFR_RAW_APPEND_PLAYBACK);
                spectatorHistoryBuffer.writeUnsignedInt(mpFFRRoom.uid);

                for (var i:int = spectatorHistoryLastCount; i < spectatorHistory.length; i++)
                {
                    spectatorHistory[i].writeData(spectatorHistoryBuffer);
                }

                _mp.sendBytes(spectatorHistoryBuffer);

                spectatorHistoryLastCount = spectatorHistory.length;
                spectatorHistoryUpdate = false;
            }
            else if (spectatorHistoryUpdate)
            {
                _mp.sendCommand(new MPCFFRScoreUpdate(mpFFRRoom, gameScore, hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo, hitCombo, hitMaxCombo));
                spectatorHistoryUpdate = false;
            }
        }

        public function e_onSpectatorTimerTick(e:Event):void
        {
            if (mpFFRRoom == null)
                return;

            _mp.sendCommand(new MPCFFRPlaybackRequest(mpFFRRoom, options.spectatorUser, spectatorHistoryLastCount));
        }

        public function e_mpFFRScoreUpdate(e:MPRoomEvent):void
        {
            if (mpFFRRoom != e.room)
                return;

            if (mpuiFFRScores)
                mpuiFFRScores.update();
        }

        public function e_mpFFRPlaybackUpdate(e:MPRoomRawEvent):void
        {
            if (mpFFRRoom != e.room || options.spectatorUser != e.user)
                return;

            var cmd:MPSocketDataRaw = e.command;

            GamePlaybackReader.parse(cmd.data, 18, spectatorHistory); // Header is 1 + 1 + 4 + 4 + 4 + 4 Bytes

            cmd.data.position = 10;
            var start_index:uint = cmd.data.readUnsignedInt();
            var end_index:uint = cmd.data.readUnsignedInt();

            spectatorHistoryLastCount = end_index;

            if (GAME_STATE == GAME_WAIT && spectatorHistory.length > 0)
            {
                GAME_STATE = GAME_PLAY;

                //  Skip Ahead
                var lastTimestamp:int = Math.max(0, spectatorHistory[spectatorHistory.length - 1].timestamp - 5000);
                var lastFrame:int = lastTimestamp / 1000 * 30;

                absoluteStart = getTimer() - lastTimestamp;
                song.start(lastTimestamp);

                while (GAME_FRAME < lastFrame)
                    logicTick();

                songDelayStarted = true;
            }
        }

        public function logicTick():void
        {
            GAME_FRAME++;

            // Anti-GPU Rampdown Trick
            if (GAME_FRAME % 15 == 0)
            {
                if ((GAME_FRAME & 1) == 0)
                    GPU_PIXEL_BMD.setPixel(0, 0, 0x010101);
                else
                    GPU_PIXEL_BMD.setPixel(0, 0, 0x020202);
            }

            if (quitDoubleTap > 0)
                quitDoubleTap--;

            if (GAME_FRAME >= gameLastNoteFrame + 20 || quitDoubleTap == 0)
            {
                GAME_STATE = GAME_END;
                return;
            }

            // Timer Text
            if (GAME_FRAME % 30 == 0 && uiProgressDisplayText != null)
                uiProgressDisplayText.update(TimeUtil.convertToHMSS(Math.ceil((gameLastNoteFrame - GAME_FRAME) / 30)));

            // Note Spawning
            var nextNote:Note = uiNoteField.nextNote;
            while (nextNote && nextNote.frame <= GAME_FRAME + JUDGE_OFFSET_FRAMES + 5)
            {
                uiNoteField.spawnArrow(nextNote, (GAME_FRAME + JUDGE_OFFSET_FRAMES + 5) / 30 * 1000);
                nextNote = uiNoteField.nextNote;
            }

            // Missed Notes
            var notes:Vector.<GameNote> = uiNoteField.notes;
            for (var n:int = 0; n < notes.length; n++)
            {
                var curNote:GameNote = notes[n];

                if (GAME_FRAME - curNote.FRAME + JUDGE_OFFSET_FRAMES >= 6)
                {
                    if (isMultiplayer)
                        spectatorHistoryUpdate = true;

                    commitJudge(curNote.DIR, GAME_FRAME, -10);
                    uiNoteField.removeNote(curNote.ID);
                    n--;
                }
                else
                    break;
            }

            // Auto Play
            if (options.isAutoplay)
                tickAutoplay();

            // Replays
            else if (options.replay && !options.replay.isPreview)
                tickReplays();

            // Multiplayer Spectator
            else if (options.isSpectator)
                tickSpectator();
        }

        public function tickAutoplay():void
        {
            var notes:Vector.<GameNote> = uiNoteField.notes;
            for (var n:int = 0; n < notes.length; n++)
            {
                var curNote:GameNote = notes[n];

                if (GAME_FRAME - curNote.FRAME + JUDGE_OFFSET_FRAMES >= 0)
                {
                    var isDec:Boolean = (Math.floor(curNote.ID / 32) & 1) == 1;
                    var offset:int = (isDec ? 32 - (curNote.ID % 32) : (curNote.ID % 32)) - 16;

                    if (options.isEditor)
                    {
                        commitJudge(curNote.DIR, (curNote.FRAME + JUDGE_OFFSET_FRAMES), 50);
                        uiNoteField.removeNote(curNote.ID);
                    }
                    else
                        judgeScorePosition(curNote.DIR, curNote.POSITION - JUDGE_OFFSET_MS + offset);

                    if (isMultiplayer)
                        spectatorHistory.push(new GamePlaybackSpectatorHit(spectatorHistory.length, curNote.POSITION - JUDGE_OFFSET_MS + offset, curNote.DIR));
                    n--;
                }
            }
        }

        public function tickReplays():void
        {
            var notes:Vector.<GameNote> = uiNoteField.notes;
            var newPress:ReplayNote = options.replay.getPress(replayPressCount);

            if (options.replay.needsBeatboxGeneration)
            {
                var oldPosition:int = GAME_TIME;
                GAME_TIME = (GAME_FRAME + 0.5) * 1000 / 30;
                var cutOffReplayNote:uint = options.replay.generationReplayNotes.length;
                var readAheadTime:Number = (1 / frameRate.value) * 1000;

                // Note Hits
                for (var n:int = 0; n < notes.length; n++)
                {
                    var curNote:GameNote = notes[n];

                    // Missed Note
                    if (curNote.ID >= cutOffReplayNote || (options.replay.generationReplayNotes[curNote.ID] == null || isNaN(options.replay.generationReplayNotes[curNote.ID].time)))
                        continue;

                    var diffValue:int = options.replay.generationReplayNotes[curNote.ID].time + curNote.POSITION;
                    if ((GAME_TIME + readAheadTime >= diffValue) || GAME_TIME >= diffValue)
                    {
                        judgeScorePosition(curNote.DIR, diffValue);
                        n--;
                    }
                }

                // Boo Handling
                while (newPress != null && GAME_TIME >= newPress.time)
                {
                    if (newPress.frame == -2)
                    {
                        commitJudge(newPress.direction, GAME_FRAME, -5);
                        binReplayBoos[binReplayBoos.length] = new ReplayBinFrame(newPress.time, newPress.direction, binReplayBoos.length);
                    }
                    replayPressCount++;
                    newPress = options.replay.getPress(replayPressCount);
                }

                GAME_TIME = oldPosition;
            }
            else
            {
                while (newPress != null && newPress.frame == GAME_FRAME)
                {
                    judgeScore(newPress.direction, newPress.frame);

                    replayPressCount++;
                    newPress = options.replay.getPress(replayPressCount);
                }
            }
        }

        public function tickSpectator():void
        {
            if (spectatorHistory.length <= 0 || replayPressCount >= spectatorHistory.length)
                return;

            var oldPosition:int = GAME_TIME;

            GAME_TIME = (GAME_FRAME + 0.5) * 1000 / 30;

            var hit:GamePlaybackEvent = spectatorHistory[replayPressCount];

            while (replayPressCount < spectatorHistory.length)
            {
                hit = spectatorHistory[replayPressCount];

                if (hit.timestamp > GAME_TIME)
                    break;

                // Skip Non-hits
                if (hit.id == GamePlaybackSpectatorHit.ID)
                {
                    judgeScorePosition((hit as GamePlaybackSpectatorHit).direction, hit.timestamp);
                    replayPressCount++;
                }
                else if (hit.id == GamePlaybackSpectatorEnd.ID)
                {
                    GAME_STATE = GAME_END;
                    break;
                }
                else
                {
                    replayPressCount++;
                }
            }

            GAME_TIME = oldPosition;
        }

        public function togglePause():void
        {
            if (GAME_STATE == GAME_PLAY)
            {
                GAME_STATE = GAME_PAUSE;
                songPausePosition = getTimer();
                song.pause();

                if (_gvars.air_useWebsockets)
                {
                    _gvars.websocketSend("SONG_PAUSE", SOCKET_SONG_MESSAGE);
                }
            }
            else if (GAME_STATE == GAME_PAUSE)
            {
                GAME_STATE = GAME_PLAY;
                absoluteStart += (getTimer() - songPausePosition);
                song.resume();

                if (_gvars.air_useWebsockets)
                {
                    _gvars.websocketSend("SONG_RESUME", SOCKET_SONG_MESSAGE);
                }
            }
        }

        public function endGame():void
        {
            if (GAME_STATE == GAME_DISPOSE || song == null)
                return;

            // Stop Music Play
            song.stop();

            // Play through to the end of a replay
            if (options.replay)
            {
                GAME_STATE = GAME_PLAY;
                while (gameLife > 0 && GAME_STATE == GAME_PLAY)
                    logicTick();
                GAME_STATE = GAME_END;
            }

            // Multiplayer
            const wasMultiplayer:Boolean = isMultiplayer;
            if (isMultiplayer)
            {
                spectatorHistory.push(new GamePlaybackSpectatorEnd(spectatorHistory.length, getTimer() - absoluteStart + songOffset.value));
                e_onMPTimerTick();
            }
            else if (isMultiplayer || isMultiplayerSpectator)
                destroyMultiplayer();

            // Save results for display
            if (!options.isEditor && !options.isSpectator)
            {
                if (autoplayCount > 0)
                    options.isAutoplay = true;

                // Fill missing notes from replay.
                if (gameReplayHit.length > 0)
                {
                    while (gameReplayHit.length < song.totalNotes)
                    {
                        gameReplayHit.push(-5);
                    }
                }
                gameReplayHit.push(-10);
                gameReplay.sort(ReplayNote.sortFunction)

                const noteCount:int = hitAmazing + hitPerfect + hitGood + hitAverage + hitMiss;

                var newGameResults:GameScoreResult = new GameScoreResult();
                newGameResults.game_index = _gvars.gameIndex++;
                newGameResults.level = song.id;
                newGameResults.song = song;
                newGameResults.songInfo = song.songInfo;
                newGameResults.note_count = song.totalNotes;
                newGameResults.amazing = hitAmazing;
                newGameResults.perfect = hitPerfect;
                newGameResults.good = hitGood;
                newGameResults.average = hitAverage;
                newGameResults.boo = hitBoo;
                newGameResults.miss = hitMiss;
                newGameResults.combo = hitCombo;
                newGameResults.max_combo = hitMaxCombo;
                newGameResults.score = gameScore;
                newGameResults.last_note = noteCount < song.totalNotes ? noteCount : 0;
                newGameResults.accuracy = accuracy.value;
                newGameResults.accuracy_deviation = accuracy.deviation;
                newGameResults.options = this.options;
                newGameResults.restart_stats = _gvars.songStats.data;
                newGameResults.replayData = gameReplay.concat();
                newGameResults.replay_hit = gameReplayHit.concat();
                newGameResults.replay_bin_notes = binReplayNotes;
                newGameResults.replay_bin_boos = binReplayBoos;
                newGameResults.user = options.replay ? options.replay.user : _gvars.activeUser;
                newGameResults.restarts = options.replay ? 0 : _gvars.songRestarts;
                newGameResults.start_time = _gvars.songStartTime;
                newGameResults.start_hash = _gvars.songStartHash;
                newGameResults.end_time = options.replay ? TimeUtil.getFormattedDate(new Date(options.replay.timestamp * 1000)) : TimeUtil.getCurrentDate();
                newGameResults.song_progress = (GAME_FRAME / gameLastNoteFrame);

                // Set Note Counts for Preview Songs
                if (options.replay && options.replay.isPreview)
                {
                    newGameResults.is_preview = true;
                    newGameResults.score = song.totalNotes * 50;
                    newGameResults.amazing = song.totalNotes;
                    newGameResults.max_combo = song.totalNotes;
                }

                newGameResults.update(_gvars);
                _gvars.songResults.push(newGameResults);
            }

            if (!options.replay && !options.isEditor && !options.isSpectator)
            {
                _gvars.sessionStats.addFromStats(_gvars.songStats);
                _gvars.songStats.reset();

                _avars.configMusicOffset = (_avars.configMusicOffset * 0.85) + songOffset.value * 0.15;

                // Cap between 5 seconds for sanity.
                if (Math.abs(_avars.configMusicOffset) >= 5000)
                    _avars.configMusicOffset = Math.max(-5000, Math.min(5000, _avars.configMusicOffset));

                _avars.musicOffsetSave();
            }

            // Websocket
            if (_gvars.air_useWebsockets)
            {
                SOCKET_SCORE_MESSAGE["amazing"] = hitAmazing;
                SOCKET_SCORE_MESSAGE["perfect"] = hitPerfect;
                SOCKET_SCORE_MESSAGE["good"] = hitGood;
                SOCKET_SCORE_MESSAGE["average"] = hitAverage;
                SOCKET_SCORE_MESSAGE["boo"] = hitBoo;
                SOCKET_SCORE_MESSAGE["miss"] = hitMiss;
                SOCKET_SCORE_MESSAGE["combo"] = hitCombo;
                SOCKET_SCORE_MESSAGE["maxcombo"] = hitMaxCombo;
                SOCKET_SCORE_MESSAGE["score"] = gameScore;
                SOCKET_SCORE_MESSAGE["last_hit"] = null;
                _gvars.websocketSend("NOTE_JUDGE", SOCKET_SCORE_MESSAGE);
                _gvars.websocketSend("SONG_END", SOCKET_SONG_MESSAGE);
            }

            // Cleanup
            initPlayerVars();

            if (song != null)
            {
                song.stop();
                song = null;
            }

            interfaceDestroy();

            GAME_STATE = GAME_DISPOSE;

            // Go to results
            if (options.isEditor || options.isSpectator)
                switchTo(Main.GAME_MENU_PANEL);
            else if (wasMultiplayer)
                switchTo(GameMenu.GAME_MP_WAIT);
            else
                switchTo(GameMenu.GAME_RESULTS);
        }

        public function restartGame():void
        {
            // Remove Notes
            uiNoteField.reset();

            if (uiPAWindow)
                uiPAWindow.reset();

            if (uiAccuracyBar)
                uiAccuracyBar.onResetSignal();

            if (uiJudge)
                uiJudge.hideJudge();

            noteBoxOffset.x = 0;
            noteBoxOffset.y = 0;

            // Track
            var tempGT:Number = ((hitAmazing + hitPerfect) * 500) + (hitGood * 250) + (hitAverage * 50) + (hitCombo * 1000) - (hitMiss * 300) - (hitBoo * 15) + gameScore;
            _gvars.songStats.amazing += hitAmazing;
            _gvars.songStats.perfect += hitPerfect;
            _gvars.songStats.good += hitGood;
            _gvars.songStats.average += hitAverage;
            _gvars.songStats.miss += hitMiss;
            _gvars.songStats.boo += hitBoo;
            _gvars.songStats.raw_score += gameScore;
            _gvars.songStats.amazing += hitAmazing;
            _gvars.songStats.grandtotal += tempGT;
            _gvars.songStats.credits += Math.round(tempGT / _gvars.SCORE_PER_CREDIT);
            _gvars.songStats.restarts++;

            // Restart
            song.stop();
            GAME_STATE = GAME_PLAY;
            initGameVars();
            initPlayerVars();
            initSongStart();

            _gvars.songRestarts++;

            // Websocket
            if (_gvars.air_useWebsockets)
            {
                SOCKET_SCORE_MESSAGE["restarts"] = _gvars.songRestarts;
                _gvars.websocketSend("NOTE_JUDGE", SOCKET_SCORE_MESSAGE);
                _gvars.websocketSend("SONG_RESTART", SOCKET_SONG_MESSAGE);
            }
        }

        public function stopClips(clip:MovieClip, frame:int):void
        {
            if (!clip)
                return;

            if (frame < 2)
                frame = 2;

            switch (clip.currentFrame - frame + 1)
            {
                case 0:
                    clip.nextFrame();
                case 1:
                    break;
                default:
                    clip.gotoAndStop(frame);
                    break;
            }

            for (var i:int = 0; i < clip.numChildren; i++)
                stopClips(clip.getChildAt(i) as MovieClip, frame);
        }

        /*#########################################################################################*\
         *			_____     ___               _   _
         *	 /\ /\  \_   \   / __\ __ ___  __ _| |_(_) ___  _ __
         *	/ / \ \  / /\/  / / | '__/ _ \/ _` | __| |/ _ \| '_ \
         *	\ \_/ /\/ /_   / /__| | |  __/ (_| | |_| | (_) | | | |
         *	 \___/\____/   \____/_|  \___|\__,_|\__|_|\___/|_| |_|
         *
           \*#########################################################################################*/

        public function interfaceBuild():void
        {
            stage.color = GameBackgroundColor.BG_STAGE;

            // Anti-GPU Rampdown Hack
            GPU_PIXEL_BMD = new BitmapData(1, 1, false, 0x010101);
            GPU_PIXEL_BITMAP = new Bitmap(GPU_PIXEL_BMD);
            addChild(GPU_PIXEL_BITMAP);

            uiNoteField = new NoteBox(song, options, this);
            uiNoteField.position();

            if (options.displayScreencut)
                uiScreenCut = new ScreenCut(options, this);

            if (options.displayGameTopBar)
            {
                bgTopBar = sideScroll ? new BarTopSideways() : new BarTopNormal();
                addChild(bgTopBar);
            }

            if (options.displayGameBottomBar)
            {
                bgBottomBar = sideScroll ? new BarBottomSideways() : new BarBottomNormal();
                addChild(bgBottomBar);
            }

            if (options.displayPA)
            {
                uiPAWindow = new PAWindow(options, this);

                if (sideScroll)
                    uiPAWindow.alternateLayout();
            }

            if (options.displayScore)
                uiScore = new Score(options, this);

            if (options.displayCombo)
            {
                uiCombo = new Combo(options, this);
                if (!sideScroll)
                    uiCombo.alignment = "right";

                uiComboStatic = new TextStatic(_lang.string("game_combo"), this);
            }

            if (options.displayRawGoods)
            {
                uiRawGoods = new RawGoods(options, this);
                uiRawGoodsStatic = new TextStatic(_lang.string("game_raw_goods"), this, options.rawGoodsColor, 12);
            }

            if (options.displayComboTotal)
            {
                uiNoteCount = new Combo(options, this);
                if (sideScroll)
                    uiNoteCount.alignment = "right";

                uiNoteCountStatic = new TextStatic(_lang.string("game_combo_total"), this);
            }

            if (options.displayAccuracyBar)
                uiAccuracyBar = new AccuracyBar(options, this);

            if (options.displaySongProgress || options.replay)
            {
                uiProgressDisplay = new ProgressBar(this, 161, 9, 458, 20, 4, 0x545454, 0.1);

                if (options.replay)
                    uiProgressDisplay.addEventListener(MouseEvent.CLICK, e_progressMouseClick);
            }

            if (options.displaySongProgressText)
                uiProgressDisplayText = new TextStatic("0:00", this);

            if (options.displayJudge)
            {
                uiJudge = new Judge(options, this);

                if (options.isEditor)
                    uiJudge.showJudge(100, true);
            }

            if (options.displayHealth)
                uiLifebar = new LifeBar(this);

            if (options.displayMultiplayerScores && (isMultiplayer || isMultiplayerSpectator || options.isEditor))
                mpuiFFRScores = new MPFFRScoreCompare(options, this, mpFFRRoom);

            if (options.isEditor)
            {
                function closeEditor(e:MouseEvent):void
                {
                    GAME_STATE = GAME_END;
                    if (!options.replay)
                    {
                        _gvars.activeUser.saveLocal();
                        _gvars.activeUser.save();
                    }
                }

                function resetLayout(e:MouseEvent):void
                {
                    for (var key:String in options.layout)
                        delete options.layout[key];
                    _avars.interfaceSave();
                    interfaceSetup();
                }

                btnExitEditor = new BoxButton(this, (Main.GAME_WIDTH - 75) / 2, (Main.GAME_HEIGHT - 30) / 2, 75, 30, _lang.string("menu_close"), 12, closeEditor);
                btnResetEditor = new BoxButton(this, btnExitEditor.x, btnExitEditor.y + 35, 75, 30, _lang.string("menu_reset"), 12, resetLayout);
            }
        }

        public function interfaceDestroy():void
        {
            if (uiSongBackground)
            {
                this.removeChild(uiSongBackground);
                uiSongBackground = null;
            }

            if (GPU_PIXEL_BITMAP)
            {
                this.removeChild(GPU_PIXEL_BITMAP);
                GPU_PIXEL_BITMAP = null;
                GPU_PIXEL_BMD = null;
            }
            if (uiProgressDisplay)
            {
                this.removeChild(uiProgressDisplay);
                uiProgressDisplay = null;
            }
            if (uiLifebar)
            {
                this.removeChild(uiLifebar);
                uiLifebar = null;
            }
            if (uiJudge)
            {
                this.removeChild(uiJudge);
                uiJudge = null;
            }
            if (bgTopBar)
            {
                this.removeChild(bgTopBar);
                bgTopBar = null;
            }
            if (bgBottomBar)
            {
                this.removeChild(bgBottomBar);
                bgBottomBar = null;
            }
            if (uiNoteField)
            {
                uiNoteField.reset();
                this.removeChild(uiNoteField);
                uiNoteField = null;
            }
            if (uiScreenCut)
            {
                this.removeChild(uiScreenCut);
                uiScreenCut = null;
            }

            if (btnExitEditor)
            {
                btnExitEditor.dispose();
                this.removeChild(btnExitEditor);
                btnExitEditor = null;
            }
            if (btnResetEditor)
            {
                btnResetEditor.dispose();
                this.removeChild(btnResetEditor);
                btnResetEditor = null;
            }
        }

        public function interfaceLayout(key:String, defaults:Boolean = true):Object
        {
            if (defaults)
            {
                var ret:Object = {};
                var def:Object = defaultLayout[key];

                for (var i:String in def)
                    ret[i] = def[i];

                var layout:Object = options.layout[key];
                for (i in layout)
                    ret[i] = layout[i];

                return ret;
            }
            else if (!options.layout[key])
                options.layout[key] = {};

            return options.layout[key];
        }

        public function interfaceSetup():void
        {
            defaultLayout = {};
            defaultLayout[LAYOUT_PROGRESS_BAR] = {x: 161, y: 9};
            defaultLayout[LAYOUT_PROGRESS_TEXT] = {x: 768, y: 5, alignment: "right"};
            defaultLayout[LAYOUT_JUDGE] = {x: 392, y: 228};
            defaultLayout[LAYOUT_ACCURACY_BAR] = {x: (Main.GAME_WIDTH / 2), y: 328};
            defaultLayout[LAYOUT_HEALTH] = {x: Main.GAME_WIDTH - 37, y: 71.5};
            defaultLayout[LAYOUT_RECEPTORS] = {x: 230, y: 0};

            if (sideScroll)
            {
                defaultLayout[LAYOUT_PA] = {x: 16, y: 418};
                defaultLayout[LAYOUT_SCORE] = {x: 392, y: 24};
                defaultLayout[LAYOUT_COMBO] = {x: 508, y: 388};
                defaultLayout[LAYOUT_COMBO_TOTAL] = {x: 770, y: 420, alignment: "right"};
                defaultLayout[LAYOUT_COMBO_STATIC] = {x: 512, y: 450};
                defaultLayout[LAYOUT_COMBO_TOTAL_STATIC] = {x: 734, y: 414};
                defaultLayout[LAYOUT_RAWGOODS] = {x: 90, y: 35};
                defaultLayout[LAYOUT_RAWGOODS_STATIC] = {x: 16, y: 53};
            }
            else
            {
                defaultLayout[LAYOUT_PA] = {x: 6, y: 96};
                defaultLayout[LAYOUT_SCORE] = {x: 392, y: 440};
                defaultLayout[LAYOUT_COMBO] = {x: 222, y: 402, alignment: "right"};
                defaultLayout[LAYOUT_COMBO_TOTAL] = {x: 544, y: 402};
                defaultLayout[LAYOUT_COMBO_STATIC] = {x: 228, y: 436};
                defaultLayout[LAYOUT_COMBO_TOTAL_STATIC] = {x: 502, y: 436};
                defaultLayout[LAYOUT_RAWGOODS] = {x: 80, y: 365};
                defaultLayout[LAYOUT_RAWGOODS_STATIC] = {x: 4, y: 380};
            }

            // MP
            defaultLayout[LAYOUT_MP_FFR_SCORE] = {x: Main.GAME_WIDTH - 150, y: 0};

            //
            noteBoxPositionDefault = interfaceLayout(LAYOUT_RECEPTORS);

            // Position
            interfacePosition(uiProgressDisplay, interfaceLayout(LAYOUT_PROGRESS_BAR));
            interfacePosition(uiProgressDisplayText, interfaceLayout(LAYOUT_PROGRESS_TEXT));
            interfacePosition(uiNoteField, interfaceLayout(LAYOUT_RECEPTORS));
            interfacePosition(uiAccuracyBar, interfaceLayout(LAYOUT_ACCURACY_BAR));
            interfacePosition(uiLifebar, interfaceLayout(LAYOUT_HEALTH));
            interfacePosition(uiScore, interfaceLayout(LAYOUT_SCORE));
            interfacePosition(uiNoteCount, interfaceLayout(LAYOUT_COMBO_TOTAL));
            interfacePosition(uiComboStatic, interfaceLayout(LAYOUT_COMBO_STATIC));
            interfacePosition(uiNoteCountStatic, interfaceLayout(LAYOUT_COMBO_TOTAL_STATIC));
            interfacePosition(uiRawGoodsStatic, interfaceLayout(LAYOUT_RAWGOODS_STATIC));

            interfacePosition(uiPAWindow, interfaceLayout(LAYOUT_PA));
            interfacePosition(uiCombo, interfaceLayout(LAYOUT_COMBO));
            interfacePosition(uiRawGoods, interfaceLayout(LAYOUT_RAWGOODS))
            interfacePosition(uiJudge, interfaceLayout(LAYOUT_JUDGE));

            interfacePosition(mpuiFFRScores, interfaceLayout(LAYOUT_MP_FFR_SCORE));

            // Editor Mode
            if (options.isEditor)
            {
                interfaceEditor(uiProgressDisplay, interfaceLayout(LAYOUT_PROGRESS_BAR, false));
                interfaceEditor(uiProgressDisplayText, interfaceLayout(LAYOUT_PROGRESS_TEXT, false));
                interfaceEditor(uiNoteField, interfaceLayout(LAYOUT_RECEPTORS, false));
                interfaceEditor(uiAccuracyBar, interfaceLayout(LAYOUT_ACCURACY_BAR, false));
                interfaceEditor(uiLifebar, interfaceLayout(LAYOUT_HEALTH, false));
                interfaceEditor(uiScore, interfaceLayout(LAYOUT_SCORE, false));
                interfaceEditor(uiNoteCount, interfaceLayout(LAYOUT_COMBO_TOTAL, false));
                interfaceEditor(uiComboStatic, interfaceLayout(LAYOUT_COMBO_STATIC, false));
                interfaceEditor(uiNoteCountStatic, interfaceLayout(LAYOUT_COMBO_TOTAL_STATIC, false));
                interfaceEditor(uiRawGoodsStatic, interfaceLayout(LAYOUT_RAWGOODS_STATIC, false));

                interfaceEditor(uiPAWindow, interfaceLayout(LAYOUT_PA, false));
                interfaceEditor(uiCombo, interfaceLayout(LAYOUT_COMBO, false));
                interfaceEditor(uiRawGoods, interfaceLayout(LAYOUT_RAWGOODS, false))
                interfaceEditor(uiJudge, interfaceLayout(LAYOUT_JUDGE, false));

                interfaceEditor(mpuiFFRScores, interfaceLayout(LAYOUT_MP_FFR_SCORE, false));
            }
        }

        public function interfacePosition(sprite:Sprite, layout:Object):void
        {
            if (!sprite)
                return;

            for (var p:String in layout)
                if (p in sprite)
                    sprite[p] = layout[p];
        }

        public function interfaceEditor(sprite:Sprite, layout:Object):void
        {
            if (!sprite)
                return;

            sprite.mouseChildren = false;
            sprite.buttonMode = true;
            sprite.useHandCursor = true;

            sprite.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
            {
                sprite.startDrag(false);
            });
            sprite.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
            {
                sprite.stopDrag();
                layout["x"] = sprite.x;
                layout["y"] = sprite.y;
                _avars.interfaceSave();
            });
        }

        /*#########################################################################################*\
         *	   ___                           _
         *	  / _ \__ _ _ __ ___   ___ _ __ | | __ _ _   _
         *	 / /_\/ _` | '_ ` _ \ / _ \ '_ \| |/ _` | | | |
         *	/ /_\\ (_| | | | | | |  __/ |_) | | (_| | |_| |
         *	\____/\__,_|_| |_| |_|\___| .__/|_|\__,_|\__, |
         *							  |_|            |___/
           \*#########################################################################################*/

        public function buildJudgeNodes(src:Array):Vector.<JudgeNode>
        {
            var out:Vector.<JudgeNode> = new Vector.<JudgeNode>(src.length, true);
            for (var i:int = 0; i < src.length; i++)
            {
                out[i] = new JudgeNode(src[i].t, src[i].s, src[i].f);
            }
            return out;
        }

        /**
         * Judge a note score based on the current song position in ms.
         * @param dir Note Direction
         * @param position Time in MS.
         * @return
         */
        public function judgeScorePosition(dir:String, position:int):Boolean
        {
            if (position < 0)
                position = 0;

            var positionJudged:int = position + JUDGE_OFFSET_MS;

            var score:int = 0;
            var frame:int = 0;
            var booConflict:Boolean = false;
            for each (var note:GameNote in uiNoteField.notes)
            {
                if (note.DIR != dir)
                    continue;

                var rawAccuracy:Number = note.POSITION - position;
                var judgeAccuracy:Number = positionJudged - note.POSITION;
                var lastJudge:JudgeNode = null;
                for each (var j:JudgeNode in judgeSettings)
                {
                    if (judgeAccuracy > j.time)
                        lastJudge = j;
                }
                score = lastJudge ? lastJudge.score : 0;

                if (score)
                    frame = lastJudge.frame;

                if (!_avars.configJudge && !score)
                {
                    var pdiff:int = GAME_FRAME - note.FRAME + JUDGE_OFFSET_FRAMES;
                    if (pdiff >= -3 && pdiff <= 3)
                    {
                        booConflict = true;
                    }
                }

                if (score > 0)
                    break;
                else if (judgeAccuracy <= judgeSettings[0].time)
                    break;
            }

            if (score)
            {
                commitJudge(dir, frame + note.FRAME - JUDGE_OFFSET_FRAMES, score);
                uiNoteField.removeNote(note.ID);
                accuracy.addValue(rawAccuracy);
                binReplayNotes[note.ID].time = judgeAccuracy;

                if (uiAccuracyBar != null)
                    uiAccuracyBar.onScoreSignal(score, judgeAccuracy);
            }
            else
            {
                var booFrame:int = GAME_FRAME;
                if (booConflict)
                {
                    var noteIndex:int = 0;
                    note = (noteIndex < uiNoteField.notes.length - 1 ? uiNoteField.notes[noteIndex++] : uiNoteField.spawnNextNote());
                    while (note)
                    {
                        if (booFrame + JUDGE_OFFSET_FRAMES < note.FRAME - 3)
                            break;
                        if (note.DIR == dir)
                            booFrame = note.FRAME + 4 - JUDGE_OFFSET_FRAMES;

                        note = (noteIndex < uiNoteField.notes.length - 1 ? uiNoteField.notes[noteIndex++] : uiNoteField.spawnNextNote());
                    }
                }

                if (booFrame >= gameFirstNoteFrame)
                    binReplayBoos[binReplayBoos.length] = new ReplayBinFrame(position, dir, binReplayBoos.length);

                commitJudge(dir, booFrame, -5);
            }

            if (options.modEnabled("tap_pulse"))
            {
                if (dir == "L")
                    noteBoxOffset.x -= Math.abs(options.receptorSpacing * 0.20);
                if (dir == "R")
                    noteBoxOffset.x += Math.abs(options.receptorSpacing * 0.20);
                if (dir == "U")
                    noteBoxOffset.y -= Math.abs(options.receptorSpacing * 0.15);
                if (dir == "D")
                    noteBoxOffset.y += Math.abs(options.receptorSpacing * 0.15);
            }

            return score > 0;
        }

        public function judgeScore(dir:String, frame:int):Boolean
        {
            var score:int = 0;
            for each (var note:GameNote in uiNoteField.notes)
            {
                if (note.DIR != dir)
                    continue;

                var diff:int = frame + JUDGE_OFFSET_FRAMES - note.FRAME;
                switch (diff)
                {
                    case -3:
                        score = 5;
                        break;
                    case -2:
                        score = 25;
                        break;
                    case -1:
                        score = 50;
                        break;
                    case 0:
                        score = 100;
                        break;
                    case 1:
                        score = 50;
                        break;
                    case 2:
                    case 3:
                        score = 25;
                        break;
                    default:
                        score = 0;
                        break;
                }

                if (score > 0)
                    break;
                else if (diff < -3)
                    break;
            }

            if (options.modEnabled("tap_pulse"))
            {
                if (dir == "L")
                    noteBoxOffset.x -= Math.abs(options.receptorSpacing * 0.20);
                if (dir == "R")
                    noteBoxOffset.x += Math.abs(options.receptorSpacing * 0.20);
                if (dir == "U")
                    noteBoxOffset.y -= Math.abs(options.receptorSpacing * 0.15);
                if (dir == "D")
                    noteBoxOffset.y += Math.abs(options.receptorSpacing * 0.15);
            }

            if (score)
            {
                commitJudge(dir, frame, score);
                uiNoteField.removeNote(note.ID);
                accuracy.addValue((note.FRAME - frame) * 1000 / 30);

                if (uiAccuracyBar != null)
                    uiAccuracyBar.onScoreSignal(score, diff * 33.3333 - 1);
            }
            else
                commitJudge(dir, frame, -5);

            return Boolean(score);
        }

        public function commitJudge(dir:String, frame:int, score:int):void
        {
            var health:int = 0;
            var jscore:int = score;
            uiNoteField.receptorFeedback(dir, score);
            switch (score)
            {
                case 100:
                    hitAmazing++;
                    hitCombo++;
                    gameScore += 50;
                    health = 1;
                    if (options.displayAmazing)
                    {
                        checkAutofail(options.autofail[0], hitAmazing);
                    }
                    else
                    {
                        jscore = 50;
                        checkAutofail(options.autofail[0] + options.autofail[1], hitAmazing + hitPerfect);
                    }
                    checkAutofail(options.autofail[6], gameRawGoods);
                    break;
                case 50:
                    hitPerfect++;
                    hitCombo++;
                    gameScore += 50;
                    health = 1;
                    checkAutofail(options.autofail[1], hitPerfect);
                    checkAutofail(options.autofail[6], gameRawGoods);
                    break;
                case 25:
                    hitGood++;
                    hitCombo++;
                    gameScore += 25;
                    gameRawGoods += 1;
                    health = 1;
                    checkAutofail(options.autofail[2], hitGood);
                    checkAutofail(options.autofail[6], gameRawGoods);
                    break;
                case 5:
                    hitAverage++;
                    hitCombo++;
                    gameScore += 5;
                    gameRawGoods += 1.8;
                    health = 1;
                    checkAutofail(options.autofail[3], hitAverage);
                    checkAutofail(options.autofail[6], gameRawGoods);
                    break;
                case -5:
                    if (frame < gameFirstNoteFrame)
                        return;
                    hitBoo++;
                    gameScore -= 5;
                    gameRawGoods += 0.2;
                    health = -1;
                    checkAutofail(options.autofail[5], hitBoo);
                    checkAutofail(options.autofail[6], gameRawGoods);
                    break;
                case -10:
                    hitMiss++;
                    hitCombo = 0;
                    gameScore -= 10;
                    gameRawGoods += 2.4;
                    health = -1;
                    checkAutofail(options.autofail[4], hitMiss);
                    checkAutofail(options.autofail[6], gameRawGoods);
                    break;
            }

            if (options.isAutoplay)
            {
                gameScore = 0;
                hitAmazing = 0;
                hitPerfect = 0;
                hitGood = 0;
                hitAverage = 0;
            }

            if (uiJudge && !options.isEditor)
                uiJudge.showJudge(jscore);

            updateHealth(health > 0 ? _gvars.HEALTH_JUDGE_ADD : _gvars.HEALTH_JUDGE_REMOVE);

            if (hitCombo > hitMaxCombo)
                hitMaxCombo = hitCombo;

            if (score == -10)
                gameReplayHit.push(0);
            else if (score == -5)
                score = 0;

            if (score > 0)
                gameReplayHit.push(score);

            if (score >= 0)
                gameReplay.push(new ReplayNote(dir, frame, Math.round(getTimer() - absoluteStart + songOffset.value), score));

            updateFieldVars();

            // Websocket
            if (_gvars.air_useWebsockets)
            {
                SOCKET_SCORE_MESSAGE["amazing"] = hitAmazing;
                SOCKET_SCORE_MESSAGE["perfect"] = hitPerfect;
                SOCKET_SCORE_MESSAGE["good"] = hitGood;
                SOCKET_SCORE_MESSAGE["average"] = hitAverage;
                SOCKET_SCORE_MESSAGE["boo"] = hitBoo;
                SOCKET_SCORE_MESSAGE["miss"] = hitMiss;
                SOCKET_SCORE_MESSAGE["combo"] = hitCombo;
                SOCKET_SCORE_MESSAGE["maxcombo"] = hitMaxCombo;
                SOCKET_SCORE_MESSAGE["score"] = gameScore;
                SOCKET_SCORE_MESSAGE["last_hit"] = score;
                _gvars.websocketSend("NOTE_JUDGE", SOCKET_SCORE_MESSAGE);
            }
        }

        public function checkAutofail(autofail:Number, hit:Number):void
        {
            if (autofail > 0 && hit >= autofail)
            {
                if (options.autofail_restart)
                    GAME_STATE = GAME_RESTART;
                else
                    GAME_STATE = GAME_END;
            }
        }

        /*#########################################################################################*\
         *		   _                 _                   _       _
         *	/\   /(_)___ _   _  __ _| |  /\ /\ _ __   __| | __ _| |_ ___  ___
         *	\ \ / / / __| | | |/ _` | | / / \ \ '_ \ / _` |/ _` | __/ _ \/ __|
         *	 \ V /| \__ \ |_| | (_| | | \ \_/ / |_) | (_| | (_| | ||  __/\__ \
         *	  \_/ |_|___/\__,_|\__,_|_|  \___/| .__/ \__,_|\__,_|\__\___||___/
         *									  |_|
           \*#########################################################################################*/

        public function updateHealth(val:int):void
        {
            gameLife += val;

            if (gameLife <= 0)
                GAME_STATE = GAME_END;
            else if (gameLife > 100)
                gameLife = 100;

            if (uiLifebar)
                uiLifebar.health = gameLife;
        }

        public function updateFieldVars():void
        {
            if (uiPAWindow)
                uiPAWindow.update(hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo);

            if (uiScore)
                uiScore.update(gameScore);

            if (uiCombo)
                uiCombo.update(hitCombo, hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo, gameRawGoods);

            if (uiRawGoods)
                uiRawGoods.update(gameRawGoods);
        }

        public function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, siteLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, siteLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, siteLoadError);
        }

        public function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, siteLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, siteLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, siteLoadError);
        }
    }
}

internal class JudgeNode
{
    public var time:Number;
    public var frame:Number;
    public var score:Number;

    public function JudgeNode(time:Number, score:Number, frame:Number = -1)
    {
        this.time = time;
        this.score = score;
        this.frame = frame;
    }
}
