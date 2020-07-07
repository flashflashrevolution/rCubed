package game
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerSingleton;
    import assets.gameplay.lifemeterDisplay;
    import assets.gameplay.viewLR;
    import assets.gameplay.viewUD;
    import classes.Alert;
    import classes.BoxButton;
    import classes.GameNote;
    import classes.Language;
    import classes.Noteskins;
    import classes.chart.LevelScriptRuntime;
    import classes.chart.Note;
    import classes.chart.NoteChart;
    import classes.chart.Song;
    import classes.replay.ReplayNote;
    import classes.replay.ReplayPack;
    import com.flashfla.components.ProgressBar;
    import com.flashfla.net.Multiplayer;
    import com.flashfla.utils.Average;
    import com.flashfla.utils.RollingAverage;
    import com.flashfla.utils.TimeUtil;
    import flash.display.GradientType;
    import flash.display.MovieClip;
    import flash.display.Sprite;
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
    import game.controls.MPHeader;
    import game.controls.NoteBox;
    import game.controls.PAWindow;
    import game.controls.Score;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import menu.MenuPanel;
    import sql.SQLSongDetails;

    public class GamePlay extends MenuPanel
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

        private var player1Life:lifemeterDisplay;
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
        private var inputDisabled:Boolean = false;

        private var options:GameOptions;
        private var mpSpectate:Boolean;

        private var gameLastNoteFrame:Number;
        private var gameFirstNoteFrame:Number;
        private var gameSongFrames:int;

        private var gameLife:int;
        private var gameScore:int;
        private var gameRawGoods:Number;
        private var gameReplay:Array; // Vector.<ReplayNote>;
        private var gameReplayHit:Array; // Vector.<int>;

        private var _binReplayNotes:Array;
        private var _binReplayBoos:Array;

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

        private var SOCKET_MESSAGE:Object = {};

        public function GamePlay(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            options = _gvars.options;
            song = options.song;

            // --- Per Song Options - Super hacky, but actually solid
            if (_gvars.sql_connect && !options.isEditor && !options.replay)
            {
                options.fill(); // Reset
                SQLQueries.getSongDetails(_gvars.sql_conn, {"engine": (song.entry.engine != null ? song.entry.engine : Constant.BRAND_NAME_SHORT_LOWER()), "song_id": song.entry.level}, function(results:Vector.<SQLSongDetails>):void
                {
                    //trace("Delay Gameplay init for:", song.entry.level);
                    if (results != null && results.length > 0)
                    {
                        var result:SQLSongDetails = results[0];

                        // Custom Offsets
                        if (result.set_custom_offsets)
                        {
                            options.offsetJudge = result.offset_judge;
                            options.offsetGlobal = result.offset_music;
                        }

                        // Invert Mirror Mod
                        if (result.set_mirror_invert)
                        {
                            if (options.modEnabled("mirror"))
                                delete options.modCache["mirror"];
                            else
                                options.modCache["mirror"] = true;
                        }
                    }

                    stageAdd(); // This is cancelled by returning false below.
                });

                initBackground();
                return false; // Cancel stageAdd, will be called when callback is complete.
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

            // var stage3D:Stage3D = stage.stage3Ds[0];
            // stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, initStage3D);
            // stage.stage3Ds[0].requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.ENHANCED);

            // Create Background
            initBackground();
            initPlayerVars();
            // Init Core
            initCore();

            if (options.isEditor)
            {
                options.isAutoplay = true;
                stage.frameRate = options.frameRate;
                stage.addEventListener(Event.ENTER_FRAME, editorOnEnterFrame, false, int.MAX_VALUE, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, editorKeyboardKeyDown, false, int.MAX_VALUE, true);
            }
            else
            {
                stage.frameRate = song.frameRate;
                stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, int.MAX_VALUE, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardKeyDown, false, int.MAX_VALUE, true);
                stage.addEventListener(KeyboardEvent.KEY_UP, keyboardKeyUp, false, int.MAX_VALUE, true);
            }

            // Prebuild Websocket Message, this is updated instead of creating a new object every message.
            SOCKET_MESSAGE = {"player": {
                        "settings": options.settingsEncode(),
                        "name": _gvars.activeUser.name,
                        "userid": _gvars.activeUser.id,
                        "avatar": Constant.USER_AVATAR_URL + "?uid=" + _gvars.activeUser.id,
                        "skill_rating": _gvars.activeUser.skillRating,
                        "skill_level": _gvars.activeUser.skillLevel,
                        "game_rank": _gvars.activeUser.gameRank,
                        "game_played": _gvars.activeUser.gamesPlayed,
                        "game_grand_total": _gvars.activeUser.grandTotal
                    },
                    "engine": (song.entry.engine == null ? null : {"id": song.entry.engine.id,
                            "name": song.entry.engine.name,
                            "config": song.entry.engine.config_url,
                            "domain": song.entry.engine.domain})
                    ,
                    "song": {
                        "name": song.entry.name,
                        "level": song.entry.level,
                        "difficulty": song.entry.difficulty,
                        "style": song.entry.style,
                        "time": song.entry.time,
                        "time_seconds": song.entry.timeSecs,
                        "note_count": song.entry.arrows,
                        "author": song.entry.author,
                        "author_url": song.entry.author_url,
                        "stepauthor": song.entry.stepauthor,
                        "credits": song.entry.credits,
                        "genre": song.entry.genre,
                        "nps_min": song.entry.min_nps,
                        "nps_max": song.entry.max_nps,
                        "release_date": song.entry.releasedate,
                        "song_rating": song.entry.song_rating
                    },
                    "score": {
                        "best_score": _gvars.activeUser.getLevelRank(song.entry),
                        "amazing": 0,
                        "perfect": 0,
                        "good": 0,
                        "average": 0,
                        "miss": 0,
                        "boo": 0,
                        "score": 0,
                        "combo": 0,
                        "maxcombo": 0,
                        "restarts": 0,
                        "last_hit": null
                    }};

            // Init Game
            initUI();
            initVars();

            // Preload next Song
            if (_gvars.songQueue.length > 0)
            {
                _gvars.getSongFile(_gvars.songQueue[0]);
            }

            // Setup MP Things
            if (options.multiplayer)
            {
                MultiplayerSingleton.getInstance().gameplayPlaying(this);
                if (!options.isEditor)
                {
                    options.singleplayer = false; // Back to multiplayer lobby
                    options.multiplayer.connection.addEventListener(Multiplayer.EVENT_GAME_UPDATE, onMultiplayerUpdate);
                    if (mpSpectate)
                        options.multiplayer.connection.addEventListener(Multiplayer.EVENT_GAME_RESULTS, onMultiplayerResults);
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

            if (song.entry && song.entry.name)
                stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE + " - " + song.entry.name;
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
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyboardKeyDown);
                stage.removeEventListener(KeyboardEvent.KEY_UP, keyboardKeyUp);

                if (options.multiplayer)
                {
                    options.multiplayer.connection.removeEventListener(Multiplayer.EVENT_GAME_UPDATE, onMultiplayerUpdate);
                    options.multiplayer.connection.removeEventListener(Multiplayer.EVENT_GAME_RESULTS, onMultiplayerResults);
                }
            }

            _gvars.gameMain.disablePopups = false;

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

            if (MultiplayerSingleton.getInstance().connection.connected && !MultiplayerSingleton.getInstance().isInRoom())
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
                progressDisplay = new ProgressBar(458, 20, 4, 0x545454, 0.1);
                progressDisplay.x = 161;
                progressDisplay.y = 9.35;
                gameplayUI.addChild(progressDisplay);

                if (options.replay)
                    progressDisplay.addEventListener(MouseEvent.CLICK, progressMouseClick);
            }

            if (!mpSpectate)
            {
                buildJudge();
                buildHealth();
            }

            if (options.multiplayer)
                buildMultiplayer();

            if (options.isEditor)
            {
                gameplayUI.mouseChildren = false;
                gameplayUI.mouseEnabled = false;

                exitEditor = new BoxButton(75, 30, _lang.string("menu_close"));
                exitEditor.x = (Main.GAME_WIDTH / 2) - (exitEditor.width / 2);
                exitEditor.y = (Main.GAME_HEIGHT / 2) - (exitEditor.height / 2);
                exitEditor.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
                {
                    GAME_STATE = GAME_END;
                    if (!options.replay)
                    {
                        _gvars.activeUser.saveLocal();
                        _gvars.activeUser.save();
                    }
                });
                this.addChild(exitEditor);
                resetEditor = new BoxButton(75, 30, _lang.string("menu_reset"));
                resetEditor.x = exitEditor.x;
                resetEditor.y = exitEditor.y + 35;
                resetEditor.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
                {
                    for (var key:String in options.layout)
                        delete options.layout[key];
                    _avars.interfaceSave();
                    interfaceSetup();
                });
                this.addChild(resetEditor);
            }
        }

        private function initPlayerVars():void
        {
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

            mpSpectate = (options.multiplayer && !options.multiplayer.user.isPlayer);
            if (mpSpectate)
            {
                options.displayCombo = options.displayComboTotal = options.displayPA = false;
                if (options.multiplayer.connection.mode != Multiplayer.GAME_R3)
                    options.displayAmazing = false;
            }
            else if (options.multiplayer)
                options.displayComboTotal = false;
        }

        private function initVars(postStart:Boolean = true):void
        {
            // Post Start Time
            if (postStart && !_gvars.activeUser.isGuest && !options.replay && !options.isEditor && song.entry.engine == null && !mpSpectate)
            {
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
            inputDisabled = false;
            _keys = [];
            gameLife = 50;
            gameScore = 0;
            gameRawGoods = 0;
            gameReplay = []; // new Vector.<ReplayNote>;
            gameReplayHit = []; // new Vector.<int>;

            _binReplayNotes = [];
            _binReplayBoos = [];

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
                    SOCKET_MESSAGE["score"]["amazing"] = hitAmazing;
                    SOCKET_MESSAGE["score"]["perfect"] = hitPerfect;
                    SOCKET_MESSAGE["score"]["good"] = hitGood;
                    SOCKET_MESSAGE["score"]["average"] = hitAverage;
                    SOCKET_MESSAGE["score"]["boo"] = hitBoo;
                    SOCKET_MESSAGE["score"]["miss"] = hitMiss;
                    SOCKET_MESSAGE["score"]["combo"] = hitCombo;
                    SOCKET_MESSAGE["score"]["maxcombo"] = hitMaxCombo;
                    SOCKET_MESSAGE["score"]["score"] = gameScore;
                    SOCKET_MESSAGE["score"]["last_hit"] = null;
                    SOCKET_MESSAGE["score"]["restarts"] = _gvars.songRestarts;
                    _gvars.websocketSend("SONG_START", SOCKET_MESSAGE);
                }
            }
        }

        private function siteLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            var data:URLVariables = e.target.data;
            if (data.result == "success")
            {
                _gvars.songStartTime = data.current_date;
                _gvars.songStartHash = data.current_time;
            }
        }

        private function siteLoadError(e:Event = null):void
        {
            removeLoaderListeners();
            //_gvars.gameMain.addAlert("Error sending game start, score may not save", 60, Alert.RED);
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
                    _binReplayNotes[curNote.ID] = null;
                    commitJudge(curNote.DIR, gameProgress, -10);
                    noteBox.removeNote(curNote.ID);
                    n--;
                }
            }

            // Replays
            if (options.replay)
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

                        var diffValue:int = repCurNote.POSITION - options.replay.generationReplayNotes[repCurNote.ID];
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
            for each (var user:Object in options.multiplayer.players)
            {
                var gameplay:Object = user.gameplay;
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

            // Guitar Mode Key Tracking
            if (_gvars.activeUser.guitarMode)
            {
                switch (keyCode)
                {
                    case _gvars.activeUser.keyLeft:
                        //case Keyboard.NUMPAD_4:
                        _keys["L"] = false;
                        noteBox.receptorHeld("L", false);
                        break;

                    case _gvars.activeUser.keyRight:
                        //case Keyboard.NUMPAD_6:
                        _keys["R"] = false;
                        noteBox.receptorHeld("R", false);
                        break;

                    case _gvars.activeUser.keyUp:
                        //case Keyboard.NUMPAD_8:
                        _keys["U"] = false;
                        noteBox.receptorHeld("U", false);
                        break;

                    case _gvars.activeUser.keyDown:
                        //case Keyboard.NUMPAD_2:
                        _keys["D"] = false;
                        noteBox.receptorHeld("D", false);
                        break;
                }
            }

            e.stopImmediatePropagation();
        }

        private function keyboardKeyDown(e:KeyboardEvent):void
        {
            var keyCode:int = e.keyCode;

            if (inputDisabled)
                return;

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
                    // Guitar Mode, Requires Struming
                    if (_gvars.activeUser.guitarMode)
                    {

                        // Strum Key Press
                        if (keyCode == _gvars.activeUser.keyStrum)
                        {
                            for (var k:int = 0; k < keyDirections.length; k++)
                            {
                                if (_keys[keyDirections[k]])
                                {
                                    if (legacyMode)
                                        judgeScore(keyDirections[k], gameProgress);
                                    else
                                        judgeScorePosition(keyDirections[k], Math.round(getTimer() - absoluteStart + songOffset.value));
                                }
                            }
                        }
                        // Other Keys Pressed
                        else
                        {
                            switch (keyCode)
                            {
                                case _gvars.activeUser.keyLeft:
                                    //case Keyboard.NUMPAD_4:
                                    _keys["L"] = true;
                                    noteBox.receptorHeld("L");
                                    break;

                                case _gvars.activeUser.keyRight:
                                    //case Keyboard.NUMPAD_6:
                                    _keys["R"] = true;
                                    noteBox.receptorHeld("R");
                                    break;

                                case _gvars.activeUser.keyUp:
                                    //case Keyboard.NUMPAD_8:
                                    _keys["U"] = true;
                                    noteBox.receptorHeld("U");
                                    break;

                                case _gvars.activeUser.keyDown:
                                    //case Keyboard.NUMPAD_2:
                                    _keys["D"] = true;
                                    noteBox.receptorHeld("D");
                                    break;
                            }
                        }
                    }
                    else
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
            }

            if (keyCode == _gvars.playerUser.keyRestart && !options.multiplayer)
            {
                GAME_STATE = GAME_RESTART;
            }
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
            else if (keyCode == 19 && (CONFIG::debug || _gvars.playerUser.isAdmin || _gvars.playerUser.isDeveloper || options.replay))
            { // Pause
                togglePause();
            }
            else if (keyCode == Keyboard.F8 && (CONFIG::debug || _gvars.playerUser.isDeveloper || _gvars.playerUser.isAdmin))
            {
                options.isAutoplay = !options.isAutoplay;
                _gvars.gameMain.addAlert("Bot Play: " + options.isAutoplay, 60);
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
                    _gvars.websocketSend("SONG_PAUSE", SOCKET_MESSAGE);
                }
            }
            else if (GAME_STATE == GAME_PAUSE)
            {
                GAME_STATE = GAME_PLAY;
                absoluteStart += (getTimer() - songPausePosition);
                song.resume();

                if (_gvars.air_useWebsockets)
                {
                    _gvars.websocketSend("SONG_RESUME", SOCKET_MESSAGE);
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
            gameReplay.sortOn("frame", Array.NUMERIC);

            var noteCount:int = hitAmazing + hitPerfect + hitGood + hitAverage + hitMiss;

            // Save results for display
            if (!mpSpectate && !options.isEditor)
            {
                var judgementsEncode:String = JSON.stringify({"amazing": hitAmazing, "perfect": hitPerfect, "good": hitGood, "average": hitAverage, "boo": hitBoo, "miss": hitMiss, "maxcombo": hitMaxCombo});
                _gvars.songResults.push({"game_index": _gvars.gameIndex++,
                        "level": song.id,
                        "songFile": song,
                        "song": song.entry,
                        "amazing": hitAmazing,
                        "perfect": hitPerfect,
                        "good": hitGood,
                        "average": hitAverage,
                        "boo": hitBoo,
                        "miss": hitMiss,
                        "combo": hitCombo,
                        "maxcombo": hitMaxCombo,
                        "score": gameScore,
                        "lastNote": noteCount < song.totalNotes ? noteCount : 0,
                        "accuracy": 30 * accuracy.value / 1000,
                        "accuracyDeviation": 30 * accuracy.deviation / 1000,
                        "options": this.options,
                        "restart_stats": _gvars.songStats.data,
                        "replay": gameReplay.concat(),
                        "replay_hit": gameReplayHit.concat(),
                        "replay_bin": ReplayPack.writeReplay(_gvars.activeUser, options, judgementsEncode, _binReplayNotes, _binReplayBoos),
                        "_binReplayNotes": _binReplayNotes,
                        "_binReplayBoos": _binReplayBoos,
                        "user": options.replay ? options.replay.user : _gvars.activeUser,
                        "restarts": options.replay ? 0 : _gvars.songRestarts,
                        "starttime": _gvars.songStartTime,
                        "starthash": _gvars.songStartHash,
                        "endtime": options.replay ? TimeUtil.getFormattedDate(new Date(options.replay.timestamp * 1000)) : TimeUtil.getCurrentDate(),
                        "songprogress": (gameProgress / gameLastNoteFrame),
                        "playtime_secs": ((getTimer() - msStartTime) / 1000)});
            }
            _gvars.sessionStats.addFromStats(_gvars.songStats);
            _gvars.songStats.reset();

            if (!legacyMode && !options.replay && !options.isEditor && !mpSpectate)
            {
                _avars.configMusicOffset = (_avars.configMusicOffset * 0.85) + songOffset.value * 0.15;
                _avars.musicOffsetSave();
            }

            // Websocket
            if (_gvars.air_useWebsockets)
            {
                SOCKET_MESSAGE["score"]["amazing"] = hitAmazing;
                SOCKET_MESSAGE["score"]["perfect"] = hitPerfect;
                SOCKET_MESSAGE["score"]["good"] = hitGood;
                SOCKET_MESSAGE["score"]["average"] = hitAverage;
                SOCKET_MESSAGE["score"]["boo"] = hitBoo;
                SOCKET_MESSAGE["score"]["miss"] = hitMiss;
                SOCKET_MESSAGE["score"]["combo"] = hitCombo;
                SOCKET_MESSAGE["score"]["maxcombo"] = hitMaxCombo;
                SOCKET_MESSAGE["score"]["score"] = gameScore;
                SOCKET_MESSAGE["score"]["last_hit"] = null;
                _gvars.websocketSend("SONG_END", SOCKET_MESSAGE);
            }

            // Cleanup
            initVars(false);

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
            if (screen == 0 || screen == 1)
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
                SOCKET_MESSAGE["score"]["restarts"] = _gvars.songRestarts;
                _gvars.websocketSend("SONG_RESTART", SOCKET_MESSAGE);
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
            player1Life = new lifemeterDisplay();
            player1Life.x = Main.GAME_WIDTH - 37;
            player1Life.y = 71.5;
            player1Life.gotoAndStop(gameLife);
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

            for each (var user:Object in options.multiplayer.players)
            {
                if (user.userID == options.multiplayer.connection.currentUser.userID)
                    continue;

                if (options.displayMPPA)
                {
                    var pa:PAWindow = new PAWindow(options);
                    addChild(pa);
                    mpPA[user.playerID] = pa;
                }

                if (mpSpectate)
                {
                    var header:MPHeader = new MPHeader(user);
                    if (options.displayMPPA)
                        mpPA[user.playerID].addChild(header);
                    else
                        addChild(header);
                    mpHeader[user.playerID] = header;
                }

                if (options.displayMPCombo)
                {
                    var combo:Combo = new Combo(options);
                    addChild(combo);
                    mpCombo[user.playerID] = combo;
                }

                // Hide opponent's judge
                if (mpSpectate)
                {
                    //if (options.displayMPJudge) {
                    var judge:Judge = new Judge(options);
                    addChild(judge);
                    mpJudge[user.playerID] = judge;
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

            if (options.multiplayer)
            {
                var index:int = 0;
                for (var id:int = 1; id < options.multiplayer.playerCount + 1; id++)
                {
                    if (id == options.multiplayer.user.playerID)
                        continue;

                    index++;
                    var indexs:String = index.toString();
                    interfacePosition(mpJudge[id], interfaceLayout(LAYOUT_MP_JUDGE + indexs));
                    interfacePosition(mpCombo[id], interfaceLayout(LAYOUT_MP_COMBO + indexs));
                    interfacePosition(mpPA[id], interfaceLayout(LAYOUT_MP_PA + indexs));
                    interfacePosition(mpHeader[id], interfaceLayout(LAYOUT_MP_HEADER + indexs));

                    if (options.isEditor)
                    {
                        interfaceEditor(mpJudge[id], interfaceLayout(LAYOUT_MP_JUDGE + indexs, false));
                        interfaceEditor(mpCombo[id], interfaceLayout(LAYOUT_MP_COMBO + indexs, false));
                        interfaceEditor(mpPA[id], interfaceLayout(LAYOUT_MP_PA + indexs, false));
                        interfaceEditor(mpHeader[id], interfaceLayout(LAYOUT_MP_HEADER + indexs, false));
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
                _binReplayNotes[note.ID] = (note.POSITION - positionJudged);
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
                    _binReplayBoos.push({"d": dir, "t": position, "i": _binReplayBoos.length});
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

            if (options.multiplayer)
            {
                dispatchEvent(new SFSEvent(Multiplayer.EVENT_GAME_UPDATE, {gameScore: gameScore,
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
                SOCKET_MESSAGE["score"]["amazing"] = hitAmazing;
                SOCKET_MESSAGE["score"]["perfect"] = hitPerfect;
                SOCKET_MESSAGE["score"]["good"] = hitGood;
                SOCKET_MESSAGE["score"]["average"] = hitAverage;
                SOCKET_MESSAGE["score"]["boo"] = hitBoo;
                SOCKET_MESSAGE["score"]["miss"] = hitMiss;
                SOCKET_MESSAGE["score"]["combo"] = hitCombo;
                SOCKET_MESSAGE["score"]["maxcombo"] = hitMaxCombo;
                SOCKET_MESSAGE["score"]["score"] = gameScore;
                SOCKET_MESSAGE["score"]["last_hit"] = score;
                _gvars.websocketSend("NOTE_JUDGE", SOCKET_MESSAGE);
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
                player1Life.gotoAndStop(gameLife);
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

        private var multiplayerResults:Array = new Array();

        public function onMultiplayerUpdate(event:SFSEvent):void
        {
            var user:Object = event.params.user;
            var data:Object = user.gameplay;

            if (options.multiplayer != event.params.room || !data || user.userID == options.multiplayer.connection.currentUser.userID)
                return;

            var diff:Object = multiplayerDiff(user.playerID, data);

            var combo:Combo = mpCombo[user.playerID];
            if (combo)
                combo.update(data.combo, data.amazing, data.perfect, data.good, data.average, data.miss, data.boo);

            var pa:PAWindow = mpPA[user.playerID];
            if (pa)
                pa.update(data.amazing, data.perfect, data.good, data.average, data.miss, data.boo);

            var judge:Judge = mpJudge[user.playerID];
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

            if (data.status == Multiplayer.STATUS_RESULTS && !multiplayerResults[user.userID])
            {
                multiplayerResults[user.userID] = true;
                _gvars.gameMain.addAlert(user.userName + " finished playing the song", 240, Alert.RED);
            }
        }

        public function onMultiplayerResults(event:SFSEvent):void
        {
            if (event.params.room == options.multiplayer)
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
