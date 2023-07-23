package game
{
    import arc.ArcGlobals;
    import assets.GameBackgroundColor;
    import assets.gameplay.viewLR;
    import assets.gameplay.viewUD;
    import classes.Alert;
    import classes.GameNote;
    import classes.Language;
    import classes.Noteskins;
    import classes.chart.Note;
    import classes.chart.Song;
    import classes.replay.ReplayBinFrame;
    import classes.replay.ReplayNote;
    import classes.ui.BoxButton;
    import classes.ui.ProgressBar;
    import classes.user.UserSongData;
    import classes.user.UserSongNotes;
    import com.flashfla.utils.Average;
    import com.flashfla.utils.RollingAverage;
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
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.ui.Keyboard;
    import flash.ui.Mouse;
    import flash.utils.getTimer;
    import game.controls.AccuracyBar;
    import game.controls.Combo;
    import game.controls.FlashlightOverlay;
    import game.controls.Judge;
    import game.controls.LifeBar;
    import game.controls.NoteBox;
    import game.controls.PAWindow;
    import game.controls.RawGoods;
    import game.controls.Score;
    import game.controls.ScreenCut;
    import game.controls.TextStatic;
    import menu.MenuPanel;
    import menu.MenuSongSelection;

    public class GameplayDisplay extends MenuPanel
    {
        public static const GAME_DISPOSE:int = -1;
        public static const GAME_PLAY:int = 0;
        public static const GAME_END:int = 1;
        public static const GAME_RESTART:int = 2;
        public static const GAME_PAUSE:int = 3;

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

        public static const LAYOUT_MP_JUDGE:String = "mpjudge";
        public static const LAYOUT_MP_COMBO:String = "mpcombo";
        public static const LAYOUT_MP_PA:String = "mppa";
        public static const LAYOUT_MP_HEADER:String = "mpheader";
        public static const LAYOUT_MP_RAWGOODS:String = "mprawgoods";

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _noteskins:Noteskins = Noteskins.instance;
        private var _lang:Language = Language.instance;
        private var _loader:URLLoader;
        private var _keys:Array;
        private var song:Song;
        private var song_background:MovieClip;

        private var reverseMod:Boolean;
        private var sideScroll:Boolean;
        private var defaultLayout:Object;

        private var displayBlackBG:Sprite;
        private var gameplayUI:*;
        private var progressDisplay:ProgressBar;
        private var progressDisplayText:TextStatic;
        private var noteBox:NoteBox;
        private var score:Score;
        private var comboTotal:Combo;
        private var rawGoodsTotal:RawGoods;
        private var comboStatic:TextStatic;
        private var rawGoodsStatic:TextStatic;
        private var comboTotalStatic:TextStatic;
        private var accBar:AccuracyBar;
        private var screenCut:ScreenCut;
        private var flashLight:FlashlightOverlay;
        private var exitEditor:BoxButton;
        private var resetEditor:BoxButton;

        private var player1PAWindow:PAWindow;
        private var player1Combo:Combo;
        private var player1Life:LifeBar;
        private var player1Judge:Judge;
        private var player1JudgeOffset:int;
        private var player1RawGoods:RawGoods;

        private var mpHeader:Array;
        private var mpCombo:Array;
        private var mpJudge:Array;
        private var mpPA:Array;
        private var mpRawGoods:Array;

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
        private var judgeSettings:Vector.<JudgeNode>;

        private var quitDoubleTap:int = -1;

        private var options:GameOptions;

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

        private var binReplayNotes:Vector.<ReplayBinFrame>;
        private var binReplayBoos:Vector.<ReplayBinFrame>;

        private var replayPressCount:Number = 0;

        private var keyDirections:Array = ["L", "D", "U", "R"];
        private var hitAmazing:int;
        private var hitPerfect:int;
        private var hitGood:int;
        private var hitAverage:int;
        private var hitMiss:int;
        private var hitBoo:int;
        private var hitCombo:int;
        private var hitRawGoods:int;
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
            song.handleDirty(options);

            if (!options.isEditor && song.chart.Notes.length == 0)
            {
                Alert.add(_lang.string("error_chart_has_no_notes"), 120, Alert.RED);

                var screen:int = _gvars.activeUser.startUpScreen;
                switchTo(Main.GAME_MENU_PANEL);
                return false;
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
                var infoRanks:Object = GlobalVariables.instance.activeUser.getLevelRank(song.songInfo);
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

            // Create Background
            initBackground();

            // Init Core
            initPlayerVars();
            initCore();

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
            initUI();
            initVars();

            // Preload next Song
            if (_gvars.songQueue.length > 0)
            {
                _gvars.getSongFile(_gvars.songQueue[0]);
            }

            stage.focus = this.stage;
            stage.frameRate = options.frameRate;

            interfaceSetup();

            _gvars.gameMain.disablePopups = true;

            if (!options.isEditor && !options.replay)
                Mouse.hide();

            if (song.songInfo && song.songInfo.name)
                stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE + " - " + song.songInfo.name;

            // Add onEnterFrame Listeners
            if (options.isEditor)
            {
                options.isAutoplay = true;
                stage.addEventListener(Event.ENTER_FRAME, editorOnEnterFrame, false, int.MAX_VALUE - 10, true);
                stage.addEventListener(KeyboardEvent.KEY_DOWN, editorKeyboardKeyDown, false, int.MAX_VALUE - 10, true);
            }
            else
            {
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
            song.updateMusicOffset();
            if (song.background && !options.modEnabled("nobackground"))
            {
                song_background = song.background as MovieClip;
                gameSongFrames = song_background.totalFrames;
                song_background.x = 115;
                song_background.y = 42.5;
                this.addChild(song_background);
            }

            songDelay = song.mp3Frame / options.songRate * 1000 / 30 - globalOffset;
        }

        private function initBackground():void
        {
            // Anti-GPU Rampdown Hack
            GPU_PIXEL_BMD = new BitmapData(1, 1, false, 0x010101);
            GPU_PIXEL_BITMAP = new Bitmap(GPU_PIXEL_BMD);
            this.addChild(GPU_PIXEL_BITMAP);

            stage.color = GameBackgroundColor.BG_STAGE;
        }

        private function initUI():void
        {
            noteBox = new NoteBox(song, options);
            noteBox.position();
            this.addChild(noteBox);

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

            if (!options.displayGameTopBar && !options.displayGameBottomBar)
                gameplayUI.visible = false;

            if (options.displayPA)
            {
                player1PAWindow = new PAWindow(options);
                if (sideScroll)
                    player1PAWindow.alternateLayout();
                this.addChild(player1PAWindow);
            }

            if (options.displayScore)
            {
                score = new Score(options);
                this.addChild(score);
            }

            if (options.displayCombo)
            {
                player1Combo = new Combo(options);
                if (!sideScroll)
                    player1Combo.alignment = "right";
                this.addChild(player1Combo);

                comboStatic = new TextStatic(_lang.string("game_combo"));
                this.addChild(comboStatic);
            }

            if (options.displayRawGoods)
            {
                player1RawGoods = new RawGoods(options);
                this.addChild(player1RawGoods);

                rawGoodsStatic = new TextStatic(_lang.string("game_raw_goods"));
                rawGoodsStatic.setFormatting(options.rawGoodsColor, 12)
                this.addChild(rawGoodsStatic);
            }

            if (options.displayComboTotal)
            {
                comboTotal = new Combo(options);
                if (sideScroll)
                    comboTotal.alignment = "right";
                this.addChild(comboTotal);

                comboTotalStatic = new TextStatic(_lang.string("game_combo_total"));
                this.addChild(comboTotalStatic);
            }

            if (options.displayAccuracyBar)
            {
                accBar = new AccuracyBar(options);
                this.addChild(accBar);
            }

            if (options.displaySongProgress || options.replay)
            {
                progressDisplay = new ProgressBar(this, 161, 9, 458, 20, 4, 0x545454, 0.1);

                if (options.replay)
                    progressDisplay.addEventListener(MouseEvent.CLICK, progressMouseClick);
            }
            if (options.displaySongProgressText)
            {
                progressDisplayText = new TextStatic("0:00");
                this.addChild(progressDisplayText);
            }

            buildJudge();
            buildHealth();

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
                judgeSettings = buildJudgeNodes(options.judgeWindow);
            else
                judgeSettings = buildJudgeNodes(Constant.JUDGE_WINDOW);
            judgeOffset = options.offsetJudge * 1000 / 30;
            autoJudgeOffset = options.autoJudgeOffset;
        }

        private function initVars(postStart:Boolean = true):void
        {
            // Post Start Time
            if (postStart && !_gvars.activeUser.isGuest && !options.replay && !options.isEditor && song.songInfo.engine == null)
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

            // Game Vars
            _keys = [];
            gameLife = 50;
            gameScore = 0;
            gameRawGoods = 0;
            gameReplay = [];
            gameReplayHit = [];

            binReplayNotes = new Vector.<ReplayBinFrame>(song.totalNotes, true);
            binReplayBoos = new <ReplayBinFrame>[];

            // Prefill Replay
            for (var i:int = song.totalNotes - 1; i >= 0; i--)
                binReplayNotes[i] = new ReplayBinFrame(NaN, song.getNote(i).direction, i);

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
                gameLastNoteFrame = song.getNote(song.totalNotes - 1).frame + Math.ceil(song.songInfo.time_end * 30);
                gameFirstNoteFrame = song.getNote(0).frame;
            }
            if (comboTotal)
                comboTotal.update(song.totalNotes);

            msStartTime = getTimer();
            absoluteStart = getTimer();
            gamePosition = 0;
            gameProgress = 0;
            absolutePosition = 0;

            songOffset = new RollingAverage(options.frameRate * 4, _avars.configMusicOffset);
            frameRate = new RollingAverage(options.frameRate * 4, options.frameRate);
            accuracy = new Average();

            songDelayStarted = false;

            updateFieldVars();

            if (progressDisplayText)
                progressDisplayText.update(TimeUtil.convertToHMSS(Math.ceil(gameLastNoteFrame / 30)));

            // Handle Early Charts - Pad Charts till atleast 2 seconds before first note.
            if (song != null && song.totalNotes > 0 && options.isolationOffset == 0)
            {
                var firstNote:Note = song.getNote(0);
                if (firstNote.time < 2)
                    absoluteStart += (2 - firstNote.time) * 1000;
            }

            if (postStart)
            {
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
            Logger.success(this, "Post Start Load Success = " + data.result);
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

            if (quitDoubleTap > 0)
            {
                quitDoubleTap--;
            }

            if (gameProgress >= gameLastNoteFrame + 20 || quitDoubleTap == 0)
            {
                GAME_STATE = GAME_END;
                return;
            }

            // Timer Text
            if (gameProgress % 30 == 0 && progressDisplayText != null)
            {
                progressDisplayText.update(TimeUtil.convertToHMSS(Math.ceil(Math.max(0, (gameLastNoteFrame - gameProgress)) / 30)));
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
                if (options.isAutoplay && (gameProgress - curNote.PROGRESS + player1JudgeOffset) >= 0)
                {
                    commitJudge(curNote.DIR, (curNote.PROGRESS + player1JudgeOffset), 50);
                    noteBox.removeNote(curNote.ID);
                    n--;
                }

                // Remove Old note
                if (gameProgress - curNote.PROGRESS + player1JudgeOffset >= 6)
                {
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
                        if (repCurNote.ID >= cutOffReplayNote || (options.replay.generationReplayNotes[repCurNote.ID] == null || isNaN(options.replay.generationReplayNotes[repCurNote.ID].time)))
                        {
                            continue;
                        }

                        var diffValue:int = options.replay.generationReplayNotes[repCurNote.ID].time + repCurNote.POSITION;
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
                        {
                            commitJudge(newPress.direction, gameProgress, -5);
                            binReplayBoos[binReplayBoos.length] = new ReplayBinFrame(newPress.time, newPress.direction, binReplayBoos.length);
                        }
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

        private function onEnterFrame(e:Event):void
        {
            // UI Updates
            if (options.displayJudge && player1Judge != null)
            {
                player1Judge.updateJudge(e);
            }


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

                    gamePosition = Math.round(absolutePosition + songOffset.value);

                    var targetProgress:int = Math.round(gamePosition * 30 / 1000 - 0.5);
                    var threshold:int = Math.round(1 / (frameRate.value / 60));
                    if (threshold < 1)
                        threshold = 1;
                    if (options.replay)
                        threshold = 0x7fffffff;

                    //Logger.debug("GP", "lAP: " + lastAbsolutePosition + " | aP: " + absolutePosition + " | sDS: " + songDelayStarted + " | sD: " + songDelay + " | sOv: " + songOffset.value + " | sGP: " + song.getPosition() + " | sP: " + songPosition + " | gP: " + gamePosition + " | tP: " + targetProgress + " | t: " + threshold);

                    while (gameProgress < targetProgress && threshold-- > 0)
                        logicTick();

                    if (reverseMod)
                        stopClips(song_background, 2 + song.musicStartFrames - globalOffsetRounded + gameProgress * options.songRate);
                    else
                        stopClips(song_background, 2 + song.musicStartFrames - globalOffsetRounded + gameProgress * options.songRate);

                    if (options.modEnabled("tap_pulse"))
                    {
                        noteBoxOffset.x = Math.max(Math.min(Math.abs(noteBoxOffset.x) < 0.5 ? 0 : (noteBoxOffset.x * 0.992), noteBox.positionOffsetMax.max_x), noteBox.positionOffsetMax.min_x);
                        noteBoxOffset.y = Math.max(Math.min(Math.abs(noteBoxOffset.y) < 0.5 ? 0 : (noteBoxOffset.y * 0.992), noteBox.positionOffsetMax.max_y), noteBox.positionOffsetMax.min_y);

                        noteBox.x = noteBoxPositionDefault.x + noteBoxOffset.x;
                        noteBox.y = noteBoxPositionDefault.y + noteBoxOffset.y;
                    }

                    noteBox.update(gamePosition);

                    if (progressDisplay)
                        progressDisplay.update(gameProgress / gameLastNoteFrame, false);
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
                        judgeScorePosition(dir, Math.round(getTimer() - absoluteStart + songOffset.value));
                    }
                }
            }

            // Game Restart
            if (keyCode == _gvars.playerUser.keyRestart)
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
            if (GAME_STATE == GAME_DISPOSE || song == null)
                return;

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
            if (!options.isEditor)
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

            if (!options.replay && !options.isEditor)
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
                this.removeChild(progressDisplay);
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

            // Go to results
            switchTo((options.isEditor) ? Main.GAME_MENU_PANEL : GameMenu.GAME_RESULTS);
        }

        private function restartGame():void
        {
            // Remove Notes
            noteBox.reset();

            if (player1PAWindow)
                player1PAWindow.reset();

            if (accBar)
                accBar.onResetSignal();

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
            song.stop();
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
                    flashLight = new FlashlightOverlay();

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
            if (!options.displayScreencut)
                return;

            if (screenCut)
            {
                if (this.contains(screenCut))
                    this.removeChild(screenCut);
                screenCut = null;
            }
            screenCut = new ScreenCut(options);
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
            defaultLayout[LAYOUT_PROGRESS_BAR] = {x: 161, y: 9};
            defaultLayout[LAYOUT_PROGRESS_TEXT] = {x: 768, y: 5, properties: {alignment: "right"}};
            defaultLayout[LAYOUT_JUDGE] = {x: 392, y: 228};
            defaultLayout[LAYOUT_ACCURACY_BAR] = {x: (Main.GAME_WIDTH / 2), y: 328};
            defaultLayout[LAYOUT_HEALTH] = {x: Main.GAME_WIDTH - 37, y: 71.5};
            defaultLayout[LAYOUT_RECEPTORS] = {x: 230, y: 0};
            if (sideScroll)
            {
                defaultLayout[LAYOUT_PA] = {x: 16, y: 418};
                defaultLayout[LAYOUT_SCORE] = {x: 392, y: 24};
                defaultLayout[LAYOUT_COMBO] = {x: 508, y: 388};
                defaultLayout[LAYOUT_COMBO_TOTAL] = {x: 770, y: 420, properties: {alignment: "right"}};
                defaultLayout[LAYOUT_COMBO_STATIC] = {x: 512, y: 450};
                defaultLayout[LAYOUT_COMBO_TOTAL_STATIC] = {x: 734, y: 414};
                defaultLayout[LAYOUT_RAWGOODS] = {x: 90, y: 35};
                defaultLayout[LAYOUT_RAWGOODS_STATIC] = {x: 16, y: 53};
            }
            else
            {
                defaultLayout[LAYOUT_PA] = {x: 6, y: 96};
                defaultLayout[LAYOUT_SCORE] = {x: 392, y: 440};
                defaultLayout[LAYOUT_COMBO] = {x: 222, y: 402, properties: {alignment: "right"}};
                defaultLayout[LAYOUT_COMBO_TOTAL] = {x: 544, y: 402};
                defaultLayout[LAYOUT_COMBO_STATIC] = {x: 228, y: 436};
                defaultLayout[LAYOUT_COMBO_TOTAL_STATIC] = {x: 502, y: 436};
                defaultLayout[LAYOUT_RAWGOODS] = {x: 80, y: 365};
                defaultLayout[LAYOUT_RAWGOODS_STATIC] = {x: 4, y: 380};
            }

            noteBoxPositionDefault = interfaceLayout(LAYOUT_RECEPTORS);

            // Position
            interfacePosition(progressDisplay, interfaceLayout(LAYOUT_PROGRESS_BAR));
            interfacePosition(progressDisplayText, interfaceLayout(LAYOUT_PROGRESS_TEXT));
            interfacePosition(noteBox, interfaceLayout(LAYOUT_RECEPTORS));
            interfacePosition(accBar, interfaceLayout(LAYOUT_ACCURACY_BAR));
            interfacePosition(player1Life, interfaceLayout(LAYOUT_HEALTH));
            interfacePosition(score, interfaceLayout(LAYOUT_SCORE));
            interfacePosition(comboTotal, interfaceLayout(LAYOUT_COMBO_TOTAL));
            interfacePosition(comboStatic, interfaceLayout(LAYOUT_COMBO_STATIC));
            interfacePosition(comboTotalStatic, interfaceLayout(LAYOUT_COMBO_TOTAL_STATIC));
            interfacePosition(rawGoodsStatic, interfaceLayout(LAYOUT_RAWGOODS_STATIC));

            interfacePosition(player1PAWindow, interfaceLayout(LAYOUT_PA));
            interfacePosition(player1Combo, interfaceLayout(LAYOUT_COMBO));
            interfacePosition(player1RawGoods, interfaceLayout(LAYOUT_RAWGOODS))
            interfacePosition(player1Judge, interfaceLayout(LAYOUT_JUDGE));

            // Editor Mode
            if (options.isEditor)
            {
                interfaceEditor(progressDisplay, interfaceLayout(LAYOUT_PROGRESS_BAR, false));
                interfaceEditor(progressDisplayText, interfaceLayout(LAYOUT_PROGRESS_TEXT, false));
                interfaceEditor(noteBox, interfaceLayout(LAYOUT_RECEPTORS, false));
                interfaceEditor(accBar, interfaceLayout(LAYOUT_ACCURACY_BAR, false));
                interfaceEditor(player1Life, interfaceLayout(LAYOUT_HEALTH, false));
                interfaceEditor(score, interfaceLayout(LAYOUT_SCORE, false));
                interfaceEditor(comboTotal, interfaceLayout(LAYOUT_COMBO_TOTAL, false));
                interfaceEditor(comboStatic, interfaceLayout(LAYOUT_COMBO_STATIC, false));
                interfaceEditor(comboTotalStatic, interfaceLayout(LAYOUT_COMBO_TOTAL_STATIC, false));
                interfaceEditor(rawGoodsStatic, interfaceLayout(LAYOUT_RAWGOODS_STATIC, false));

                interfaceEditor(player1PAWindow, interfaceLayout(LAYOUT_PA, false));
                interfaceEditor(player1Combo, interfaceLayout(LAYOUT_COMBO, false));
                interfaceEditor(player1RawGoods, interfaceLayout(LAYOUT_RAWGOODS, false))
                interfaceEditor(player1Judge, interfaceLayout(LAYOUT_JUDGE, false));

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

        private function buildJudgeNodes(src:Array):Vector.<JudgeNode>
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

                var acc:Number = note.POSITION - position;
                var diff:Number = positionJudged - note.POSITION;
                var lastJudge:JudgeNode = null;
                for each (var j:JudgeNode in judgeSettings)
                {
                    if (diff > j.time)
                        lastJudge = j;
                }
                score = lastJudge ? lastJudge.score : 0;
                if (score)
                    frame = lastJudge.frame;
                if (!_avars.configJudge && !score)
                {
                    var pdiff:int = gameProgress - note.PROGRESS + player1JudgeOffset;
                    if (pdiff >= -3 && pdiff <= 3)
                        booConflict = true;
                }
                if (score > 0)
                    break;
                else if (diff <= judgeSettings[0].time)
                    break;
            }
            if (score)
            {
                commitJudge(dir, frame + note.PROGRESS - player1JudgeOffset, score);
                noteBox.removeNote(note.ID);
                accuracy.addValue(acc);
                binReplayNotes[note.ID].time = diff;

                if (accBar != null)
                    accBar.onScoreSignal(score, diff);
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

                if (accBar != null)
                    accBar.onScoreSignal(score, diff * 33.3333 - 1);
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

        private function checkAutofail(autofail:Number, hit:Number):void
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

            if (player1PAWindow)
                player1PAWindow.update(hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo);

            if (score)
                score.update(gameScore);

            if (player1Combo)
                player1Combo.update(hitCombo, hitAmazing, hitPerfect, hitGood, hitAverage, hitMiss, hitBoo, gameRawGoods);

            if (player1RawGoods)
                player1RawGoods.update(gameRawGoods);
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
