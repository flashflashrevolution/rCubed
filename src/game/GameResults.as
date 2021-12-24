package game
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerSingleton;
    import assets.menu.icons.fa.iconPhoto;
    import assets.menu.icons.fa.iconRandom;
    import assets.menu.icons.fa.iconRight;
    import assets.menu.icons.fa.iconSmallT;
    import assets.menu.icons.fa.iconVideo;
    import assets.results.ResultsBackground;
    import by.blooddy.crypto.SHA1;
    import classes.Alert;
    import classes.Language;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.replay.Replay;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.StarSelector;
    import classes.ui.Text;
    import com.flashfla.net.DynamicURLLoader;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.ObjectUtil;
    import com.flashfla.utils.TimeUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.ui.Keyboard;
    import flash.utils.getTimer;
    import game.graph.GraphAccuracy;
    import game.graph.GraphBase;
    import game.graph.GraphCombo;
    import menu.MenuPanel;
    import popups.PopupHighscores;
    import popups.PopupMessage;
    import popups.PopupSongNotes;
    import popups.PopupTokenUnlock;
    import popups.replays.ReplayHistoryTabLocal;

    public class GameResults extends MenuPanel
    {
        public static const GRAPH_WIDTH:int = 718;
        public static const GRAPH_HEIGHT:int = 117;
        public static const GRAPH_COMBO:int = 0;
        public static const GRAPH_ACCURACY:int = 1;

        private var graphCache:Object = {"0": {}, "1": {}};

        private var _mp:MultiplayerSingleton = MultiplayerSingleton.getInstance();
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _lang:Language = Language.instance;
        private var _loader:DynamicURLLoader;
        private var _playlist:Playlist = Playlist.instance;

        // Results
        private var resultsTime:String = TimeUtil.getCurrentDate();
        private var resultIndex:int = 0;
        private var songResults:Vector.<GameScoreResult>;
        private var songRankIndex:int = -1;

        // Title Bar
        private var navSaveReplay:BoxIcon;
        private var navScreenShot:BoxIcon;
        private var navRandomSong:BoxIcon;

        // Game Result
        private var resultsDisplay:ResultsBackground;
        private var navRating:Sprite;
        private var navPrev:BoxButton;
        private var navNext:BoxButton;
        private var resultsMods:Text;

        // Graph
        private var graphType:int = 0;
        private var graphToggle:BoxIcon;
        private var graphAccuracy:BoxIcon;
        private var activeGraph:GraphBase;
        private var graphDraw:Sprite;
        private var graphOverlay:Sprite;
        private var graphOverlayText:Text;

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
                sendScore();
                saveLocalReplay();
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
            // Add keyboard navigation
            stage.addEventListener(KeyboardEvent.KEY_DOWN, eventHandler);

            // Add Mouse Move for graphs
            stage.addEventListener(MouseEvent.MOUSE_MOVE, e_graphHover);

            // Reset Window Title
            stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE;

            // Get Graph Type
            graphType = LocalStore.getVariable("result_graph_type", 0);

            // Background
            resultsDisplay = new ResultsBackground();
            resultsDisplay.song_description.styleSheet = Constant.STYLESHEET;
            this.addChild(resultsDisplay);

            // Background Noise
            var noiseSource:BitmapData = new BitmapData(780, 480, false, 0x00000000);
            noiseSource.perlinNoise(780, 480, 12, getTimer(), true, false, 7, true);
            var noiseImage:Bitmap = new Bitmap(noiseSource);
            noiseImage.alpha = 0.3;
            resultsDisplay.blueBackground.addChild(noiseImage);

            // Avatar
            var result:GameScoreResult = songResults[songResults.length - 1];
            if (result.user)
            {
                var userAvatar:DisplayObject = result.user.avatar;
                if (userAvatar && userAvatar.height > 0 && userAvatar.width > 0)
                {
                    userAvatar.x = 616 + ((99 - userAvatar.width) / 2);
                    userAvatar.y = 114 + ((99 - userAvatar.height) / 2);
                    this.addChild(userAvatar);
                }
            }

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

            if (!_mp.gameplayPlayingStatus())
            {
                navReplay = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_replay_song"), 17, eventHandler);
                buttonMenuItems.push(navReplay);
            }

            if (!_gvars.flashvars.replay && !_gvars.flashvars.preview_file)
            {
                navMenu = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_exit_menu"), 17, eventHandler);
                buttonMenuItems.push(navMenu);
            }

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
            navScreenShot.setHoverText(_lang.string("game_results_queue_save_screenshot"), "bottom");

            navSaveReplay = new BoxIcon(this, 485, 6, 32, 32, new iconVideo(), eventHandler);
            navSaveReplay.setIconColor("#E2FEFF");
            navSaveReplay.setHoverText(_lang.string("game_results_queue_save_replay"), "bottom");

            navRandomSong = new BoxIcon(this, 448, 6, 32, 32, new iconRandom(), eventHandler);
            navRandomSong.setIconColor("#E2FEFF");
            navRandomSong.setHoverText(_lang.string("game_results_play_random_song"), "bottom");

            // Song Results - Song Queue
            navPrev = new BoxButton(this, 18, 62, 90, 32, _lang.string("game_results_queue_previous"), 12, eventHandler);
            navNext = new BoxButton(this, 672, 62, 90, 32, _lang.string("game_results_queue_next"), 12, eventHandler);

            // Graph
            resultsMods = new Text(this, 18, 276, "---");

            graphDraw = new Sprite();
            graphDraw.x = 30;
            graphDraw.y = 298;
            graphDraw.cacheAsBitmap = true;
            this.addChild(graphDraw);

            graphOverlay = new Sprite();
            graphOverlay.x = 30;
            graphOverlay.y = 298;
            graphOverlay.mouseChildren = false;
            graphOverlay.mouseEnabled = false;
            this.addChild(graphOverlay);

            graphToggle = new BoxIcon(this, 10, 298, 16, 18, new iconRight(), eventHandler);
            graphToggle.padding = 6;
            graphToggle.setHoverText(_lang.string("result_next_graph_type"), "right");

            graphAccuracy = new BoxIcon(this, 10, 318, 16, 18, new iconSmallT());
            graphAccuracy.padding = 6;
            graphAccuracy.delay = 250;

            // Display Game Result
            displayGameResult(songResults.length > 1 ? -1 : 0);

            _mp.gameplayResults(this, songResults);
            _gvars.gameMain.displayPopupQueue();
        }

        override public function stageRemove():void
        {
            // Remove keyboard navigation
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, eventHandler);

            // Remove Mouse Move for graphs
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, e_graphHover);

            super.stageRemove();
        }

        //******************************************************************************************//
        // Results Display Logic
        //******************************************************************************************//

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

            // Variables
            var skillLevel:String = (songResults[0].user != null) ? ("[Lv." + songResults[0].user.skillLevel + "]" + " ") : "";
            var displayTime:String = "";
            var songInfo:SongInfo;
            var songTitle:String = "";
            var songSubTitle:String = "";

            var scoreTotal:int = 0;

            // Song Results
            var result:GameScoreResult;

            // Song Queue (Multiple Songs)
            if (gameIndex == -1)
            {
                navHighscores.enabled = false;
                result = new GameScoreResult();
                result.user = songResults[0].user;
                result.options = songResults[0].options;
                result.replay_hit = [];

                for (var x:int = 0; x < songResults.length; x++)
                {
                    var tempResult:GameScoreResult = songResults[x];
                    songInfo = tempResult.songInfo;
                    songSubTitle += songInfo.name + ", ";
                    result.note_count += tempResult.note_count;
                    result.amazing += tempResult.amazing;
                    result.perfect += tempResult.perfect;
                    result.good += tempResult.good;
                    result.average += tempResult.average;
                    result.miss += tempResult.miss;
                    result.boo += tempResult.boo;
                    result.score += tempResult.score;
                    result.credits += tempResult.credits;
                    result.restarts += tempResult.restarts;

                    // Replay Graph
                    for (var y:int = 0; y < tempResult.replay_hit.length; y++)
                        result.replay_hit.push(tempResult.replay_hit[y]);

                    // Score Total
                    scoreTotal += tempResult.score_total;
                }
                result.update(_gvars);

                result.max_combo = getMaxCombo(result);
                songTitle = sprintf(_lang.string("game_results_total_songs"), {"total": NumberUtil.numberFormat(songResults.length)});
                songSubTitle = songSubTitle.substr(0, songSubTitle.length - 2);
                displayTime = resultsTime;

                // Index
                songRankIndex = -1;
            }

            // Single Song
            else
            {
                navHighscores.enabled = true;
                result = songResults[resultIndex];
                songInfo = result.songInfo;

                var seconds:Number = Math.floor(songInfo.time_secs * (1 / result.options.songRate));
                var songLength:String = (Math.floor(seconds / 60)) + ":" + (seconds % 60 >= 10 ? "" : "0") + (seconds % 60);
                var rateString:String = result.options.songRate != 1 ? " (" + result.options.songRate + "x Rate)" : "";

                // Song Title
                songTitle = songInfo.engine ? songInfo.name + rateString : "<a href=\"" + Constant.LEVEL_STATS_URL + songInfo.level + "\">" + songInfo.name + rateString + "</a>";
                songSubTitle = sprintf(_lang.string("game_results_subtitle_difficulty"), {"value": songInfo.difficulty}) + " - " + sprintf(_lang.string("game_results_subtitle_length"), {"value": songLength});
                if (songInfo.author != "")
                    songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_author"), {"value": songInfo.author_html}));
                if (songInfo.stepauthor != "")
                    songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_stepauthor"), {"value": songInfo.stepauthor_html}));

                displayTime = result.end_time;
                scoreTotal = result.score_total;

                // Song Notes / Star
                navRating.visible = (result.songInfo != null);

                // Highscores
                if (result.songInfo && result.songInfo.engine)
                    navHighscores.enabled = false;

                // Cached Rank Index
                songRankIndex = result.game_index + 1;

                // Save Replay Button
                navSaveReplay.enabled = true;
                if (!canSendScore(result, true, false, true, true) || result.is_preview)
                    navSaveReplay.enabled = false;
            }

            // Save Screenshot
            if (!result.is_preview)
                navScreenShot.enabled = true;

            // Random Song Button
            if (result.options.replay || result.is_preview || _mp.gameplayPlayingStatus())
                navRandomSong.enabled = false;

            // Skill rating
            var song_weight:Number = SkillRating.getSongWeight(result);
            if (result.last_note > 0)
                song_weight = 0;

            // Display Results
            if (Text.isUnicode(songTitle))
                resultsDisplay.song_title.defaultTextFormat.font = Language.UNI_FONT_NAME;
            if (Text.isUnicode(songSubTitle))
                resultsDisplay.song_description.defaultTextFormat.font = Language.UNI_FONT_NAME;

            resultsDisplay.results_username.htmlText = "<B>" + (result.options.replay ? "Replay r" : "R") + "esults for " + skillLevel + result.user.name + ":</B>";
            resultsDisplay.results_time.htmlText = "<B>" + displayTime + "</B>";
            resultsDisplay.song_title.htmlText = "<B>" + _lang.wrapFont(songTitle) + "</B>";
            resultsDisplay.song_description.htmlText = "<B>" + songSubTitle + "</B>";
            resultsDisplay.result_amazing.htmlText = "<B>" + NumberUtil.numberFormat(result.amazing) + "</B>";
            resultsDisplay.result_perfect.htmlText = "<B>" + NumberUtil.numberFormat(result.perfect) + "</B>";
            resultsDisplay.result_good.htmlText = "<B>" + NumberUtil.numberFormat(result.good) + "</B>";
            resultsDisplay.result_average.htmlText = "<B>" + NumberUtil.numberFormat(result.average) + "</B>";
            resultsDisplay.result_miss.htmlText = "<B>" + NumberUtil.numberFormat(result.miss) + "</B>";
            resultsDisplay.result_boo.htmlText = "<B>" + NumberUtil.numberFormat(result.boo) + "</B>";
            resultsDisplay.result_maxcombo.htmlText = "<B>" + NumberUtil.numberFormat(result.max_combo) + "</B>";
            resultsDisplay.result_rawscore.htmlText = "<B>" + NumberUtil.numberFormat(result.score) + "</B>";
            resultsDisplay.result_total.htmlText = "<B>" + NumberUtil.numberFormat(scoreTotal) + "</B>";
            resultsDisplay.result_credits.htmlText = "<B>" + NumberUtil.numberFormat(result.credits) + "</B>";
            resultsDisplay.result_rawgoods.htmlText = "<B>" + NumberUtil.numberFormat(result.raw_goods, 1, true) + "</B>";
            resultsDisplay.result_equivalency.htmlText = "<B>" + NumberUtil.numberFormat(song_weight, 2, true) + "</B>";

            // Align Rating Star to Song Title
            navRating.x = resultsDisplay.song_title.x + (resultsDisplay.song_title.width / 2) - (resultsDisplay.song_title.textWidth / 2) - 22;
            navRating.y = resultsDisplay.song_title.y + 4;

            /// - Rank Text
            // Has R3 Highscore
            if (_gvars.songResultRanks[songRankIndex] != null)
            {
                resultsDisplay.result_rank.htmlText = "<B>Rank: " + _gvars.songResultRanks[songRankIndex].new_ranking;
                resultsDisplay.result_last_best.htmlText = "<B>Last Best: " + _gvars.songResultRanks[songRankIndex].old_ranking;
            }
            // Alt Engine Score
            else if (result.songInfo && result.songInfo.engine)
            {
                resultsDisplay.result_credits.htmlText = "<B>--</B>";
                var rank:Object = result.legacyLastRank;
                if (rank)
                {
                    resultsDisplay.result_rank.htmlText = "<B>" + (rank.score < result.score ? "Last" : "Current") + " Best: " + rank.score;
                    resultsDisplay.result_last_best.htmlText = rank.results;
                }
                else
                {
                    resultsDisplay.result_rank.htmlText = "Saved score locally";
                    resultsDisplay.result_last_best.htmlText = "";
                }
            }
            // Getting Rank / Unsendable Score
            else if (!result.options.replay && gameIndex != -1 && !result.user.isGuest)
            {
                resultsDisplay.result_rank.htmlText = canSendScore(result, true, true, false, false) ? "Saving score..." : "Score not saved";
                resultsDisplay.result_last_best.htmlText = "";
            }
            // Blank
            else
            {
                resultsDisplay.result_rank.htmlText = "";
                resultsDisplay.result_last_best.htmlText = "";
            }

            // Edited Replay
            if (result.options.replay && result.options.replay.isEdited)
            {
                resultsDisplay.result_rank.htmlText = _lang.string("results_replay_modified");
                resultsDisplay.result_rank.textColor = 0xF06868;
            }

            // Song Preview
            if (result.is_preview)
            {
                resultsDisplay.results_username.htmlText = "<B>Song Preview:</B>";
                resultsDisplay.result_credits.htmlText = "<B>0</B>";
            }

            // Mod Text
            resultsMods.text = "Scroll Speed: " + result.options.scrollSpeed;
            if (result.restarts > 0)
                resultsMods.text += ", Restarts: " + result.restarts;

            var mods:Array = [];
            for each (var mod:String in result.options.mods)
                mods.push(_lang.string("options_mod_" + mod));

            if (result.options.judgeWindow)
                mods.push(_lang.string("options_mod_judge"));
            if (mods.length > 0)
                resultsMods.text += ", Game Mods: " + mods.join(", ");
            if (result.last_note > 0)
                resultsMods.text += ", Last Note: " + result.last_note;

            if (gameIndex != -1)
            {
                graphAccuracy.setHoverText(sprintf(_lang.string("result_accuracy_deviation"), {"acc_frame": result.accuracy_frames.toFixed(3),
                        "acc_dev_frame": result.accuracy_deviation_frames.toFixed(3),
                        "acc_ms": result.accuracy.toFixed(3),
                        "acc_dev_ms": result.accuracy_deviation.toFixed(3)}), "right");
            }

            drawResultGraph(result);
        }

        //******************************************************************************************//
        // Graph Logic
        //******************************************************************************************//

        /**
         * Displays a valid graph for the given GameScoreResult, this checks if the
         * selected graph can be displayed for the given result.
         *
         * @param result Current GameScoreResult
         */
        private function drawResultGraph(result:GameScoreResult):void
        {
            var graph_type:int = graphType;

            // Check for Totals Index
            if (graph_type == GRAPH_ACCURACY && (result.song == null || result.replay_bin_notes == null))
                graph_type = GRAPH_COMBO;

            // Graph Toggle
            graphToggle.visible = (result.song != null);
            graphAccuracy.visible = (result.song != null);

            // Remove Old Graph
            if (activeGraph != null)
            {
                activeGraph.onStageRemove();
            }

            activeGraph = getGraph(graph_type, result);
            activeGraph.onStage(this);
            activeGraph.draw();
            activeGraph.drawOverlay(stage.mouseX - graphOverlay.x, stage.mouseY - graphOverlay.y);
        }

        /**
         * Gets the request graph object, either from cache of by creation.
         * @param graph_type Graph Type
         * @param result GameScoreResult
         * @return Graph Class
         */
        public function getGraph(graphType:int, result:GameScoreResult):GraphBase
        {
            var cacheId:String = graphType + "_" + resultIndex;

            // From Cache
            if (graphCache[cacheId] != null)
            {
                return graphCache[cacheId];
            }

            // Create New
            else
            {
                var newGraph:GraphBase;

                if (graphType == GRAPH_ACCURACY)
                {
                    newGraph = new GraphAccuracy(graphDraw, graphOverlay, result);
                }
                else
                {
                    newGraph = new GraphCombo(graphDraw, graphOverlay, result);
                }

                graphCache[cacheId] = newGraph;

                return newGraph;
            }
        }

        /**
         * Updates the active graph overlay with the current mouse coordinates
         * @param e
         */
        private function e_graphHover(e:MouseEvent):void
        {
            //trace(e.stageX - graphOverlay.x, e.stageY - graphOverlay.y); 
            if (activeGraph != null)
            {
                activeGraph.drawOverlay(e.stageX - graphOverlay.x, e.stageY - graphOverlay.y);
            }
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

        /**
         * Generates a score has that needs to be matched on the server for
         * a score to be considered valid.
         * @param result PostVars
         * @return SHA1 Hash
         */
        private function getSaveHash(result:Object):String
        {
            var dataSerial:String = "";
            dataSerial += "amazing:" + result.amazing + ",";
            dataSerial += "perfect:" + result.perfect + ",";
            dataSerial += "good:" + result.good + ",";
            dataSerial += "average:" + result.average + ",";
            dataSerial += "miss:" + result.miss + ",";
            dataSerial += "boo:" + result.boo + ",";
            dataSerial += "max_combo:" + result.max_combo + ",";
            dataSerial += "score:" + result.score + ",";
            dataSerial += "replay:" + result.replay + ",";
            dataSerial += "level:" + result.level + ",";
            dataSerial += "session:" + result.session + ",";
            dataSerial += "uid:" + _gvars.activeUser.siteId + ",";
            dataSerial += "ses:" + _gvars.activeUser.hash + ",";
            dataSerial += R3::HASH_STRING;
            return SHA1.hash(dataSerial);
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
            if (e.type == "keyDown" && !_mp.gameplayPlayingStatusResults())
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
                saveServerReplay();
            }

            else if (target == navScreenShot)
            {
                var ext:String = "";
                if (resultIndex >= 0)
                {
                    ext = songResults[resultIndex].screenshot_path;
                }
                _gvars.takeScreenShot(ext);
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

                if (!_gvars.options.replay || _gvars.flashvars.replay || _gvars.flashvars.preview_file)
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
                    addPopup(new PopupHighscores(this, songResults[resultIndex].songInfo));
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
                    _gvars.gameMain.addPopup(new PopupSongNotes(this, songResults[resultIndex].songInfo));
                }
            }

            else if (target == graphToggle)
            {
                if (resultIndex >= 0)
                {
                    graphType = (graphType + 1) % 2;
                    LocalStore.setVariable("result_graph_type", graphType);
                    drawResultGraph(songResults[resultIndex]);
                }
            }
        }

        /**
         * Adds the event listeners for the url loader.
         * @param completeHandler On Complete Handler
         * @param errorHandler On Error Handler
         */
        private function addLoaderListeners(completeHandler:Function, errorHandler:Function):void
        {
            _loader.addEventListener(Event.COMPLETE, completeHandler);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
        }

        /**
         * Removes the event listeners for the url loader.
         * @param completeHandler On Complete Handler
         * @param errorHandler On Error Handler
         */
        private function removeLoaderListeners(completeHandler:Function, errorHandler:Function):void
        {
            _loader.removeEventListener(Event.COMPLETE, completeHandler);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
        }

        //******************************************************************************************//
        // Score Saving
        //******************************************************************************************//

        /**
         * Calculates if a given score is valid and can be saved on the server. Depending on the flags,
         * this checks different criteria.
         * @param result GameScoreSeult to check.
         * @param valid_score Check for mods that aren't valid for highscore.
         * @param valid_replay Check for mods that aren't valid for replays.
         * @param check_replay Check if score was from a replay. Also checks for positive score.
         * @param check_alt_engine Check for Alt Engine. Also checks user isn't guest.
         * @return
         */
        private function canSendScore(result:GameScoreResult, valid_score:Boolean = true, valid_replay:Boolean = true, check_replay:Boolean = true, check_alt_engine:Boolean = true):Boolean
        {
            var ret:Boolean = false;
            ret ||= valid_score && !result.options.isScoreValid(true, false);
            ret ||= valid_replay && !result.options.isScoreValid(false, true);
            ret ||= check_replay && (_gvars.flashvars.replay || result.replayData.length <= 0 || result.score <= 0 || (result.options.replay && result.options.replay.isEdited) || result.user.siteId != _gvars.playerUser.siteId)
            ret ||= check_alt_engine && (result.user.isGuest || result.songInfo.engine != null);
            return !ret;
        }

        /**
         * Calculates if a given score is valid and can be updated on the server. Depending on the flags,
         * this checks different criteria. This slightly differents from the canSendScore as some mods
         * are allowed to be sent to the server that aren't recorded on the highscores like rates.
         * @param result GameScoreSeult to check.
         * @param valid_score Check for mods that aren't valid for highscore.
         * @param valid_replay Check for mods that aren't valid for replays.
         * @param check_replay Check if score was from a replay. Also checks for positive score.
         * @param check_alt_engine Check for Alt Engine. Also checks user isn't guest.
         * @return
         */
        private function canUpdateScore(result:GameScoreResult, valid_score:Boolean = true, valid_replay:Boolean = true, check_replay:Boolean = true, check_alt_engine:Boolean = true):Boolean
        {
            var ret:Boolean = false;
            ret ||= valid_score && !result.options.isScoreUpdated(true, false);
            ret ||= valid_replay && !result.options.isScoreUpdated(false, true);
            ret ||= check_replay && (_gvars.flashvars.replay || result.replayData.length <= 0 || result.score <= 0 || (result.options.replay && result.options.replay.isEdited) || result.user.siteId != _gvars.playerUser.siteId)
            ret ||= check_alt_engine && (result.user.isGuest || result.songInfo.engine != null);
            return !ret;
        }

        /**
         * Sends a post request to the last GameScoreREsult to the main highscore.
         * Will also call the `sendAltEngineScore()` itself if the score is from an alt engine.
         */
        private function sendScore():void
        {
            // Get last score
            var gameResult:GameScoreResult = songResults[songResults.length - 1];

            // Update Judge Offset
            updateJudgeOffset(gameResult);

            // Alt Engine Score
            if (gameResult.songInfo.engine)
            {
                sendAltEngineScore();
                return;
            }

            if (!canSendScore(gameResult, true, true, false, false))
            {
                Alert.add(_lang.string("game_result_error_enabled_mods"), 90, Alert.RED);
                return;
            }

            // Loader
            _loader = new DynamicURLLoader();
            addLoaderListeners(siteLoadComplete, siteLoadError);

            var req:URLRequest = new URLRequest(Constant.SONG_SAVE_URL);
            var scoreSender:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(scoreSender);

            // Post Game Data
            scoreSender.level = gameResult.level;
            scoreSender.update = canUpdateScore(gameResult, true, true, false, false);
            scoreSender.rate = gameResult.options.songRate;
            scoreSender.restarts = gameResult.restarts;
            scoreSender.accuracy = gameResult.accuracy_frames;
            scoreSender.amazing = gameResult.amazing;
            scoreSender.perfect = gameResult.perfect;
            scoreSender.good = gameResult.good;
            scoreSender.average = gameResult.average;
            scoreSender.miss = gameResult.miss;
            scoreSender.boo = gameResult.boo;
            scoreSender.max_combo = gameResult.max_combo;
            scoreSender.score = gameResult.score;
            scoreSender.replay = Replay.getReplayString(gameResult.replayData);
            scoreSender.save_settings = JSON.stringify(gameResult.options.settingsEncode());
            scoreSender.restart_stats = JSON.stringify(gameResult.restart_stats);
            scoreSender.session = _gvars.userSession;
            scoreSender.start_time = gameResult.start_time;
            scoreSender.start_hash = gameResult.start_hash;
            scoreSender.hashMap = getSaveHash(scoreSender);

            // Set Request
            req.data = scoreSender;
            req.method = URLRequestMethod.POST;

            // Saving Vars
            _loader.postData = ObjectUtil.clone(scoreSender);
            _loader.rank_index = _gvars.gameIndex;
            _loader.song = gameResult.songInfo;
            _loader.results = gameResult;
            _loader.load(req);
        }

        /**
         * Loader Event: Site Score Save Success
         */
        private function siteLoadComplete(e:Event):void
        {
            Logger.info(this, "Canon Data Loaded");
            removeLoaderListeners(siteLoadComplete, siteLoadError);

            // Parse Response
            var siteDataString:String = e.target.data;
            var data:Object;
            try
            {
                data = JSON.parse(siteDataString);
            }
            catch (err:Error)
            {
                Logger.error(this, "Canon Parse Failure: " + Logger.exception_error(err));
                Logger.error(this, "Wrote invalid response data to log folder. [logs/c_result.txt]");
                AirContext.writeTextFile(AirContext.getAppFile("logs/c_result.txt"), siteDataString);

                Alert.add(_lang.string("error_failed_to_save_results") + " (ERR: JSON_ERROR)", 360, Alert.RED);

                if (resultsDisplay != null)
                    resultsDisplay.result_rank.htmlText = "Score save failed!";

                return;
            }

            // Has Reponse
            var result:Object = e.target.postData;
            var songInfo:SongInfo = e.target.song;
            var gameResult:GameScoreResult = e.target.results;
            var totalScore:int = e.target.resultsTotal;
            Logger.debug(this, "Score Save Result: " + data.result);

            if (data.result == 0)
            {
                Alert.add(_lang.string("game_result_save_success"), 90, Alert.DARK_GREEN);

                // Server Message
                if (data.gServerMessage != null)
                {
                    Alert.add(data.gServerMessage, 360);
                }

                // Server Message Popup
                if (data.gServerMessageFull != null)
                {
                    _gvars.gameMain.addPopupQueue(new PopupMessage(this, data.gServerMessageFull, data.gServerMessageTitle ? data.gServerMessageTitle : ""));
                }

                // Token Unlock
                if (data.token_unlocks != null)
                {
                    for each (var token_item:Object in data.token_unlocks)
                    {
                        _gvars.gameMain.addPopupQueue(new PopupTokenUnlock(this, token_item.type, token_item.ID, token_item.text));
                        _gvars.unlockTokenById(token_item.type, token_item.ID);
                    }
                }
                else if (data.tUnlock != null)
                {
                    _gvars.gameMain.addPopupQueue(new PopupTokenUnlock(this, data.tType, data.tID, data.tText, data.tName, data.tMessage));
                    _gvars.unlockTokenById(data.tType, data.tID);
                }

                // Valid Legal Score
                if (result.update)
                {
                    // Check Old vs New Rankings.
                    if (data.new_ranking < data.old_ranking && data.old_ranking > 0)
                    {
                        Alert.add(sprintf(_lang.string("new_best_rank"), {"old": data.old_ranking, "new": data.new_ranking, "diff": ((data.old_ranking - data.new_ranking) * -1)}), 240, Alert.DARK_GREEN);
                    }

                    // Check raw score vs level ranks and update.
                    var previousLevelRanks:Object = _gvars.activeUser.level_ranks[songInfo.level];
                    var newLevelRanks:Object = {"genre": songInfo.genre,
                            "rank": data.new_ranking,
                            "score": gameResult.score,
                            "results": gameResult.pa_string + "-" + gameResult.max_combo,
                            "perfect": gameResult.amazing + gameResult.perfect,
                            "plays": 1,
                            "aaas": int(gameResult.is_aaa),
                            "fcs": int(gameResult.is_fc),
                            "good": gameResult.good,
                            "average": gameResult.average,
                            "miss": gameResult.miss,
                            "boo": gameResult.boo,
                            "maxcombo": gameResult.max_combo,
                            "rawscore": gameResult.score};

                    // Update Level Ranks is missing or better.
                    if (previousLevelRanks == null || gameResult.score > previousLevelRanks.score)
                    {
                        // Update Counts for Play, FC, AAA from previous.
                        if (previousLevelRanks != null)
                        {
                            newLevelRanks["plays"] += previousLevelRanks["plays"];
                            newLevelRanks["aaas"] += previousLevelRanks["aaas"];
                            newLevelRanks["fcs"] += previousLevelRanks["fcs"];
                        }
                        _gvars.activeUser.level_ranks[songInfo.level] = newLevelRanks;
                    }

                    // Update Counters
                    else
                    {
                        previousLevelRanks["plays"] += newLevelRanks["plays"];
                        previousLevelRanks["aaas"] += newLevelRanks["aaas"];
                        previousLevelRanks["fcs"] += newLevelRanks["fcs"];
                    }

                    _gvars.songResultRanks[e.target.rank_index] = {old_ranking: data.old_ranking, new_ranking: data.new_ranking};

                    // Update Rank Display if current score.
                    var gameIndex:int = (songResults.length == 1 ? e.target.rank_index : songRankIndex);
                    if (e.target.rank_index == gameIndex && resultsDisplay != null)
                    {
                        resultsDisplay.result_rank.htmlText = "<B>Rank: " + _gvars.songResultRanks[gameIndex].new_ranking;
                        resultsDisplay.result_last_best.htmlText = "<B>Last Best: " + _gvars.songResultRanks[gameIndex].old_ranking;
                    }
                }
                else
                {
                    resultsDisplay.result_rank.htmlText = "Game Mods";
                    resultsDisplay.result_last_best.htmlText = "Enabled";
                }

                _gvars.activeUser.grandTotal += gameResult.score_total;
                _gvars.activeUser.credits += gameResult.credits;

                Playlist.instanceCanon.updateSongAccess();

                // Display Popup Queue
                if (resultsDisplay != null)
                    _gvars.gameMain.displayPopupQueue();
            }
            else
            {
                if (resultsDisplay != null)
                {
                    resultsDisplay.result_rank.htmlText = data.ignore ? "" : "Score save failed!";
                    resultsDisplay.result_last_best.htmlText = data.ignore ? "" : "(ERR: " + data.result + ")";
                }
            }
        }

        /**
         * Loader Event: Site Score Save Failure
         */
        private function siteLoadError(e:ErrorEvent = null):void
        {
            Logger.error(this, "Canon Score Save Failure: " + Logger.event_error(e));
            removeLoaderListeners(siteLoadComplete, siteLoadError);
            Alert.add(_lang.string("error_server_connection_failure"), 120, Alert.RED);

            if (resultsDisplay != null)
                resultsDisplay.result_rank.htmlText = "Score save failed!";
        }

        //******************************************************************************************//
        // Alt Engine Score Saving
        //******************************************************************************************//

        /**
         * Sends a post request to saves score for alt engines. This shouldn't
         * be called directly and instead you shoulkd simple call `sendScore()`
         * which will call this is necessary.
         */
        private function sendAltEngineScore():void
        {
            // Get last score
            var gameResult:GameScoreResult = songResults[songResults.length - 1];

            if (!gameResult.songInfo.engine)
                return;

            // Update Local Alt Engine Levelranks
            if (((gameResult.legacyLastRank = _avars.legacyLevelRanksGet(gameResult.songInfo)) || {score: 0}).score < gameResult.score)
            {
                _avars.legacyLevelRanksSet(gameResult.songInfo, {"score": gameResult.score,
                        "rank": 0,
                        "perfect": gameResult.amazing + gameResult.perfect,
                        "good": gameResult.good,
                        "average": gameResult.average,
                        "miss": gameResult.miss,
                        "boo": gameResult.boo,
                        "maxcombo": gameResult.max_combo,
                        "rawscore": gameResult.score,
                        "results": gameResult.pa_string + "-" + gameResult.max_combo,
                        "arrows": gameResult.song.totalNotes});
                _avars.legacyLevelRanksSave();
            }

            // Loader
            _loader = new DynamicURLLoader();
            addLoaderListeners(altSiteLoadComplete, altSiteLoadError);

            var req:URLRequest = new URLRequest(Constant.ALT_SONG_SAVE_URL);
            var scoreSender:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(scoreSender);
            var sd:Object = {"arrows": gameResult.song.chart.Notes.length, // Playlist XML often lies.
                    "author": gameResult.songInfo.author,
                    "difficulty": gameResult.songInfo.difficulty,
                    "genre": gameResult.songInfo.genre,
                    "level": gameResult.songInfo.level,
                    "levelid": gameResult.songInfo.level_id,
                    "name": gameResult.songInfo.name,
                    "stepauthor": gameResult.songInfo.stepauthor,
                    "time": gameResult.songInfo.time};

            // Post Game Data
            var dataObject:Object = {};
            dataObject.engine = gameResult.songInfo.engine;
            dataObject.song_data = sd;
            dataObject.level = gameResult.level;
            dataObject.rate = gameResult.options.songRate;
            dataObject.restarts = gameResult.restarts;
            dataObject.accuracy = gameResult.accuracy_frames;
            dataObject.amazing = gameResult.amazing;
            dataObject.perfect = gameResult.perfect;
            dataObject.good = gameResult.good;
            dataObject.average = gameResult.average;
            dataObject.miss = gameResult.miss;
            dataObject.boo = gameResult.boo;
            dataObject.max_combo = gameResult.max_combo;
            dataObject.score = gameResult.score;
            dataObject.replay = gameResult.replay_bin_encoded;
            dataObject.save_settings = gameResult.options.settingsEncode();
            dataObject.session = _gvars.userSession;
            dataObject.hashMap = getSaveHash(dataObject);
            scoreSender.data = JSON.stringify(dataObject);
            scoreSender.session = _gvars.userSession;

            // Set Request
            req.data = scoreSender;
            req.method = URLRequestMethod.POST;

            // Saving Vars
            _loader.postData = ObjectUtil.clone(scoreSender);
            _loader.rank_index = _gvars.gameIndex;
            _loader.song = gameResult.songInfo;
            _loader.results = gameResult;
            _loader.load(req);
        }

        /**
         * Loader Event: Alt Engine Score Save Success
         */
        private function altSiteLoadComplete(e:Event):void
        {
            Logger.info(this, "Alt Data Loaded");
            removeLoaderListeners(altSiteLoadComplete, altSiteLoadError);

            // Parse Response
            var siteDataString:String = e.target.data;
            var data:Object;
            try
            {
                data = JSON.parse(siteDataString);
            }
            catch (err:Error)
            {
                Logger.error(this, "Alt Parse Failure: " + Logger.exception_error(err));
                Logger.error(this, "Wrote invalid response data to log folder. [logs/a_result.txt]");
                AirContext.writeTextFile(AirContext.getAppFile("logs/a_result.txt"), siteDataString);
                return;
            }

            // Has Reponse
            var result:Object = JSON.parse(e.target.postData.data);
            var songInfo:SongInfo = e.target.song;
            var totalScore:int = e.target.resultsTotal;
            var gameResult:GameScoreResult = e.target.results;

            Logger.debug(this, "Alt Score Save Result: " + data.result);

            if (data.result == 0)
            {
                // Server Message
                if (data.gServerMessage != null)
                {
                    Alert.add(data.gServerMessage, 360);
                }

                // Server Message Popup
                if (data.gServerMessageFull != null)
                {
                    _gvars.gameMain.addPopupQueue(new PopupMessage(this, data.gServerMessageFull, data.gServerMessageTitle ? data.gServerMessageTitle : ""));
                }

                // Token Unlock
                if (data.tUnlock != null)
                {
                    _gvars.gameMain.addPopupQueue(new PopupTokenUnlock(this, data.tType, data.tID, data.tText, data.tName, data.tMessage));
                }

                // Display Popup Queue
                if (resultsDisplay != null)
                {
                    _gvars.gameMain.displayPopupQueue();
                }
            }
        }

        /**
         * Loader Event: Alt Engine Score Save Failure
         */
        private function altSiteLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Alt Score Save Failure: " + Logger.event_error(err));
            removeLoaderListeners(altSiteLoadComplete, altSiteLoadError);
        }

        //******************************************************************************************//
        // Replay Saving
        //******************************************************************************************//

        /**
         * Saves a local replays to the session replays in the F2 menu.
         * This will also record the replay into a .txt file if
         * `Auto-Save Replays` is enabled in the settings screen.
         */
        private function saveLocalReplay():void
        {
            var result:GameScoreResult = songResults[songResults.length - 1];

            if (!canSendScore(result, true, false, true, false))
                return;

            var nR:Replay = new Replay(_gvars.gameIndex);
            nR.user = _gvars.playerUser;
            nR.level = result.songInfo.level;
            nR.settings = result.options.settingsEncode();
            if (result.songInfo.engine)
                nR.settings.arc_engine = _avars.legacyEncode(result.songInfo);
            nR.score = result.score;
            nR.perfect = (result.amazing + result.perfect);
            nR.good = result.good;
            nR.average = result.average;
            nR.miss = result.miss;
            nR.boo = result.boo;
            nR.maxcombo = result.max_combo;
            nR.replayData = result.replayData;
            nR.replayBin = result.replayBin;
            nR.timestamp = int(new Date().getTime() / 1000);
            nR.song = result.songInfo;
            _gvars.replayHistory.unshift(nR);

            // Display F2 Shortcut key only once per session.
            if (!Flags.VALUES[Flags.F2_REPLAYS])
            {
                Alert.add(_lang.string("replay_save_success"), 150);
                Flags.VALUES[Flags.F2_REPLAYS] = true;
            }

            // Write Local txt Replay Encode
            if (_gvars.air_autoSaveLocalReplays && result.replayBin != null)
            {
                try
                {
                    var path:String = AirContext.getReplayPath(result.song);
                    path += (result.song.songInfo.level_id ? result.song.songInfo.level_id : result.song.id.toString())
                    path += "_" + (new Date().getTime())
                    path += "_" + (result.pa_string + "-" + result.max_combo);
                    path += ".txt";

                    // Store Bin Encoded Replay
                    if (!AirContext.doesFileExist(path))
                    {
                        AirContext.writeTextFile(AirContext.getAppFile(path), nR.getEncode());

                        var cachePath:String = path.substr(Constant.REPLAY_PATH.length);
                        _gvars.file_replay_cache.setValue(cachePath, result.replay_cache_object);
                        _gvars.file_replay_cache.save();

                        ReplayHistoryTabLocal.REPLAYS.push(nR);
                    }
                }
                catch (err:Error)
                {
                    Logger.error(this, "Local Replay Save Error: " + Logger.exception_error(err));
                }
            }
        }

        /**
         * Sends a post for the replay of selected GameScoreResult.
         */
        private function saveServerReplay():void
        {
            var gameResult:GameScoreResult = songResults[resultIndex];

            // Loader
            _loader = new DynamicURLLoader();
            addLoaderListeners(replayLoadComplete, replayLoadError);

            var req:URLRequest = new URLRequest(Constant.USER_SAVE_REPLAY_URL);
            var scoreSender:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(scoreSender);

            // Post Game Data
            scoreSender.level = gameResult.level;
            scoreSender.update = canUpdateScore(gameResult, true, true, false, false);
            scoreSender.rate = gameResult.options.songRate;
            scoreSender.restarts = gameResult.restarts;
            scoreSender.accuracy = gameResult.accuracy_frames;
            scoreSender.amazing = gameResult.amazing;
            scoreSender.perfect = gameResult.perfect;
            scoreSender.good = gameResult.good;
            scoreSender.average = gameResult.average;
            scoreSender.miss = gameResult.miss;
            scoreSender.boo = gameResult.boo;
            scoreSender.max_combo = gameResult.max_combo;
            scoreSender.score = gameResult.score;
            scoreSender.replay = Replay.getReplayString(gameResult.replayData);
            scoreSender.replay_bin = gameResult.replay_bin_encoded;
            scoreSender.save_settings = JSON.stringify(gameResult.options.settingsEncode());
            scoreSender.session = _gvars.userSession;
            scoreSender.start_time = gameResult.start_time;
            scoreSender.start_hash = gameResult.start_hash;
            scoreSender.hash = SHA1.hash(scoreSender.replay + _gvars.activeUser.siteId);

            // Set Request
            req.data = scoreSender;
            req.method = URLRequestMethod.POST;

            // Saving Vars
            _loader.load(req);
        }

        /**
         * Loader Event: Replay Save Success
         */
        private function replayLoadComplete(e:Event):void
        {
            removeLoaderListeners(replayLoadComplete, replayLoadError);

            var data:Object = JSON.parse(e.target.data);

            Alert.add(_lang.string("replay_save_status_" + data.result), 90, (data.result == 0 ? Alert.GREEN : Alert.RED));
        }

        /**
         * Loader Event: Replay Save Failure
         */
        private function replayLoadError(e:Event = null):void
        {
            removeLoaderListeners(replayLoadComplete, replayLoadError);
            Alert.add(_lang.string("error_server_connection_failure"), 120, Alert.RED);
        }

    }
}
