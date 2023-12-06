package game
{
    import arc.ArcGlobals;
    import assets.menu.icons.fa.iconPhoto;
    import assets.menu.icons.fa.iconRandom;
    import assets.menu.icons.fa.iconVideo;
    import classes.Language;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.score.ScoreHandler;
    import classes.score.ScoreHandlerEvent;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.StarSelector;
    import com.flashfla.net.DynamicURLLoader;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;
    import flash.utils.getTimer;
    import game.results.GameResultBackground;
    import game.results.GameResultSingle;
    import menu.MenuPanel;
    import popups.PopupHighscores;
    import popups.PopupSongNotes;

    public class GameResults extends MenuPanel
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _lang:Language = Language.instance;
        private var _loader:DynamicURLLoader;
        private var _playlist:Playlist = Playlist.instance;
        private var _score:ScoreHandler = ScoreHandler.instance;

        // Results
        private var resultIndex:int = 0;
        private var songResults:Vector.<GameScoreResult>;
        private var result:GameScoreResult;

        private var queueTotalResult:GameScoreResult;

        private var background:GameResultBackground;
        private var resultsDisplay:GameResultSingle;

        // Title Bar
        private var navSaveReplay:BoxIcon;
        private var navScreenShot:BoxIcon;
        private var navRandomSong:BoxIcon;

        // Game Result
        private var navRating:Sprite;
        private var navPrev:BoxButton;
        private var navNext:BoxButton;

        // Menu Bar
        private var navReplay:BoxButton;
        private var navOptions:BoxButton;
        private var navHighscores:BoxButton;
        private var navMenu:BoxButton;

        public function GameResults(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            songResults = _gvars.songResults.concat();

            // Send last score
            if (!_gvars.options.replay)
            {
                const lastResult:GameScoreResult = songResults[songResults.length - 1];

                // Update Judge Offset
                updateJudgeOffset(lastResult);

                if (_gvars.songQueue.length == 0)
                {
                    _score.addEventListener(ScoreHandlerEvent.SUCCESS, e_onScoreResult);
                    _score.addEventListener(ScoreHandlerEvent.FAILURE, e_onScoreResult);
                }
                _score.sendScore(lastResult);
                _score.saveLocalReplay(lastResult);

            }

            // More songs to play, jump to gameplay or loading.
            if (_gvars.songQueue.length > 0)
            {
                switchTo(GameMenu.GAME_LOADING);
                return false;
            }
            else
            {
                _gvars.songResults.length = 0;
            }
            return true;
        }

        //******************************************************************************************//
        // Panel Stage Functions
        //******************************************************************************************//

        override public function stageAdd():void
        {
            // Reset Window Title
            stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE;

            // Background
            background = new GameResultBackground();
            addChild(background);

            // Background Noise
            var noiseSource:BitmapData = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x00000000);
            noiseSource.perlinNoise(Main.GAME_WIDTH, Main.GAME_HEIGHT, 12, getTimer(), true, false, 7, true);
            var noiseImage:Bitmap = new Bitmap(noiseSource);
            noiseImage.alpha = 0.2;
            background.addChild(noiseImage);

            resultsDisplay = new GameResultSingle();
            addChild(resultsDisplay);

            var buttonMenu:Sprite = new Sprite();
            var buttonMenuItems:Array = [];
            buttonMenu.x = 22;
            buttonMenu.y = 428;
            this.addChild(buttonMenu);

            // Main Bavigation Buttons
            navOptions = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_options"), 17, eventHandler);
            buttonMenuItems.push(navOptions);

            navHighscores = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_highscores"), 17, eventHandler);
            buttonMenuItems.push(navHighscores);

            navReplay = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_replay_song"), 17, eventHandler);
            buttonMenuItems.push(navReplay);

            navMenu = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_exit_menu"), 17, eventHandler);
            buttonMenuItems.push(navMenu);

            var BUTTON_GAP:int = 11;
            var BUTTON_WIDTH:int = (735 - (Math.max(0, (buttonMenuItems.length - 1)) * BUTTON_GAP)) / buttonMenuItems.length;
            for (var bx:int = 0; bx < buttonMenuItems.length; bx++)
            {
                buttonMenuItems[bx].width = BUTTON_WIDTH;
                buttonMenuItems[bx].x = BUTTON_WIDTH * bx + BUTTON_GAP * bx;
            }

            // Song Notes / Star Rating Button
            navRating = new Sprite();
            navRating.buttonMode = true;
            navRating.mouseChildren = false;
            navRating.addEventListener(MouseEvent.CLICK, eventHandler);
            StarSelector.drawStar(navRating.graphics, 18, 0, 0, true, 0xF2D60D, 1);
            resultsDisplay.addChild(navRating);

            // Song Results Buttons
            navScreenShot = new BoxIcon(this, 522, 6, 32, 32, new iconPhoto(), eventHandler);
            navScreenShot.setIconColor("#E2FEFF");
            navScreenShot.setHoverText(_lang.string("game_results_queue_save_screenshot_clipboard_hint"), "bottom");

            navSaveReplay = new BoxIcon(this, 485, 6, 32, 32, new iconVideo(), eventHandler);
            navSaveReplay.setIconColor("#E2FEFF");
            navSaveReplay.setHoverText(_lang.string("game_results_queue_save_replay"), "bottom");

            navRandomSong = new BoxIcon(this, 448, 6, 32, 32, new iconRandom(), eventHandler);
            navRandomSong.setIconColor("#E2FEFF");
            navRandomSong.setHoverText(_lang.string("game_results_play_random_song"), "bottom");

            // Song Results - Song Queue
            navPrev = new BoxButton(this, 18, 62, 90, 32, _lang.string("game_results_queue_previous"), 12, eventHandler);
            navNext = new BoxButton(this, 672, 62, 90, 32, _lang.string("game_results_queue_next"), 12, eventHandler);

            // Build Queue Total
            buildQueueTotal();

            // Display Game Result
            displayGameResult(songResults.length > 1 ? -1 : 0);

            _gvars.gameMain.displayPopupQueue();

            // Add keyboard navigation
            stage.addEventListener(KeyboardEvent.KEY_DOWN, eventHandler);

            // Add Mouse Move for graphs
            stage.addEventListener(MouseEvent.MOUSE_MOVE, resultsDisplay.e_graphHover);
        }

        override public function stageRemove():void
        {
            // Remove Score Events
            _score.removeEventListener(ScoreHandlerEvent.SUCCESS, e_onScoreResult);
            _score.removeEventListener(ScoreHandlerEvent.FAILURE, e_onScoreResult);

            // Remove keyboard navigation
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, eventHandler);

            // Remove Mouse Move for graphs
            if (resultsDisplay)
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, resultsDisplay.e_graphHover);

            super.stageRemove();
        }

        private function e_onScoreResult(e:ScoreHandlerEvent):void
        {
            if (resultsDisplay)
                resultsDisplay.onScoreResult(e);
        }

        //******************************************************************************************//
        // Results Display Logic
        //******************************************************************************************//
        public function buildQueueTotal():void
        {
            if (songResults.length <= 1)
                return;

            var songSubTitle:String = "";

            queueTotalResult = new GameScoreResult();
            queueTotalResult.game_index = -1;
            queueTotalResult.user = songResults[0].user;
            queueTotalResult.options = songResults[0].options;
            queueTotalResult.replay_hit = [];
            queueTotalResult.score_total = 0;

            queueTotalResult.songInfo = new SongInfo();
            queueTotalResult.songInfo.order = songResults.length;

            for (var x:int = 0; x < songResults.length; x++)
            {
                var tempResult:GameScoreResult = songResults[x];

                songSubTitle += tempResult.songInfo.name + ", ";

                queueTotalResult.note_count += tempResult.note_count;
                queueTotalResult.amazing += tempResult.amazing;
                queueTotalResult.perfect += tempResult.perfect;
                queueTotalResult.good += tempResult.good;
                queueTotalResult.average += tempResult.average;
                queueTotalResult.miss += tempResult.miss;
                queueTotalResult.boo += tempResult.boo;
                queueTotalResult.score += tempResult.score;
                queueTotalResult.credits += tempResult.credits;
                queueTotalResult.restarts += tempResult.restarts;

                // Replay Graph
                for (var y:int = 0; y < tempResult.replay_hit.length; y++)
                    queueTotalResult.replay_hit.push(tempResult.replay_hit[y]);

                // Score Total
                queueTotalResult.score_total += tempResult.score_total;
            }
            queueTotalResult.update(_gvars);

            queueTotalResult.max_combo = getMaxCombo(queueTotalResult);

            queueTotalResult.songInfo.name = songSubTitle.substr(0, songSubTitle.length - 2);
        }

        public function displayGameResult(gameIndex:int):void
        {
            // Set Index
            resultIndex = gameIndex;

            // Buttons
            navScreenShot.enabled = false;
            navSaveReplay.enabled = false;
            navPrev.visible = false;
            navNext.visible = false;

            if (songResults.length > 1)
            {
                if (gameIndex > -1)
                {
                    navPrev.visible = true;
                    navPrev.text = (gameIndex == 0 ? _lang.string("game_results_queue_total") : _lang.string("game_results_queue_previous"));
                }
                if (gameIndex < songResults.length - 1)
                    navNext.visible = true;
            }

            // Song Results
            // Song Queue (Multiple Songs)
            if (gameIndex == -1)
            {
                navHighscores.enabled = false;
                result = queueTotalResult;
            }

            // Single Song
            else
            {
                navHighscores.enabled = true;
                result = songResults[resultIndex];

                // Song Notes / Star
                navRating.visible = (result.songInfo != null);

                // Highscores
                if (result.songInfo && result.songInfo.engine)
                    navHighscores.enabled = false;

                // Save Replay Button
                navSaveReplay.enabled = true;
                if (!_score.canSendScore(result, true, false, true, true) || result.is_preview)
                    navSaveReplay.enabled = false;
            }

            // Save Screenshot
            if (!result.is_preview)
                navScreenShot.enabled = true;

            // Random Song Button
            if (result.options.replay || result.is_preview)
                navRandomSong.enabled = false;

            // Update
            resultsDisplay.update(result);

            // Align Rating Star to Song Title
            navRating.x = resultsDisplay.songName.x + resultsDisplay.songName.textfield.x - 22;
            navRating.y = resultsDisplay.songName.y + 5;
        }

        //******************************************************************************************//
        // Helper Functions
        //******************************************************************************************//

        /**
         * Handles Auto Judge Offset options by changing the judge offset and saving
         * the user settings. This is called when scores are saved successfully and
         * passes in the site response post vars, not GameScoreResult.
         * @param result Post Vars
         */
        private function updateJudgeOffset(result:GameScoreResult):void
        {
            if (_gvars.activeUser.AUTO_JUDGE_OFFSET && // Auto Judge Offset enabled
                (result.amazing + result.perfect + result.good + result.average >= 50) && // Accuracy data is reliable
                result.accuracy !== 0)
            {
                _gvars.activeUser.JUDGE_OFFSET = Number(result.accuracy_frames.toFixed(3));
                // Save settings
                _gvars.activeUser.saveLocal();
                _gvars.activeUser.save();
            }
        }

        /**
         * Calculates the max combo in a game score result based on the replay.
         * This is used for queue results to display the max combo across
         * multiple songs for the UI.
         * @param gameResult
         * @return int
         */
        private function getMaxCombo(gameResult:GameScoreResult):int
        {
            var maxCombo:int = 0;
            var curCombo:int = 0;
            for (var x:int = 0; x < gameResult.replay_hit.length; x++)
            {
                var curNote:int = gameResult.replay_hit[x];
                if (curNote > 0)
                {
                    curCombo += 1;
                }
                else if (curNote <= 0)
                {
                    curCombo = 0;
                }
                if (curCombo > maxCombo)
                    maxCombo = curCombo;
            }
            return maxCombo;
        }

        //******************************************************************************************//
        // Event Handlers
        //******************************************************************************************//

        /**
         * Handles all UI events, both mouse and keyboard.
         * @param e
         */
        private function eventHandler(e:* = null):void
        {
            var target:DisplayObject = e.target;

            // Don't do anything with popups open.
            if (_gvars.gameMain.current_popup != null)
                return;

            // Handle Key events and click in the same function
            if (e.type == "keyDown")
            {
                target = null;
                var keyCode:int = e.keyCode;
                if ((keyCode == _gvars.playerUser.keyLeft || keyCode == Keyboard.LEFT) && navPrev.visible)
                {
                    target = navPrev;
                }
                else if ((keyCode == _gvars.playerUser.keyRight || keyCode == Keyboard.RIGHT) && navNext.visible)
                {
                    target = navNext;
                }
                else if (keyCode == _gvars.playerUser.keyRestart)
                {
                    target = navReplay;
                }
                else if (keyCode == _gvars.playerUser.keyQuit)
                {
                    target = navMenu;
                    stage.removeEventListener(KeyboardEvent.KEY_DOWN, eventHandler);
                }
            }


            if (!target)
                return;

            // Based on target
            if (target == navSaveReplay)
            {
                _score.saveServerReplay(result);
            }

            else if (target == navScreenShot)
            {
                navScreenShot.purgeHoverSprite();
                if (e.ctrlKey)
                {
                    _gvars.saveScreenshotToClipboard()
                }
                else
                {
                    var ext:String = "";
                    if (resultIndex >= 0)
                    {
                        ext = result.screenshot_path;
                    }
                    _gvars.takeScreenShot(ext);
                }

            }

            else if (target == navPrev)
            {
                displayGameResult(resultIndex - 1);
            }

            else if (target == navNext)
            {
                displayGameResult(resultIndex + 1);
            }

            else if (target == navReplay)
            {
                var skipload:Boolean = (songResults.length == 1 && songResults[0].song && songResults[0].song.isLoaded);

                if (!_gvars.options.replay)
                    _gvars.options.fill();

                if (skipload)
                {
                    _gvars.songRestarts++;
                    switchTo(GameMenu.GAME_PLAY);
                }
                else
                {
                    _gvars.songQueue = _gvars.totalSongQueue.concat();
                    switchTo(GameMenu.GAME_LOADING);
                }
            }

            else if (target == navRandomSong)
            {
                var songList:Array = _playlist.playList;
                var selectedSong:Object;

                //Check for filters and filter the songs list
                if (_gvars.activeFilter != null)
                {
                    var filteredSongInfos:Vector.<SongInfo>;
                    filteredSongInfos = _playlist.indexList.filter(function(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
                    {
                        return _gvars.activeFilter.process(item, _gvars.activeUser);
                    });

                    songList = [];
                    for each (var songInfo:SongInfo in filteredSongInfos)
                        songList.push(songInfo);
                }

                // Filter to only Playable Songs
                songList = songList.filter(function(item:SongInfo, index:int, array:Array):Boolean
                {
                    return _gvars.checkSongAccess(item) == GlobalVariables.SONG_ACCESS_PLAYABLE;
                });

                // Check for at least 1 possible playable song.
                if (songList.length > 0)
                {
                    selectedSong = songList[Math.floor(Math.random() * (songList.length - 1))];
                    _gvars.songQueue.push(selectedSong);
                    _gvars.options = new GameOptions();
                    _gvars.options.fill();
                    switchTo(Main.GAME_PLAY_PANEL);
                }
            }

            else if (target == navOptions)
            {
                addPopup(Main.POPUP_OPTIONS);
            }

            else if (target == navHighscores)
            {
                if (resultIndex >= 0)
                {
                    addPopup(new PopupHighscores(this, result.songInfo));
                }
            }

            else if (target == navMenu)
            {
                switchTo(Main.GAME_MENU_PANEL);
            }

            else if (target == navRating)
            {
                if (resultIndex >= 0)
                {
                    _gvars.gameMain.addPopup(new PopupSongNotes(this, result.songInfo));
                }
            }
        }
    }
}
