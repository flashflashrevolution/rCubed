package game
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerSingleton;
    import assets.gameplay.viewLR;
    import assets.gameplay.viewUD;
    import classes.Alert;
    import classes.GameNote;
    import classes.Language;
    import classes.Noteskins;
    import classes.User;
    import classes.Gameplay;
    import classes.chart.LevelScriptRuntime;
    import classes.chart.Note;
    import classes.chart.NoteChart;
    import classes.chart.Song;
    import classes.replay.ReplayNote;
    import classes.ui.BoxButton;
    import classes.ui.ProgressBar;
    import com.flashfla.net.Multiplayer;
    import com.flashfla.utils.Average;
    import com.flashfla.utils.RollingAverage;
    import com.flashfla.utils.TimeUtil;
    import com.flashfla.net.events.GameUpdateEvent;
    import com.flashfla.net.events.GameResultsEvent;
    import flash.display.GradientType;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.ui.Keyboard;
    import flash.ui.Mouse;
    import flash.utils.getTimer;
    import game.controls.Combo;
    import game.controls.ComboStatic;
    import game.controls.Judge;
    import game.controls.LifeBar;
    import game.controls.MPHeader;
    import game.controls.NoteBox;
    import game.controls.PAWindow;
    import game.controls.Score;
    import menu.MenuPanel;
    import menu.MenuSongSelection;
    import sql.SQLSongUserInfo;

    public class GameplayDisplay extends MenuPanel
    {
        public static const GAME_DISPOSE:int = -1;
        public static const GAME_PLAY:int = 0;
        public static const GAME_END:int = 1;
        public static const GAME_RESTART:int = 2;
        public static const GAME_PAUSE:int = 3;

        public static const LAYOUT_RECEPTORS:String = "receptors";
        public static const LAYOUT_JUDGE:String = "judge";
        public static const LAYOUT_HEALTH:String = "health";
        public static const LAYOUT_SCORE:String = "score";
        public static const LAYOUT_COMBO:String = "combo";
        public static const LAYOUT_COMBO_TOTAL:String = "combototal";
        public static const LAYOUT_COMBO_STATIC:String = "combostatic";
        public static const LAYOUT_COMBO_TOTAL_STATIC:String = "combototalstatic";
        public static const LAYOUT_PA:String = "pa";

        public static const LAYOUT_MP_JUDGE:String = "mpjudge";
        public static const LAYOUT_MP_COMBO:String = "mpcombo";
        public static const LAYOUT_MP_PA:String = "mppa";
        public static const LAYOUT_MP_HEADER:String = "mpheader";

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _noteskins:Noteskins = Noteskins.instance;
        private var _lang:Language = Language.instance;
        private var _loader:URLLoader;
        private var _keys:Array;
        private var song:Song;
        private var song_background:MovieClip;
        private var legacyMode:Boolean;
        private var levelScript:LevelScriptRuntime;

        private var reverseMod:Boolean;
        private var sideScroll:Boolean;
        private var defaultLayout:Object;

        private var displayBlackBG:Sprite;
        private var gameplayUI:*;
        private var progressDisplay:ProgressBar;
        private var noteBox:NoteBox;
        private var paWindow:PAWindow;
        private var score:Score;
        private var combo:Combo;
        private var comboTotal:Combo;
        private var comboStatic:ComboStatic;
        private var comboTotalStatic:ComboStatic;
        private var screenCut:Sprite;
        private var flashLight:Sprite;
        private var exitEditor:BoxButton;
        private var resetEditor:BoxButton;

        private var player1Life:LifeBar;
        private var player1Judge:Judge;
        private var player1JudgeOffset:int;

        private var mpHeader:Array;
        private var mpCombo:Array;
        private var mpJudge:Array;
        private var mpPA:Array;

        private var msStartTime:Number = 0;
        private var absoluteStart:int = 0;
        private var absolutePosition:int = 0;
        private var songPausePosition:int = 0;
        private var songDelay:int = 0;
        private var songDelayStarted:Boolean = false;
        private var songOffset:RollingAverage;
        private var frameRate:RollingAverage;
        private var gamePosition:int = 0;
        private var gameProgress:int = 0;
        private var globalOffset:int = 0;
        private var globalOffsetRounded:int = 0;
        private var accuracy:Average;
        private var judgeOffset:int = 0;
        private var autoJudgeOffset:Boolean = false;
        private var judgeSettings:Array;

        private var quitDoubleTap:int = -1;

        private var options:GameOptions;
        private var mpSpectate:Boolean;

        private var gameLastNoteFrame:Number;
        private var gameFirstNoteFrame:Number;
        private var gameSongFrames:int;

        private var gameLife:int;
        private var gameScore:int;
        private var gameRawGoods:Number;
        private var gameReplay:Array;

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
        private var gameReplayHit:Array;

        private var binReplayNotes:Array;
        private var binReplayBoos:Array;

        private var replayPressCount:Number = 0;

        private var keyDirections:Array = ["L", "D", "U", "R"];
        private var hitAmazing:int;
        private var hitPerfect:int;
        private var hitGood:int;
        private var hitAverage:int;
        private var hitMiss:int;
        private var hitBoo:int;
        private var hitCombo:int;
        private var hitMaxCombo:int;

        private var noteBoxOffset:Object = {"x": 0, "y": 0};
        private var noteBoxPositionDefault:Object;

        private var keyHints:Array;

        private var GAME_STATE:uint = GAME_PLAY;

        private var SOCKET_SONG_MESSAGE:Object = {};
        private var SOCKET_SCORE_MESSAGE:Object = {};

        // Anti-GPU Rampdown Hack
        private var GPU_PIXEL_BMD:BitmapData;
        private var GPU_PIXEL_BITMAP:Bitmap;

        public function GameplayDisplay(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            options = _gvars.options;
            song = options.song;
            if (!options.isEditor && song.chart.Notes.length == 0)
            {
                Alert.add("Chart has no notes, returning to main menu...", 120, Alert.RED);
                var screen:int = _gvars.activeUser.startUpScreen;
                if (!_gvars.activeUser.isGuest && (screen == 0 || screen == 1) && !MultiplayerSingleton.getInstance().connection.connected)
                {
                    MultiplayerSingleton.getInstance().connection.connect();
                }
                switchTo(Main.GAME_MENU_PANEL);
                return false;
            }

            // --- Per Song Options
            var perSongOptions:SQLSongUserInfo = SQLQueries.getSongUserInfo(song.songInfo);
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
                        delete options.modCache["mirror"];
                    else
                        options.modCache["mirror"] = true;
                }
            }
            // --- End Per Song Settings

            return true;
        }

        // protected function initStage3D(e:Event):void
        // {
        //     // //var context3D:Context3D = stage.stage3Ds[0].context3D;
        //     //context3D.createProgram()		
        // }

        override public function stageAdd():void
        {
            if (_gvars.menuMusic)
                _gvars.menuMusic.stop();

            if (MenuSongSelection.previewMusic)
                MenuSongSelection.previewMusic.stop();

            // var stage3D:Stage3D = stage.stage3Ds[0];
            // stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, initStage3D);
            // stage.stage3Ds[0].requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.ENHANCED);

            // Create Background
            initBackground();
            initPlayerVars();

            // Init Core
            initCore();

            // Prebuild Websocket Message, this is updated instead of creating a new object every message.
            SOCKET_SONG_MESSAGE = {"player": {
                        "settings": options.settingsEncode(),
                        "name": _gvars.activeUser.name,
                        "userid": _gvars.activeUser.siteId,
                        "avatar": Constant.USER_AVATAR_URL + "?uid=" + _gvars.activeUser.siteId,
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
                        "author_url": song.songInfo.stepauthorURL,
                        "stepauthor": song.songInfo.stepauthor,
                        "credits": song.songInfo.credits,
                        "genre": song.songInfo.genre,
                        "nps_min": song.songInfo.minNps,
                        "nps_max": song.songInfo.maxNps,
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
            initUI();
            initVars();

            // Preload next Song
            if (_gvars.songQueue.length > 0)
            {
                _gvars.getSongFile(_gvars.songQueue[0]);
            }

            // Setup MP Things
            if (options.mpRoom)
            {
                MultiplayerSingleton.getInstance().gameplayPlaying(this);
                if (!options.isEditor)
                {
                    options.singleplayer = false; // Back to multiplayer lobby
                    options.mpRoom.connection.addEventListener(Multiplayer.EVENT_GAME_UPDATE, onMultiplayerUpdate);
                    if (mpSpectate)
                        options.mpRoom.connection.addEventListener(Multiplayer.EVENT_GAME_RESULTS, onMultiplayerResults);
                }
            }
            else
            {
                options.singleplayer = true; // Back to song selection
            }
            stage.focus = this.stage;

            interfaceSetup();

            _gvars.gameMain.disablePopups = true;

            if (!options.isEditor && !options.replay && !mpSpectate)
                Mouse.hide();

            if (song.songInfo && song.songInfo.name)
                stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE + " - " + song.songInfo.name;

            // Add onEnterFrame Listeners
            if (options.isEditor)
            {
                options.isAutoplay = true;
                stage.frameRate = options.frameRate;
                stage.addEventListener(Event.ENTER_FRAME, editorOnEnterFrame, false, int.MAX_VALUE - 10, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, editorKeyboardKeyDown, false, int.MAX_VALUE - 10, true);
            }
            else
            {
                stage.frameRate = song.frameRate;
                stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, int.MAX_VALUE - 10, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardKeyDown, true, int.MAX_VALUE - 10, true);
                stage.addEventListener(KeyboardEvent.KEY_UP, keyboardKeyUp, true, int.MAX_VALUE - 10, true);
            }
        }

        override public function stageRemove():void
        {
            stage.frameRate = 60;
            if (options.isEditor)
            {
                _gvars.activeUser.screencutPosition = options.screencutPosition;
                stage.removeEventListener(Event.ENTER_FRAME, editorOnEnterFrame);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, editorKeyboardKeyDown);
            }
            else
            {
                stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyboardKeyDown, true);
                stage.removeEventListener(KeyboardEvent.KEY_UP, keyboardKeyUp, true);

                if (options.mpRoom)
                {
                    options.mpRoom.connection.removeEventListener(Multiplayer.EVENT_GAME_UPDATE, onMultiplayerUpdate);
                    options.mpRoom.connection.removeEventListener(Multiplayer.EVENT_GAME_RESULTS, onMultiplayerResults);
                }
            }

            _gvars.gameMain.disablePopups = false;

            // Disable Editor mode when leaving editor.
            options.isEditor = false;

            Mouse.show();
        }

        /*#########################################################################################*\
         *       _____       _ _   _       _ _
         *       \_   \_ __ (_) |_(_) __ _| (_)_______
         *	     / /\/ '_ \| | __| |/ _` | | |_  / _ \
         *	  /\/ /_ | | | | | |_| | (_| | | |/ /  __/
         *	  \____/ |_| |_|_|\__|_|\__,_|_|_/___\___|
         *
           \*#########################################################################################*/

        private function initCore():void
        {
            // Bound Isolation Note Mod
            if (options.isolationOffset >= song.chart.Notes.length)
                options.isolationOffset = song.chart.Notes.length - 1;

            // Song
            song.updateMusicDelay();
            legacyMode = (song.type == NoteChart.FFR || song.type == NoteChart.FFR_RAW || song.type == NoteChart.FFR_LEGACY);
            if (song.music && (legacyMode || !options.modEnabled("nobackground")))
            {
                song_background = song.music as MovieClip;
                gameSongFrames = song_background.totalFrames;
                song_background.x = 115;
                song_background.y = 42.5;
                this.addChild(song_background);
                if (options.modEnabled("nobackground"))
                    setChildIndex(song_background, 0);
            }
            song.start();
            songDelay = song.mp3Frame / options.songRate * 1000 / 30 - globalOffset;
        }

        private function initBackground():void
        {
            // Anti-GPU Rampdown Hack
            GPU_PIXEL_BMD = new BitmapData(1, 1, false, 0x010101);
            GPU_PIXEL_BITMAP = new Bitmap(GPU_PIXEL_BMD);
            this.addChild(GPU_PIXEL_BITMAP);

            // if (!displayBlackBG)
            // {
            //     displayBlackBG = new Sprite();
            //     displayBlackBG.graphics.beginFill(0x000000);
            //     displayBlackBG.graphics.drawRect(-Main.GAME_WIDTH, -Main.GAME_WIDTH, Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);
            //     this.addChild(displayBlackBG);
            // }
        }

        private function initUI():void
        {
            noteBox = new NoteBox(song, options);
            noteBox.position();
            this.addChild(noteBox);

            if (!options.isEditor && MultiplayerSingleton.getInstance().connection.connected && !MultiplayerSingleton.getInstance().isInRoom())
            {
                var isInSoloMode:Boolean = true;
                MultiplayerSingleton.getInstance().connection.disconnect(isInSoloMode);
            }

            /*
               if (false && !_gvars.tempFlags["key_hints"] && !options.multiplayer && !options.isEditor && !options.replay && !mpSpectate) {
               keyHints = [];
               togglePause();
               var aa:Alert;
               for each(var rec:MovieClip in noteBox.receptorArray) {
               aa = new Alert(StringUtil.keyCodeChar(_gvars.activeUser["key" + rec.KEY]));
               if(rec.VERTEX == "y") {
               aa.x = rec.x - (aa.width / 2);
               aa.y = rec.y - ((rec.height / 2) * rec.DIRECTION) - (10 * rec.DIRECTION);
               if (rec.DIRECTION == 1) aa.y -= aa.height;
               } else {
               aa.x = rec.x - ((rec.width / 2) * rec.DIRECTION) - (10 * rec.DIRECTION);;
               aa.y = rec.y - (aa.height / 2);
               if (rec.DIRECTION == 1) aa.x -= aa.width;
               }
               noteBox.addChild(aa);
               keyHints.push(aa);
               }
               _gvars.tempFlags["key_hints"] = true;
               }
             */

            buildFlashlight();

            buildScreenCut();

            gameplayUI = (sideScroll ? new viewLR() : new viewUD());
            this.addChild(gameplayUI);

            if (!options.displayGameTopBar)
                gameplayUI.top_bar.visible = false;

            if (!options.displayGameBottomBar)
                gameplayUI.bottom_bar.visible = false;

            if (options.displayPA)
            {
                paWindow = new PAWindow(options);
                if (sideScroll)
                    paWindow.alternateLayout();
                this.addChild(paWindow);
            }

            if (options.displayScore)
            {
                score = new Score(options);
                this.addChild(score);
            }

            if (options.displayCombo)
            {
                combo = new Combo(options);
                if (!sideScroll)
                    combo.alignment = Combo.ALIGN_RIGHT;
                this.addChild(combo);

                comboStatic = new ComboStatic(_lang.string("game_combo"));
                this.addChild(comboStatic);
            }

            if (options.displayComboTotal)
            {
                comboTotal = new Combo(options);
                if (sideScroll)
                    comboTotal.alignment = Combo.ALIGN_RIGHT;
                this.addChild(comboTotal);

                comboTotalStatic = new ComboStatic(_lang.string("game_combo_total"));
                this.addChild(comboTotalStatic);
            }

            if (options.displaySongProgress || options.replay)
            {
                progressDisplay = new ProgressBar(gameplayUI, 161, 9.35, 458, 20, 4, 0x545454, 0.1);

                if (options.replay)
                    progressDisplay.addEventListener(MouseEvent.CLICK, progressMouseClick);
            }

            if (!mpSpectate)
            {
                buildJudge();
                buildHealth();
            }

            if (options.mpRoom)
                buildMultiplayer();

            if (options.isEditor)
            {
                gameplayUI.mouseChildren = false;
                gameplayUI.mouseEnabled = false;

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

                exitEditor = new BoxButton(this, (Main.GAME_WIDTH - 75) / 2, (Main.GAME_HEIGHT - 30) / 2, 75, 30, _lang.string("menu_close"), 12, closeEditor);
                resetEditor = new BoxButton(this, exitEditor.x, exitEditor.y + 35, 75, 30, _lang.string("menu_reset"), 12, resetLayout);
            }
        }

        private function initPlayerVars():void
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
            player1JudgeOffset = Math.round(options.offsetJudge);
            globalOffsetRounded = Math.round(options.offsetGlobal);
            globalOffset = (options.offsetGlobal - globalOffsetRounded) * 1000 / 30;

            if (options.judgeWindow)
                judgeSettings = options.judgeWindow;
            else
                judgeSettings = Constant.JUDGE_WINDOW;
            judgeOffset = options.offsetJudge * 1000 / 30;
            autoJudgeOffset = options.autoJudgeOffset;

            mpSpectate = (options.mpRoom && !options.mpRoom.connection.currentUser.isPlayer);
            if (mpSpectate)
            {
                options.displayCombo = options.displayComboTotal = options.displayPA = false;
            }
            else if (options.mpRoom)
                options.displayComboTotal = false;
        }

        private function initVars(postStart:Boolean = true):void
        {
            // Post Start Time
            if (postStart && !_gvars.activeUser.isGuest && !options.replay && !options.isEditor && song.songInfo.engine == null && !mpSpectate)
            {
                Logger.debug(this, "Posting Start of level " + song.id);
                _loader = new URLLoader();
                addLoaderListeners();

                var req:URLRequest = new URLRequest(Constant.SONG_START_URL);
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

            // Game Vars
            _keys = [];
            gameLife = 50;
            gameScore = 0;
            gameRawGoods = 0;
            gameReplay = [];
            gameReplayHit = [];

            binReplayNotes = [];
            binReplayBoos = [];

            replayPressCount = 0;

            hitAmazing = 0;
            hitPerfect = 0;
            hitGood = 0;
            hitAverage = 0;
            hitMiss = 0;
            hitBoo = 0;
            hitCombo = 0;
            hitMaxCombo = 0;

            updateHealth(0);
            if (song != null && song.totalNotes > 0)
            {
                gameLastNoteFrame = song.getNote(song.totalNotes - 1).frame;
                gameFirstNoteFrame = song.getNote(0).frame;
            }
            if (comboTotal)
                comboTotal.update(song.totalNotes);

            msStartTime = getTimer();
            absoluteStart = getTimer();
            gamePosition = 0;
            gameProgress = 0;
            absolutePosition = 0;
            if (song != null)
            {
                songOffset = new RollingAverage(song.frameRate * 4, _avars.configMusicOffset);
                frameRate = new RollingAverage(song.frameRate * 4, song.frameRate);
            }
            accuracy = new Average();

            songDelayStarted = false;

            if (postStart)
            {
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
                    SOCKET_SCORE_MESSAGE["last_hit"] = null;
                    SOCKET_SCORE_MESSAGE["restarts"] = _gvars.songRestarts;
                    _gvars.websocketSend("NOTE_JUDGE", SOCKET_SCORE_MESSAGE);
                    _gvars.websocketSend("SONG_START", SOCKET_SONG_MESSAGE);
                }
            }
        }

        private function siteLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            var data:URLVariables = e.target.data;
            Logger.debug(this, "Post Start Load Success = " + data.result);
            if (data.result == "success")
            {
                _gvars.songStartTime = data.current_date;
                _gvars.songStartHash = data.current_time;
            }
        }

        private function siteLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Post Start Load Failure: " + Logger.event_error(err));
            removeLoaderListeners();
            //Alert.add("Error sending game start, score may not save", 60, Alert.RED);
        }

        /*#########################################################################################*\
         *        __                 _
         *       /__\_   _____ _ __ | |_ ___
         *      /_\ \ \ / / _ \ '_ \| __/ __|
         *     //__  \ V /  __/ | | | |_\__ \
         *     \__/   \_/ \___|_| |_|\__|___/
         *
           \*#########################################################################################*/

        private function stopClips(clip:MovieClip, frame:int):void
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

        private function logicTick():void
        {
            gameProgress++;

            // Anti-GPU Rampdown Hack:
            // By doing a sparse but steady amount of screen updates using a single pixel in the
            // top left, the GPU is kept active on laptops. This fixes the issue when a skip can
            // appear to happen when the GPU re-awakes to begin drawing updates after a break in
            // a song.
            if (gameProgress % 15 == 0)
            {
                if ((gameProgress & 1) == 0)
                    GPU_PIXEL_BMD.setPixel(0, 0, 0x010101);
                else
                    GPU_PIXEL_BMD.setPixel(0, 0, 0x020202);
            }

            if (levelScript != null)
                levelScript.doProgressTick(gameProgress);

            if (quitDoubleTap > 0)
            {
                quitDoubleTap--;
            }

            if (gameProgress >= gameLastNoteFrame + 20 || quitDoubleTap == 0)
            {
                GAME_STATE = GAME_END;
                return;
            }

            var nextNote:Note = noteBox.nextNote;
            while (nextNote && nextNote.frame <= gameProgress + player1JudgeOffset + 5)
            {
                noteBox.spawnArrow(nextNote, (gameProgress + player1JudgeOffset + 5) / 30 * 1000);
                nextNote = noteBox.nextNote;
            }

            var notes:Array = noteBox.notes;
            for (var n:int = 0; n < notes.length; n++)
            {
                var curNote:GameNote = notes[n];

                // Game Bot
                if (options.isAutoplay && (gameProgress - curNote.PROGRESS + player1JudgeOffset) == 0)
                {
                    judgeScore(curNote.DIR, gameProgress);
                    n--;
                }

                // Remove Old note
                if (gameProgress - curNote.PROGRESS + player1JudgeOffset >= 6)
                {
                    binReplayNotes[curNote.ID] = {"d": curNote.DIR, "t": null};
                    commitJudge(curNote.DIR, gameProgress, -10);
                    noteBox.removeNote(curNote.ID);
                    n--;
                }
            }

            // Replays
            if (options.replay && !options.replay.isPreview)
            {
                var newPress:ReplayNote = options.replay.getPress(replayPressCount);
                if (options.replay.needsBeatboxGeneration)
                {
                    var oldPosition:int = gamePosition;
                    gamePosition = (gameProgress + 0.5) * 1000 / 30;
                    var cutOffReplayNote:uint = options.replay.generationReplayNotes.length;
                    var readAheadTime:Number = (1 / frameRate.value) * 1000;
                    // Note Hits
                    for (var rn:int = 0; rn < notes.length; rn++)
                    {
                        var repCurNote:GameNote = notes[rn];

                        // Missed Note
                        if (repCurNote.ID >= cutOffReplayNote || options.replay.generationReplayNotes[repCurNote.ID] == null)
                        {
                            continue;
                        }

                        var diffValue:int = options.replay.generationReplayNotes[repCurNote.ID] + repCurNote.POSITION;
                        if ((gamePosition + readAheadTime >= diffValue) || gamePosition >= diffValue)
                        {
                            judgeScorePosition(repCurNote.DIR, diffValue);
                            rn--;
                        }
                    }

                    // Boo Handling
                    while (newPress != null && gamePosition >= newPress.time)
                    {
                        if (newPress.frame == -2)
                            commitJudge(newPress.direction, gameProgress, -5);
                        replayPressCount++;
                        newPress = options.replay.getPress(replayPressCount);
                    }
                    gamePosition = oldPosition;
                }
                else
                {
                    while (newPress != null && newPress.frame == gameProgress)
                    {
                        judgeScore(newPress.direction, newPress.frame);

                        replayPressCount++;
                        newPress = options.replay.getPress(replayPressCount);
                    }
                }
            }
        }

        private var mpLowIndex:int = 0;
        private var mpLowProgress:int = 0;
        private var mpLowProgressTime:int = 0;
        private var mpHighIndex:int = 0;
        private var mpHighProgress:int = 0;
        private var mpHighProgressTime:int = 0;

        private function spectateSync():void
        {
            var lowIndex:int = 0;
            var highIndex:int = 0;
            for each (var user:User in options.mpRoom.players)
            {
                var gameplay:Gameplay = user.gameplay;
                var index:int = gameplay.amazing + gameplay.perfect + gameplay.good + gameplay.average + gameplay.miss;
                if (!lowIndex || (index && index < lowIndex))
                    lowIndex = index;
                if (!highIndex || (index && index > highIndex))
                    highIndex = index;
            }

            if (!song.getNote(lowIndex) || !song.getNote(highIndex))
                return;

            var lowProgress:int = song.getNote(lowIndex).frame;
            var highProgress:int = song.getNote(highIndex).frame;

            var currentTime:int = getTimer();
            if (lowIndex > mpLowProgress)
            {
                mpLowIndex = lowIndex;
                mpLowProgress = lowProgress;
                mpLowProgressTime = currentTime;
            }
            if (highIndex > mpHighProgress)
            {
                mpHighIndex = highIndex;
                mpHighProgress = highProgress;
                mpHighProgressTime = currentTime;
            }

            lowIndex = mpLowProgressTime ? (mpLowProgress + (currentTime - mpLowProgressTime) * 30 / 1000) : 0;
            highIndex = mpHighProgressTime ? (mpHighProgress + (currentTime - mpHighProgressTime) * 30 / 1000) : 0;

            if (gameProgress < lowIndex - 30)
            {
                if (highIndex - lowIndex < 60)
                    lowIndex = lowIndex + (highIndex - lowIndex) / 2;
                else
                    lowIndex += 15;
                absoluteStart = currentTime;
                songOffset.reset(lowIndex * 1000 / 30);
                song.start(lowIndex * 1000 / 30);
                noteBox.resetNoteCount(mpLowIndex);
                while (gameProgress < lowIndex)
                    logicTick();
            }
            else if (gameProgress > highIndex + 30 || (!lowIndex && !highIndex))
            {
                if (highIndex - lowIndex < 60)
                    highIndex = lowIndex + (highIndex - lowIndex) / 2;
                else if (highIndex > 15)
                    highIndex -= 15;
                absoluteStart = currentTime;
                songOffset.reset(highIndex * 1000 / 30);
                song.start(highIndex * 1000 / 30);
                noteBox.resetNoteCount(mpHighIndex);
            }
        }

        private function onEnterFrame(e:Event):void
        {
            // XXX: HACK HACK HACK
            if (legacyMode)
            {
                var songFrame:int = song_background.currentFrame;
                if (songFrame == gameSongFrames - 1)
                    song.stop();
            }

            switch (GAME_STATE)
            {
                case GAME_PLAY:
                    if (legacyMode)
                    {
                        logicTick();
                        gamePosition = (gameProgress + 0.5) * 1000 / 30;

                        if (mpSpectate)
                            spectateSync();
                    }
                    else
                    {
                        var lastAbsolutePosition:int = absolutePosition;
                        absolutePosition = getTimer() - absoluteStart;

                        if (!songDelayStarted)
                        {
                            if (absolutePosition < songDelay)
                            {
                                song.stop();
                            }
                            else
                            {
                                songDelayStarted = true;
                                song.start();
                            }
                        }

                        var songPosition:int = song.getPosition() + songDelay;
                        if (song.musicIsPlaying && songPosition > 100)
                            songOffset.addValue(songPosition - absolutePosition);

                        frameRate.addValue(1000 / (absolutePosition - lastAbsolutePosition));

                        gamePosition = Math.round(absolutePosition + songOffset.value);
                        if (gamePosition < 0)
                            gamePosition = 0;

                        var targetProgress:int = Math.round(gamePosition * 30 / 1000 - 0.5);
                        var threshold:int = Math.round(1 / (frameRate.value / 60));
                        if (threshold < 1)
                            threshold = 1;
                        if (options.replay)
                            threshold = 0x7fffffff;

                        //Logger.debug("GP", "lAP: " + lastAbsolutePosition + " | aP: " + absolutePosition + " | sDS: " + songDelayStarted + " | sD: " + songDelay + " | sOv: " + songOffset.value + " | sGP: " + song.getPosition() + " | sP: " + songPosition + " | gP: " + gamePosition + " | tP: " + targetProgress + " | t: " + threshold);

                        while (gameProgress < targetProgress && threshold-- > 0)
                            logicTick();

                        if (mpSpectate)
                            spectateSync();

                        if (reverseMod)
                            stopClips(song_background, 2 + song.musicDelay - globalOffsetRounded + gameProgress * options.songRate);
                        else
                            stopClips(song_background, 2 + song.musicDelay - globalOffsetRounded + gameProgress * options.songRate);
                    }

                    if (options.modEnabled("tap_pulse"))
                    {
                        noteBoxOffset.x = Math.max(Math.min(Math.abs(noteBoxOffset.x) < 0.5 ? 0 : (noteBoxOffset.x * 0.992), noteBox.positionOffsetMax.max_x), noteBox.positionOffsetMax.min_x);
                        noteBoxOffset.y = Math.max(Math.min(Math.abs(noteBoxOffset.y) < 0.5 ? 0 : (noteBoxOffset.y * 0.992), noteBox.positionOffsetMax.max_y), noteBox.positionOffsetMax.min_y);

                        noteBox.x = noteBoxPositionDefault.x + noteBoxOffset.x;
                        noteBox.y = noteBoxPositionDefault.y + noteBoxOffset.y;
                    }

                    noteBox.update(gamePosition);

                    if (progressDisplay)
                        progressDisplay.update((gameProgress / gameLastNoteFrame) * 100, false);
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

        private function keyboardKeyUp(e:KeyboardEvent):void
        {
            var keyCode:int = e.keyCode;

            // Set Key as used.
            _keys[keyCode] = false;

            e.stopImmediatePropagation();
        }

        private function keyboardKeyDown(e:KeyboardEvent):void
        {
            var keyCode:int = e.keyCode;

            // Don't allow key presses unless the key is up.
            if (_keys[keyCode])
            {
                return;
            }

            // Set Key as used.
            _keys[keyCode] = true;

            // Handle judgement of key presses.
            if (gameLife > 0)
            {
                if (!options.replay)
                {
                    var dir:String = null;
                    switch (keyCode)
                    {
                        case _gvars.activeUser.keyLeft:
                            //case Keyboard.NUMPAD_4:
                            dir = "L";
                            break;

                        case _gvars.activeUser.keyRight:
                            //case Keyboard.NUMPAD_6:
                            dir = "R";
                            break;

                        case _gvars.activeUser.keyUp:
                            //case Keyboard.NUMPAD_8:
                            dir = "U";
                            break;

                        case _gvars.activeUser.keyDown:
                            //case Keyboard.NUMPAD_2:
                            dir = "D";
                            break;
                    }
                    if (dir)
                    {
                        if (legacyMode)
                            judgeScore(dir, gameProgress);
                        else
                            judgeScorePosition(dir, Math.round(getTimer() - absoluteStart + songOffset.value));
                    }
                }
            }

            // Game Restart
            if (keyCode == _gvars.playerUser.keyRestart && !options.mpRoom)
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
                        _gvars.songQueue = [];
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
            else if (keyCode == Keyboard.F8 && (CONFIG::debug || _gvars.playerUser.isDeveloper || _gvars.playerUser.isAdmin))
            {
                options.isAutoplay = !options.isAutoplay;
                Alert.add("Bot Play: " + options.isAutoplay, 60);
            }

            e.stopImmediatePropagation();
        }

        private function progressMouseClick(e:MouseEvent):void
        {
            var seek:int = (e.localX / e.target.width) * gameLastNoteFrame;
            if (seek < gameProgress)
                restartGame();
            absoluteStart = getTimer();
            songOffset.reset(seek * 1000 / 30);
            song.start(seek * 1000 / 30);
            while (gameProgress < seek)
                logicTick();
            songDelayStarted = true;
        }

        private function editorOnEnterFrame(e:Event):void
        {
            // State 0 = Gameplay
            if (GAME_STATE == GAME_PLAY)
            {
                gamePosition = getTimer() - absoluteStart;
                var targetProgress:int = Math.round(gamePosition * 30 / 1000);

                // Update Notes
                while (gameProgress < targetProgress)
                {
                    logicTick();
                }

                noteBox.update(gamePosition);
            }
            // State 1 = End Game
            else if (GAME_STATE == GAME_END)
            {
                endGame();
                return;
            }
        }

        private function editorKeyboardKeyDown(e:KeyboardEvent):void
        {
            if (noteBox == null)
                return;

            var keyCode:int = e.keyCode;
            var dir:String = "";

            if (keyCode == _gvars.playerUser.keyQuit)
            {
                GAME_STATE = GAME_END;
            }

            switch (keyCode)
            {
                case _gvars.playerUser.keyLeft:
                    //case Keyboard.NUMPAD_4:
                    dir = "L";
                    break;

                case _gvars.playerUser.keyRight:
                    //case Keyboard.NUMPAD_6:
                    dir = "R";
                    break;

                case _gvars.playerUser.keyUp:
                    //case Keyboard.NUMPAD_8:
                    dir = "U";
                    break;

                case _gvars.playerUser.keyDown:
                    //case Keyboard.NUMPAD_2:
                    dir = "D";
                    break;
            }

            if (dir != "")
            {
                noteBox.spawnArrow(new Note(dir, (gameProgress + 31) / 30, "red", gameProgress + 31), (gameProgress + player1JudgeOffset + 5) / 30 * 1000);
            }
        }

        /*#########################################################################################*\
         *	   ___                         ___                 _   _
         *	  / _ \__ _ _ __ ___   ___    / __\   _ _ __   ___| |_(_) ___  _ __  ___
         *	 / /_\/ _` | '_ ` _ \ / _ \  / _\| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         *	/ /_\\ (_| | | | | | |  __/ / /  | |_| | | | | (__| |_| | (_) | | | \__ \
         *	\____/\__,_|_| |_| |_|\___| \/    \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
         *
           \*#########################################################################################*/

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

        private function endGame():void
        {
            if (levelScript)
                levelScript.destroy();

            // Stop Music Play
            if (song)
                song.stop();

            // Play through to the end of a replay
            if (options.replay)
            {
                GAME_STATE = GAME_PLAY;
                while (gameLife > 0 && GAME_STATE == GAME_PLAY)
                    logicTick();
                GAME_STATE = GAME_END;
            }

            // Fill missing notes from replay.
            if (gameReplayHit.length > 0)
            { // fix crash when spectating game ends
                while (gameReplayHit.length < song.totalNotes)
                {
                    gameReplayHit.push(-5);
                }
            }
            gameReplayHit.push(-10);
            gameReplay.sort(ReplayNote.sortFunction)

            var noteCount:int = hitAmazing + hitPerfect + hitGood + hitAverage + hitMiss;

            // Save results for display
            if (!mpSpectate && !options.isEditor)
            {
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
                newGameResults.song_progress = (gameProgress / gameLastNoteFrame);
                newGameResults.playtime_secs = ((getTimer() - msStartTime) / 1000);

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

            _gvars.sessionStats.addFromStats(_gvars.songStats);
            _gvars.songStats.reset();

            if (!legacyMode && !options.replay && !options.isEditor && !mpSpectate)
            {
                _avars.configMusicOffset = (_avars.configMusicOffset * 0.85) + songOffset.value * 0.15;

                // Cap between 5 seconds for sanity.
                if (Math.abs(_avars.configMusicOffset) >= 5000)
                {
                    _avars.configMusicOffset = Math.max(-5000, Math.min(5000, _avars.configMusicOffset));
                }

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
            initVars(false);

            if (song != null)
                song.stop();

            song = null;

            if (song_background)
            {
                this.removeChild(song_background);
                song_background = null;
            }

            // Remove Notes
            if (noteBox != null)
            {
                noteBox.reset();
            }

            // Remove UI
            if (GPU_PIXEL_BITMAP)
            {
                this.removeChild(GPU_PIXEL_BITMAP);
                GPU_PIXEL_BITMAP = null;
                GPU_PIXEL_BMD = null;
            }
            if (displayBlackBG)
            {
                this.removeChild(displayBlackBG);
                displayBlackBG = null;
            }
            if (progressDisplay)
            {
                gameplayUI.removeChild(progressDisplay);
                progressDisplay = null;
            }
            if (player1Life)
            {
                this.removeChild(player1Life);
                player1Life = null;
            }
            if (player1Judge)
            {
                this.removeChild(player1Judge);
                player1Judge = null;
            }
            if (gameplayUI)
            {
                this.removeChild(gameplayUI);
                gameplayUI = null;
            }
            if (noteBox)
            {
                this.removeChild(noteBox);
                noteBox = null;
            }
            if (displayBlackBG)
            {
                this.removeChild(displayBlackBG);
                displayBlackBG = null;
            }
            if (flashLight)
            {
                this.removeChild(flashLight);
                flashLight = null;
            }
            if (screenCut)
            {
                this.removeChild(screenCut);
                screenCut = null;
            }
            if (exitEditor)
            {
                exitEditor.dispose();
                this.removeChild(exitEditor);
                exitEditor = null;
            }

            GAME_STATE = GAME_DISPOSE;

            var screen:int = _gvars.activeUser.startUpScreen;
            if (!_gvars.activeUser.isGuest && (screen == 0 || screen == 1) && !MultiplayerSingleton.getInstance().connection.connected)
            {
                MultiplayerSingleton.getInstance().connection.connect();
            }

            // Go to results
            switchTo((options.isEditor || mpSpectate) ? Main.GAME_MENU_PANEL : GameMenu.GAME_RESULTS);
        }

        private function restartGame():void
        {
            // Remove Notes
            noteBox.reset();

            if (paWindow)
                paWindow.reset();

            noteBoxOffset = {"x": 0, "y": 0};

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
            song.reset();
            GAME_STATE = GAME_PLAY;
            initPlayerVars();
            initVars();
            if (player1Judge)
                player1Judge.hideJudge();
            _gvars.songRestarts++;

            // Websocket
            if (_gvars.air_useWebsockets)
            {
                SOCKET_SCORE_MESSAGE["restarts"] = _gvars.songRestarts;
                _gvars.websocketSend("NOTE_JUDGE", SOCKET_SCORE_MESSAGE);
                _gvars.websocketSend("SONG_RESTART", SOCKET_SONG_MESSAGE);
            }
        }

        /*#########################################################################################*\
         *			_____     ___               _   _
         *	 /\ /\  \_   \   / __\ __ ___  __ _| |_(_) ___  _ __
         *	/ / \ \  / /\/  / / | '__/ _ \/ _` | __| |/ _ \| '_ \
         *	\ \_/ /\/ /_   / /__| | |  __/ (_| | |_| | (_) | | | |
         *	 \___/\____/   \____/_|  \___|\__,_|\__|_|\___/|_| |_|
         *
           \*#########################################################################################*/
        private function buildFlashlight():void
        {
            if (options.modEnabled("flashlight"))
            {
                if (flashLight == null)
                {
                    var _matrix:Matrix = new Matrix();
                    _matrix.createGradientBox(Main.GAME_WIDTH, Main.GAME_HEIGHT, 1.5707963267948966);
                    flashLight = new Sprite();
                    flashLight.graphics.clear();
                    flashLight.graphics.beginGradientFill(GradientType.LINEAR, [0, 0, 0, 0, 0, 0], [0.95, 0.55, 0, 0, 0.55, 0.95], [0x00, 0x52, 0x6C, 0x92, 0xAC, 0xFF], _matrix);
                    flashLight.graphics.drawRect(0, -Main.GAME_HEIGHT, Main.GAME_WIDTH, Main.GAME_HEIGHT * 3);
                    flashLight.graphics.endFill();
                }
                if (!contains(flashLight))
                    addChild(flashLight);
            }
            else if (flashLight != null && this.contains(flashLight))
            {
                removeChild(flashLight);
            }
        }

        private function buildScreenCut():void
        {
            if (!options.displayScreencut && !options.isEditor)
                return;

            if (screenCut)
            {
                if (this.contains(screenCut))
                    this.removeChild(screenCut);
                screenCut = null;
            }
            screenCut = new Sprite();
            screenCut.graphics.lineStyle(3, 0x39C4E1, 1);
            screenCut.graphics.beginFill(0x000000);

            switch (options.scrollDirection)
            {
                case "down":
                    screenCut.x = 0;
                    screenCut.y = options.screencutPosition * Main.GAME_HEIGHT;
                    screenCut.graphics.drawRect(-Main.GAME_WIDTH, -(Main.GAME_HEIGHT * 3), Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        screenCut.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            screenCut.startDrag(false, new Rectangle(0, 5, 0, Main.GAME_HEIGHT - 7));
                        });
                        screenCut.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            screenCut.stopDrag();
                            options.screencutPosition = (screenCut.y / Main.GAME_HEIGHT);
                        });
                    }
                    break;
                case "right":
                    screenCut.x = options.screencutPosition * Main.GAME_WIDTH;
                    screenCut.y = 0;
                    screenCut.graphics.drawRect(-Main.GAME_WIDTH * 3, -Main.GAME_HEIGHT, Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        screenCut.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            screenCut.startDrag(false, new Rectangle(0, 0, Main.GAME_WIDTH - 7, 0));
                        });
                        screenCut.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            screenCut.stopDrag();
                            options.screencutPosition = (screenCut.x / Main.GAME_WIDTH);
                        });
                    }
                    break;
                case "left":
                    screenCut.x = Main.GAME_WIDTH - (options.screencutPosition * Main.GAME_WIDTH);
                    screenCut.y = 0;
                    screenCut.graphics.drawRect(0, -Main.GAME_HEIGHT, Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        screenCut.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            screenCut.startDrag(false, new Rectangle(0, 0, Main.GAME_WIDTH - 7, 0));
                        });
                        screenCut.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            screenCut.stopDrag();
                            options.screencutPosition = 1 - (screenCut.x / Main.GAME_WIDTH);
                        });
                    }
                    break;
                default:
                    screenCut.x = 0;
                    screenCut.y = Main.GAME_HEIGHT - (options.screencutPosition * Main.GAME_HEIGHT);
                    screenCut.graphics.drawRect(-Main.GAME_WIDTH, 0, Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        screenCut.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            screenCut.startDrag(false, new Rectangle(0, 5, 0, Main.GAME_HEIGHT - 7));
                        });
                        screenCut.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            screenCut.stopDrag();
                            options.screencutPosition = 1 - (screenCut.y / Main.GAME_HEIGHT);
                        });
                    }
                    break;
            }
            screenCut.graphics.endFill();
            if (options.isEditor)
            {
                screenCut.buttonMode = true;
                screenCut.useHandCursor = true;
            }
            this.addChild(screenCut);
        }

        private function buildJudge():void
        {
            if (!options.displayJudge)
                return;
            player1Judge = new Judge(options);
            addChild(player1Judge);
            if (options.isEditor)
                player1Judge.showJudge(100, true);
        }

        private function buildHealth():void
        {
            if (!options.displayHealth)
                return;
            player1Life = new LifeBar();
            player1Life.x = Main.GAME_WIDTH - 37;
            player1Life.y = 71.5;
            addChild(player1Life);
        }

        private function buildMultiplayer():void
        {
            mpJudge = new Array();
            mpPA = new Array();
            mpCombo = new Array();
            mpHeader = new Array();

            if (!options.displayMP && !mpSpectate)
                return;

            for each (var user:User in options.mpRoom.players)
            {
                if (user.id == options.mpRoom.connection.currentUser.id)
                    continue;

                if (options.displayMPPA)
                {
                    var pa:PAWindow = new PAWindow(options);
                    addChild(pa);
                    mpPA[user.playerIdx] = pa;
                }

                if (mpSpectate)
                {
                    var header:MPHeader = new MPHeader(user);
                    if (options.displayMPPA)
                        mpPA[user.playerIdx].addChild(header);
                    else
                        addChild(header);
                    mpHeader[user.playerIdx] = header;
                }

                if (options.displayMPCombo)
                {
                    var combo:Combo = new Combo(options);
                    addChild(combo);
                    mpCombo[user.playerIdx] = combo;
                }

                // Hide opponent's judge
                if (mpSpectate)
                {
                    //if (options.displayMPJudge) {
                    var judge:Judge = new Judge(options);
                    addChild(judge);
                    mpJudge[user.playerIdx] = judge;
                    if (options.isEditor)
                        judge.showJudge(100, true);
                }
            }
        }

        private function interfaceLayout(key:String, defaults:Boolean = true):Object
        {
            if (defaults)
            {
                var ret:Object = new Object();
                var def:Object = defaultLayout[key];
                for (var i:String in def)
                    ret[i] = def[i];
                var layout:Object = options.layout[key];
                for (i in layout)
                    ret[i] = layout[i];
                return ret;
            }
            else if (!options.layout[key])
                options.layout[key] = new Object();
            return options.layout[key];
        }

        private function interfaceSetup():void
        {
            defaultLayout = new Object();
            defaultLayout[LAYOUT_JUDGE] = {x: 392, y: 228};
            defaultLayout[LAYOUT_HEALTH] = {x: Main.GAME_WIDTH - 37, y: 71.5};
            defaultLayout[LAYOUT_RECEPTORS] = {x: 230, y: 0};
            if (sideScroll)
            {
                defaultLayout[LAYOUT_PA] = {x: 16, y: 418};
                defaultLayout[LAYOUT_SCORE] = {x: 392, y: 24};
                defaultLayout[LAYOUT_COMBO] = {x: 508, y: 388};
                defaultLayout[LAYOUT_COMBO_TOTAL] = {x: 770, y: 420, properties: {alignment: Combo.ALIGN_RIGHT}};
                defaultLayout[LAYOUT_COMBO_STATIC] = {x: 512, y: 438};
                defaultLayout[LAYOUT_COMBO_TOTAL_STATIC] = {x: 734, y: 414};
            }
            else
            {
                defaultLayout[LAYOUT_PA] = {x: 6, y: 96};
                defaultLayout[LAYOUT_SCORE] = {x: 392, y: 440};
                defaultLayout[LAYOUT_COMBO] = {x: 222, y: 402, properties: {alignment: Combo.ALIGN_RIGHT}};
                defaultLayout[LAYOUT_COMBO_TOTAL] = {x: 544, y: 402};
                defaultLayout[LAYOUT_COMBO_STATIC] = {x: 228, y: 436};
                defaultLayout[LAYOUT_COMBO_TOTAL_STATIC] = {x: 502, y: 436};
            }

            if (mpSpectate)
            {
                defaultLayout[LAYOUT_MP_COMBO + "1"] = defaultLayout[LAYOUT_COMBO];
                defaultLayout[LAYOUT_MP_JUDGE + "1"] = {x: 208, y: 102};
                defaultLayout[LAYOUT_MP_PA + "1"] = {x: 6, y: 190};
                if (options.displayMPPA)
                    defaultLayout[LAYOUT_MP_HEADER + "1"] = {x: 0, y: -35};
                else
                    defaultLayout[LAYOUT_MP_HEADER + "1"] = {x: 6, y: 190};
            }

            defaultLayout[LAYOUT_MP_COMBO + (mpSpectate ? "2" : "1")] = defaultLayout[LAYOUT_COMBO_TOTAL];
            defaultLayout[LAYOUT_MP_JUDGE + (mpSpectate ? "2" : "1")] = {x: 568, y: 102};
            defaultLayout[LAYOUT_MP_PA + (mpSpectate ? "2" : "1")] = {x: 645, y: (mpSpectate ? 190 : 96)};
            if (options.displayMPPA)
                defaultLayout[LAYOUT_MP_HEADER + (mpSpectate ? "2" : "1")] = {x: 25, y: -35, properties: {alignment: MPHeader.ALIGN_RIGHT}};
            else
                defaultLayout[LAYOUT_MP_HEADER + (mpSpectate ? "2" : "1")] = {x: 690, y: 190, properties: {alignment: MPHeader.ALIGN_RIGHT}};

            noteBoxPositionDefault = interfaceLayout(LAYOUT_RECEPTORS);

            interfacePosition(noteBox, interfaceLayout(LAYOUT_RECEPTORS));
            interfacePosition(player1Judge, interfaceLayout(LAYOUT_JUDGE));
            interfacePosition(player1Life, interfaceLayout(LAYOUT_HEALTH));
            interfacePosition(score, interfaceLayout(LAYOUT_SCORE));
            interfacePosition(combo, interfaceLayout(LAYOUT_COMBO));
            interfacePosition(comboTotal, interfaceLayout(LAYOUT_COMBO_TOTAL));
            interfacePosition(paWindow, interfaceLayout(LAYOUT_PA));
            interfacePosition(comboStatic, interfaceLayout(LAYOUT_COMBO_STATIC));
            interfacePosition(comboTotalStatic, interfaceLayout(LAYOUT_COMBO_TOTAL_STATIC));

            if (options.isEditor)
            {
                interfaceEditor(noteBox, interfaceLayout(LAYOUT_RECEPTORS, false));
                interfaceEditor(player1Judge, interfaceLayout(LAYOUT_JUDGE, false));
                interfaceEditor(player1Life, interfaceLayout(LAYOUT_HEALTH, false));
                interfaceEditor(score, interfaceLayout(LAYOUT_SCORE, false));
                interfaceEditor(combo, interfaceLayout(LAYOUT_COMBO, false));
                interfaceEditor(comboTotal, interfaceLayout(LAYOUT_COMBO_TOTAL, false));
                interfaceEditor(paWindow, interfaceLayout(LAYOUT_PA, false));
                interfaceEditor(comboStatic, interfaceLayout(LAYOUT_COMBO_STATIC, false));
                interfaceEditor(comboTotalStatic, interfaceLayout(LAYOUT_COMBO_TOTAL_STATIC, false));
            }

            if (options.mpRoom)
            {
                var index:int = 0;
                for (var id:int = 1; id < options.mpRoom.playerCount + 1; id++)
                {
                    if (id == options.mpRoom.connection.currentUser.id)
                        continue;

                    index++;
                    var indexs:String = index.toString();
                    
                    interfacePosition(mpJudge[index], interfaceLayout(LAYOUT_MP_JUDGE + indexs));
                    interfacePosition(mpCombo[index], interfaceLayout(LAYOUT_MP_COMBO + indexs));
                    interfacePosition(mpPA[index], interfaceLayout(LAYOUT_MP_PA + indexs));
                    interfacePosition(mpHeader[index], interfaceLayout(LAYOUT_MP_HEADER + indexs));
                    

                    if (options.isEditor)
                    {
                        interfaceEditor(mpJudge[index], interfaceLayout(LAYOUT_MP_JUDGE + indexs, false));
                        interfaceEditor(mpCombo[index], interfaceLayout(LAYOUT_MP_COMBO + indexs, false));
                        interfaceEditor(mpPA[index], interfaceLayout(LAYOUT_MP_PA + indexs, false));
                        interfaceEditor(mpHeader[index], interfaceLayout(LAYOUT_MP_HEADER + indexs, false));
                    }
                }
            }
        }

        private function interfacePosition(sprite:Sprite, layout:Object):void
        {
            if (!sprite)
                return;

            if ("x" in layout)
                sprite.x = layout["x"];
            if ("y" in layout)
                sprite.y = layout["y"];
            if ("rotation" in layout)
                sprite.rotation = layout["rotation"];
            if ("visible" in layout)
                sprite.visible = layout["visible"];
            for (var p:String in layout.properties)
                sprite[p] = layout.properties[p];
        }

        private function interfaceEditor(sprite:Sprite, layout:Object):void
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

        /**
         * Judge a note score based on the current song position in ms.
         * @param dir Note Direction
         * @param position Time in MS.
         * @return
         */
        private function judgeScorePosition(dir:String, position:int):Boolean
        {
            if (position < 0)
                position = 0;
            var positionJudged:int = position + judgeOffset;

            var score:int = 0;
            var frame:int = 0;
            var booConflict:Boolean = false;
            for each (var note:GameNote in noteBox.notes)
            {
                if (note.DIR != dir)
                    continue;

                var diff:Number = positionJudged - note.POSITION;
                var lastJudge:Object = null;
                for each (var j:Object in judgeSettings)
                {
                    if (diff > j.t)
                        lastJudge = j;
                }
                score = lastJudge ? lastJudge.s : 0;
                if (score)
                    frame = lastJudge.f;
                if (!_avars.configJudge && !score)
                {
                    var pdiff:int = gameProgress - note.PROGRESS + player1JudgeOffset;
                    if (pdiff >= -3 && pdiff <= 3)
                        booConflict = true;
                }
                if (score > 0)
                    break;
                else if (diff <= judgeSettings[0].t)
                    break;
            }
            if (score)
            {
                commitJudge(dir, frame + note.PROGRESS - player1JudgeOffset, score);
                noteBox.removeNote(note.ID);
                accuracy.addValue(note.POSITION - position);
                binReplayNotes[note.ID] = {"d": dir, "t": (positionJudged - note.POSITION)};
            }
            else
            {
                var booFrame:int = gameProgress;
                if (booConflict)
                {
                    var noteIndex:int = 0;
                    note = noteBox.notes[noteIndex++] || noteBox.spawnNextNote();
                    while (note)
                    {
                        if (booFrame + player1JudgeOffset < note.PROGRESS - 3)
                            break;
                        if (note.DIR == dir)
                            booFrame = note.PROGRESS + 4 - player1JudgeOffset;

                        note = noteBox.notes[noteIndex++] || noteBox.spawnNextNote();
                    }
                }
                if (booFrame >= gameFirstNoteFrame)
                    binReplayBoos.push({"d": dir, "t": position, "i": binReplayBoos.length});
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

            return Boolean(score);
        }

        private function judgeScore(dir:String, frame:int):Boolean
        {
            var score:int = 0;
            for each (var note:GameNote in noteBox.notes)
            {
                if (note.DIR != dir)
                    continue;

                var diff:int = frame + player1JudgeOffset - note.PROGRESS;
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
                noteBox.removeNote(note.ID);
                accuracy.addValue((note.PROGRESS - frame) * 1000 / 30);
            }
            else
                commitJudge(dir, frame, -5);

            return Boolean(score);
        }

        private function commitJudge(dir:String, frame:int, score:int):void
        {
            var health:int = 0;
            var jscore:int = score;
            noteBox.receptorFeedback(dir, score);
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

            if (player1Judge && !options.isEditor)
                player1Judge.showJudge(jscore);

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
                gameReplay.push(new ReplayNote(dir, frame, (getTimer() - msStartTime), score));

            updateFieldVars();

            if (options.mpRoom)
            {
                dispatchEvent(new GameUpdateEvent({gameScore: gameScore,
                        gameLife: gameLife,
                        hitMaxCombo: hitMaxCombo,
                        hitCombo: hitCombo,
                        hitAmazing: hitAmazing,
                        hitPerfect: hitPerfect,
                        hitGood: hitGood,
                        hitAverage: hitAverage,
                        hitMiss: hitMiss,
                        hitBoo: hitBoo}));
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
                SOCKET_SCORE_MESSAGE["last_hit"] = score;
                _gvars.websocketSend("NOTE_JUDGE", SOCKET_SCORE_MESSAGE);
            }
        }

        private function checkAutofail(autofail:Number, hit:Number):void
        {
            if (autofail > 0 && hit >= autofail)
                GAME_STATE = GAME_END;
        }

        /*#########################################################################################*\
         *		   _                 _                   _       _
         *	/\   /(_)___ _   _  __ _| |  /\ /\ _ __   __| | __ _| |_ ___  ___
         *	\ \ / / / __| | | |/ _` | | / / \ \ '_ \ / _` |/ _` | __/ _ \/ __|
         *	 \ V /| \__ \ |_| | (_| | | \ \_/ / |_) | (_| | (_| | ||  __/\__ \
         *	  \_/ |_|___/\__,_|\__,_|_|  \___/| .__/ \__,_|\__,_|\__\___||___/
         *									  |_|
           \*#########################################################################################*/

        private function updateHealth(val:int):void
        {
            gameLife += val;
            if (gameLife <= 0)
            {
                GAME_STATE = GAME_END;
            }
            else if (gameLife > 100)
            {
                gameLife = 100;
            }
            if (player1Life)
                player1Life.health = gameLife;
        }

        private function updateFieldVars():void
        {
            //gameplayUI.sDisplay_score.text = gameScore.toString();

            if (paWindow)
                paWindow.update(hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo);

            if (score)
                score.update(gameScore);

            if (combo)
                combo.update(hitCombo, hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo, gameRawGoods);
        }

        private var previousDiffs:Array = new Array();

        private function multiplayerDiff(id:int, data:Object):Object
        {
            var previousDiff:Object = previousDiffs[id];
            if (!previousDiff)
                previousDiff = (previousDiffs[id] = {amazing: 0, perfect: 0, good: 0, average: 0, miss: 0, boo: 0});

            var diff:Object = {amazing: data.amazing - previousDiff.amazing,
                    perfect: data.perfect - previousDiff.perfect,
                    good: data.good - previousDiff.good,
                    average: data.average - previousDiff.average,
                    miss: data.miss - previousDiff.miss,
                    boo: data.boo - previousDiff.boo};

            previousDiff.amazing = data.amazing;
            previousDiff.perfect = data.perfect;
            previousDiff.good = data.good;
            previousDiff.average = data.average;
            previousDiff.miss = data.miss;
            previousDiff.boo = data.boo;

            return diff;
        }

        private var multiplayerResults:Array = [];

        public function onMultiplayerUpdate(event:GameUpdateEvent):void
        {
            var user:User = event.user;
            var gameplay:Gameplay = user.gameplay;

            if (!gameplay || !options.mpRoom.isPlayer(user) || user.id == options.mpRoom.connection.currentUser.id)
                return;

            var diff:Object = multiplayerDiff(user.id, gameplay);

            var combo:Combo = mpCombo[user.playerIdx];
            if (combo)
                combo.update(gameplay.combo, gameplay.amazing, gameplay.perfect, gameplay.good, gameplay.average, gameplay.miss, gameplay.boo);

            var pa:PAWindow = mpPA[user.playerIdx];
            if (pa)
                pa.update(gameplay.amazing, gameplay.perfect, gameplay.good, gameplay.average, gameplay.miss, gameplay.boo);

            var judge:Judge = mpJudge[user.playerIdx];
            if (judge)
            {
                var value:int = 0;
                if (diff.miss > 0)
                    value = -10;
                else if (diff.boo > 0)
                    value = -5;
                else if (diff.average > 0)
                    value = 5;
                else if (diff.good > 0)
                    value = 25;
                else if (diff.amazing > 0)
                    value = 100;
                else if (diff.perfect > 0)
                    value = 50;
                if (value && judge)
                    judge.showJudge(value);
            }

            if (gameplay.status == Multiplayer.STATUS_RESULTS && !multiplayerResults[user.playerIdx])
            {
                multiplayerResults[user.playerIdx] = true;
                Alert.add(user.name + " finished playing the song", 240, Alert.RED);
            }
        }

        public function onMultiplayerResults(event:GameResultsEvent):void
        {
            if (event.room == options.mpRoom)
                GAME_STATE = GAME_END;
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, siteLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, siteLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, siteLoadError);
        }

        private function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, siteLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, siteLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, siteLoadError);
        }

        public function getScriptVariable(key:String):*
        {
            return this[key];
        }

        public function setScriptVariable(key:String, val:*):void
        {
            this[key] = val;
        }
    }
}
