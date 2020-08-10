package game
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerSingleton;
    import assets.results.ResultsBackground;
    import by.blooddy.crypto.SHA1;
    import classes.Alert;
    import classes.BoxButton;
    import classes.Language;
    import classes.Playlist;
    import classes.StarSelector;
    import classes.Text;
    import classes.replay.Replay;
    import com.flashfla.net.DynamicURLLoader;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.ObjectUtil;
    import com.flashfla.utils.TimeUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.Keyboard;
    import menu.MenuPanel;
    import popups.PopupHighscores;
    import popups.PopupMessage;
    import popups.PopupSongRating;
    import popups.PopupTokenUnlock;
    import game.graph.GraphBase;
    import game.graph.GraphCombo;
    import game.graph.GraphAccuracy;
    import classes.BoxIcon;
    import assets.menu.icons.fa.iconPhoto;
    import assets.menu.icons.fa.iconSave;
    import assets.menu.icons.fa.iconRandom;

    public class GameResults extends MenuPanel
    {
        public static const GRAPH_WIDTH:int = 718;
        public static const GRAPH_HEIGHT:int = 117;
        public static const GRAPH_COMBO:int = 0;
        public static const GRAPH_ACCURACY:int = 1;

        private var graph_cache:Object = {"0": {}, "1": {}};

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
        private var graphToggle:BoxButton;
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
            navOptions = new BoxButton(170, 40, _lang.string("game_results_menu_options"), 17);
            navOptions.addEventListener(MouseEvent.CLICK, eventHandler);
            buttonMenu.addChild(navOptions);
            buttonMenuItems.push(navOptions);

            navHighscores = new BoxButton(170, 40, _lang.string("game_results_menu_highscores"), 17);
            navHighscores.addEventListener(MouseEvent.CLICK, eventHandler);
            buttonMenu.addChild(navHighscores);
            buttonMenuItems.push(navHighscores);

            if (!_mp.gameplayPlayingStatus())
            {
                navReplay = new BoxButton(170, 40, _lang.string("game_results_menu_replay_song"), 17);
                navReplay.addEventListener(MouseEvent.CLICK, eventHandler);
                buttonMenu.addChild(navReplay);
                buttonMenuItems.push(navReplay);
            }

            if (!_gvars.flashvars.replay && !_gvars.flashvars.preview_file)
            {
                navMenu = new BoxButton(170, 40, _lang.string("game_results_menu_exit_menu"), 17);
                navMenu.addEventListener(MouseEvent.CLICK, eventHandler);
                buttonMenu.addChild(navMenu);
                buttonMenuItems.push(navMenu);
            }

            var BUTTON_GAP:int = 11;
            var BUTTON_WIDTH:int = (735 - (Math.max(0, (buttonMenuItems.length - 1)) * BUTTON_GAP)) / buttonMenuItems.length;
            for (var bx:int = 0; bx < buttonMenuItems.length; bx++)
            {
                buttonMenuItems[bx].width = BUTTON_WIDTH;
                buttonMenuItems[bx].x = BUTTON_WIDTH * bx + BUTTON_GAP * bx;
            }

            // Star Rating Button
            navRating = new Sprite();
            navRating.buttonMode = true;
            navRating.mouseChildren = false;
            navRating.addEventListener(MouseEvent.CLICK, eventHandler);
            resultsDisplay.addChild(navRating);

            // Song Results Buttons
            navScreenShot = new BoxIcon(32, 32, new iconPhoto());
            navScreenShot.x = 522;
            navScreenShot.y = 6;
            navScreenShot.setIconColor("#E2FEFF");
            navScreenShot.setHoverText(_lang.string("game_results_queue_save_screenshot"), "bottom");
            navScreenShot.addEventListener(MouseEvent.CLICK, eventHandler);
            this.addChild(navScreenShot);


            navSaveReplay = new BoxIcon(32, 32, new iconSave());
            navSaveReplay.x = 485;
            navSaveReplay.y = 6;
            navSaveReplay.setIconColor("#E2FEFF");
            navSaveReplay.setHoverText(_lang.string("game_results_queue_save_replay"), "bottom");
            navSaveReplay.addEventListener(MouseEvent.CLICK, eventHandler);
            this.addChild(navSaveReplay);

            navRandomSong = new BoxIcon(32, 32, new iconRandom());
            navRandomSong.x = 448;
            navRandomSong.y = 6;
            navRandomSong.setIconColor("#E2FEFF");
            navRandomSong.setHoverText(_lang.string("game_results_play_random_song"), "bottom");
            navRandomSong.addEventListener(MouseEvent.CLICK, eventHandler);
            this.addChild(navRandomSong);

            navPrev = new BoxButton(90, 32, _lang.string("game_results_queue_previous"));
            navPrev.x = 18;
            navPrev.y = 62;
            navPrev.addEventListener(MouseEvent.CLICK, eventHandler);
            this.addChild(navPrev);

            navNext = new BoxButton(90, 32, _lang.string("game_results_queue_next"));
            navNext.x = 672;
            navNext.y = 62;
            navNext.addEventListener(MouseEvent.CLICK, eventHandler);
            this.addChild(navNext);

            resultsMods = new Text("---");
            resultsMods.x = 18;
            resultsMods.y = 276;
            this.addChild(resultsMods);

            graphDraw = new Sprite();
            graphDraw.x = 30;
            graphDraw.y = 298;
            this.addChild(graphDraw);

            graphOverlay = new Sprite();
            graphOverlay.x = 30;
            graphOverlay.y = 298;
            this.addChild(graphOverlay);

            graphToggle = new BoxButton(17, 19, "&gt;");
            graphToggle.x = 10;
            graphToggle.y = 297;
            graphToggle.addEventListener(MouseEvent.CLICK, eventHandler);
            this.addChild(graphToggle);

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
            if (navScreenShot)
                navScreenShot.enabled = false;
            if (navSaveReplay)
                navSaveReplay.enabled = false;
            if (navPrev)
                navPrev.visible = false;
            if (navNext)
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
            var song_entry:Object;
            var songTitle:String = "";
            var songSubTitle:String = "";

            var scoreTotal:int = 0;
            var scoreCredits:int = 0;

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
                    song_entry = tempResult.song_entry;
                    songSubTitle += song_entry.name + ", ";
                    result.note_count += tempResult.note_count;
                    result.amazing += tempResult.amazing;
                    result.perfect += tempResult.perfect;
                    result.good += tempResult.good;
                    result.average += tempResult.average;
                    result.miss += tempResult.miss;
                    result.boo += tempResult.boo;
                    result.score += tempResult.score;

                    // Replay Graph
                    for (var y:int = 0; y < tempResult.replay_hit.length; y++)
                        result.replay_hit.push(tempResult.replay_hit[y]);

                    // Score Total
                    scoreTotal += tempResult.total;

                    // Credits
                    scoreCredits += calculateCredits(tempResult.total);
                }
                result.updateJudge();

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
                song_entry = result.song_entry;

                var seconds:Number = Math.floor(song_entry.timeSecs * (1 / result.options.songRate));
                var songLength:String = (Math.floor(seconds / 60)) + ":" + (seconds % 60 >= 10 ? "" : "0") + (seconds % 60);
                var rateString:String = result.options.songRate != 1 ? " (" + result.options.songRate + "x Rate)" : "";

                // Song Title
                songTitle = song_entry.engine ? song_entry.name + rateString : "<a href=\"" + Constant.LEVEL_STATS_URL + song_entry.level + "\">" + song_entry.name + rateString + "</a>";
                songSubTitle = sprintf(_lang.string("game_results_subtitle_difficulty"), {"value": song_entry.difficulty}) + " - " + sprintf(_lang.string("game_results_subtitle_length"), {"value": songLength});
                if (song_entry.author != "")
                    songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_author"), {"value": song_entry.authorwithurl}));
                if (song_entry.stepauthor != "")
                    songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_stepauthor"), {"value": song_entry.stepauthorwithurl}));

                displayTime = result.endtime;
                scoreTotal = result.total;
                scoreCredits += calculateCredits(scoreTotal);

                // Star
                navRating.visible = false;
                if (resultIndex >= 0)
                {
                    navRating.graphics.clear();
                    StarSelector.drawStar(navRating.graphics, 18, 0, 0, (_gvars.playerUser.getSongRating(result.song_entry.level) != 0), 0xF2D60D, 1);
                }

                // Cached Rank Index
                songRankIndex = result.game_index + 1;

                // Save Replay Button
                navSaveReplay.enabled = true;
                if (!canSendScore(result, true, false, true, true) || _gvars.flashvars.preview_file)
                {
                    navSaveReplay.enabled = false;
                }

                // Display Song Rating Popup
                if ((result.songprogress > 0.25 || result.playtime_secs >= 30) && !result.options.replay)
                    navRating.visible = true;
            }

            // Save Screenshot
            if (!_gvars.flashvars.preview_file)
                navScreenShot.enabled = true;

            // Random Song Button
            if (result.options.replay || _gvars.flashvars.preview_file || _mp.gameplayPlayingStatus())
                navRandomSong.enabled = false;

            // Skill rating
            var raw_goods:Number = zRanking.getRawGoods(result);
            var song_weight:Number = zRanking.getSongWeight(song_entry, result);
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
            resultsDisplay.result_credits.htmlText = "<B>" + scoreCredits + "</B>";
            resultsDisplay.result_rawgoods.htmlText = "<B>" + NumberUtil.numberFormat(raw_goods, 1, true) + "</B>";
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
            else if (result.song_entry && result.song_entry.engine)
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
            else if (!result.options.replay && gameIndex != -1)
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
            if (_gvars.flashvars.preview_file)
            {
                resultsDisplay.results_username.htmlText = "<B>Song Preview:</B>";
                resultsDisplay.result_credits.htmlText = "<B>0</B>";
                navRating.visible = false;
            }

            // Mod Text
            resultsMods.text = "Scroll Speed: " + result.options.scrollSpeed;
            if (result.restarts > 0)
                resultsMods.text += ", Restarts: " + result.restarts;
            var mods:Array = new Array();
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
                var arcMenu:ContextMenu = new ContextMenu();
                var arcItem:ContextMenuItem = new ContextMenuItem("Accuracy: " + (result.accuracy_frames.toFixed(3)) + " (±" + result.accuracy_deviation_frames.toFixed(3) + ")");
                arcMenu.customItems.push(arcItem);
                resultsMods.contextMenu = arcMenu;
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

            // Remove Old Graph
            if (activeGraph != null)
            {
                activeGraph.onStageRemove();
            }

            activeGraph = getGraph(graph_type, result);
            activeGraph.onStage(this);
            activeGraph.draw();
        }

        /**
         * Gets the request graph object, either from cache of by creation.
         * @param graph_type Graph Type
         * @param result GameScoreResult
         * @return Graph Class
         */
        public function getGraph(graph_type:int, result:GameScoreResult):GraphBase
        {
            var cache_id:String = graph_type + "_" + resultIndex;

            // From Cache
            if (graph_cache[cache_id] != null)
            {
                return graph_cache[cache_id];
            }

            // Create New
            else
            {
                var new_graph:GraphBase;

                if (graph_type == GRAPH_ACCURACY)
                {
                    new_graph = new GraphAccuracy(graphDraw, graphOverlay, result);
                }
                else
                {
                    new_graph = new GraphCombo(graphDraw, graphOverlay, result);
                }

                graph_cache[cache_id] = new_graph;

                return new_graph;
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
        private function updateJudgeOffset(result:Object):void
        {
            if (_gvars.activeUser.AUTO_JUDGE_OFFSET && // Auto Judge Offset enabled 
                (result.amazing + result.perfect + result.good + result.average >= 50) && // Accuracy data is reliable
                result.accuracy !== 0)
            {
                _gvars.activeUser.JUDGE_OFFSET = result.accuracy.toFixed(3);
                // Save settings
                _gvars.activeUser.saveLocal();
                _gvars.activeUser.save();
            }
        }

        /**
         * Calculate the credits earned for the given total score.
         * Caps at 0 and site provided max credits.
         * @param total_score
         * @return int
         */
        private function calculateCredits(total_score:int):int
        {
            return Math.max(0, Math.min(Math.floor(total_score / _gvars.SCORE_PER_CREDIT), _gvars.MAX_CREDITS));
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
            dataSerial += "uid:" + _gvars.activeUser.id + ",";
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
            if (target == navSaveReplay && navSaveReplay.enabled)
            {
                saveServerReplay();
            }
            else if (target == navScreenShot && navScreenShot.enabled)
            {
                var ext:String = "";
                if (resultIndex >= 0)
                {
                    ext = songResults[resultIndex].screenshot_path;
                }
                _gvars.takeScreenShot(ext);
            }
            else if (target == navPrev && navPrev.visible)
            {
                displayGameResult(resultIndex - 1);
            }
            else if (target == navNext && navNext.visible)
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

            else if (target == navRandomSong && navRandomSong.enabled)
            {
                var songList:Array = _playlist.playList;
                var selectedSong:Object;

                //Check for filters and filter the songs list
                if (_gvars.activeFilter != null)
                {
                    songList = _playlist.indexList.filter(function(item:Object, index:int, array:Array):Boolean
                    {
                        return _gvars.activeFilter.process(item, _gvars.activeUser);
                    });
                }

                // Filter to only Playable Songs
                songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
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
                if (songResults[resultIndex])
                {
                    addPopup(new PopupHighscores(this, songResults[resultIndex].song_entry));
                }
            }
            else if (target == navMenu)
            {
                switchTo(Main.GAME_MENU_PANEL);
            }
            else if (target == navRating)
            {
                if (songResults[resultIndex])
                {
                    _gvars.gameMain.addPopup(new PopupSongRating(this, songResults[resultIndex]["song"]));
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
            ret ||= check_replay && (_gvars.flashvars.replay || result.replay.length <= 0 || result.score <= 0 || (result.options.replay && result.options.replay.isEdited) || result.user.id != _gvars.playerUser.id)
            ret ||= check_alt_engine && (result.user.id <= 2 || result.song_entry.engine != null);
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
            ret ||= check_replay && (_gvars.flashvars.replay || result.replay.length <= 0 || result.score <= 0 || (result.options.replay && result.options.replay.isEdited) || result.user.id != _gvars.playerUser.id)
            ret ||= check_alt_engine && (result.user.id <= 2 || result.song_entry.engine != null);
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

            // Alt Engine Score
            if (gameResult.song_entry.engine)
            {
                sendAltEngineScore();
                return;
            }

            if (!canSendScore(gameResult, true, true, false, false))
            {
                _gvars.gameMain.addAlert(_lang.string("game_result_error_enabled_mods"), 90, Alert.RED);
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
            scoreSender.replay = Replay.getReplayString(gameResult.replay);
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
            _loader.song = gameResult.song_entry;
            _loader.resultsString = (scoreSender.amazing + scoreSender.perfect) + "-" + scoreSender.good + "-" + scoreSender.average + "-" + scoreSender.miss + "-" + scoreSender.boo + "-" + scoreSender.max_combo;
            _loader.resultsTotal = ((scoreSender.amazing + scoreSender.perfect) * 500) + (scoreSender.good * 250) + (scoreSender.average * 50) + (scoreSender.max_combo * 1000) - (scoreSender.miss * 300) - (scoreSender.boo * 15) + Math.floor(scoreSender.score);
            _loader.load(req);
        }

        /**
         * Loader Event: Site Score Save Success
         */
        private function siteLoadComplete(e:Event):void
        {
            removeLoaderListeners(siteLoadComplete, siteLoadError);

            var result:Object = e.target.postData;
            var data:Object = JSON.parse(e.target.data);
            var song:Object = e.target.song;
            var totalScore:int = e.target.resultsTotal;

            if (data.result == 0)
            {
                _gvars.gameMain.addAlert(_lang.string("game_result_save_success"), 90, Alert.DARK_GREEN);

                // Server Message
                if (data.gServerMessage != null)
                {
                    _gvars.gameMain.addAlert(data.gServerMessage, 360);
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
                        _gvars.gameMain.addAlert("New Best Rank: " + data.old_ranking + "->" + data.new_ranking + " (" + ((data.old_ranking - data.new_ranking) * -1) + ")", 240, Alert.DARK_GREEN);
                    }

                    // Check raw score vs level ranks and update.
                    if (_gvars.activeUser.level_ranks[song.level] == null || result.score > _gvars.activeUser.level_ranks[song.level].score)
                    {
                        _gvars.activeUser.level_ranks[song.level] = {"genre": song.genre,
                                "rank": data.new_ranking,
                                "score": result.score,
                                "results": e.target.resultsString,
                                "perfect": result.amazing + result.perfect,
                                "good": result.good,
                                "average": result.average,
                                "miss": result.miss,
                                "boo": result.boo,
                                "maxcombo": result.max_combo,
                                "rawscore": result.score};
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
                    resultsDisplay.result_rank.htmlText = "Game mods enabled!";
                }

                _gvars.activeUser.grandTotal += Math.max(0, totalScore);
                _gvars.activeUser.credits += calculateCredits(Math.max(0, totalScore));

                Playlist.instanceCanon.updateSongAccess();

                // Update Judge Offset
                updateJudgeOffset(result);

                // Display Popup Queue
                if (resultsDisplay != null)
                {
                    _gvars.gameMain.displayPopupQueue();
                }
            }
            else
            {
                if (!data.ignore)
                    _gvars.gameMain.addAlert("Failed to save results. (ERR: " + data.result + ")", 360, Alert.RED);

                if (resultsDisplay != null)
                    resultsDisplay.result_rank.htmlText = data.ignore ? "" : "Score save failed!";
            }
        }

        /**
         * Loader Event: Site Score Save Failure
         */
        private function siteLoadError(e:Event = null):void
        {
            removeLoaderListeners(siteLoadComplete, siteLoadError);
            _gvars.gameMain.addAlert(_lang.string("error_server_connection_failure"), 120, Alert.RED);

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

            if (!gameResult.song_entry.engine)
                return;

            // Update Local Alt Engine Levelranks
            if (((gameResult.legacyLastRank = _avars.legacyLevelRanksGet(gameResult.song_entry)) || {score: 0}).score < gameResult.score)
            {
                _avars.legacyLevelRanksSet(gameResult.song_entry, {score: gameResult.score,
                        rank: 0,
                        perfect: gameResult.amazing + gameResult.perfect,
                        good: gameResult.good,
                        average: gameResult.average,
                        miss: gameResult.miss,
                        boo: gameResult.boo,
                        maxcombo: gameResult.max_combo,
                        rawscore: gameResult.score,
                        results: (gameResult.amazing + gameResult.perfect) + "-" + gameResult.good + "-" + gameResult.average + "-" + gameResult.miss + "-" + gameResult.boo + "-" + gameResult.max_combo,
                        arrows: gameResult.song.totalNotes});
                _avars.legacyLevelRanksSave();
            }

            // Loader
            _loader = new DynamicURLLoader();
            addLoaderListeners(altSiteLoadComplete, altSiteLoadError);

            var req:URLRequest = new URLRequest(Constant.ALT_SONG_SAVE_URL);
            var scoreSender:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(scoreSender);
            var sd:Object = {"arrows": gameResult.song.chart.Notes.length, // Playlist XML often lies.
                    "author": gameResult.song_entry.author,
                    "difficulty": gameResult.song_entry.difficulty,
                    "genre": gameResult.song_entry.genre,
                    "level": gameResult.song_entry.level,
                    "levelid": gameResult.song_entry.levelid,
                    "name": gameResult.song_entry.name,
                    "stepauthor": gameResult.song_entry.stepauthor,
                    "time": gameResult.song_entry.time};

            // Post Game Data
            var dataObject:Object = {};
            dataObject.engine = gameResult.song_entry.engine;
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
            _loader.song = gameResult.song_entry;
            _loader.load(req);
        }

        /**
         * Loader Event: Alt Engine Score Save Success
         */
        private function altSiteLoadComplete(e:Event):void
        {
            removeLoaderListeners(altSiteLoadComplete, altSiteLoadError);
            try
            {
                var result:Object = JSON.parse(e.target.postData.data);
                var song:Object = e.target.song;
                var totalScore:int = e.target.resultsTotal;
                var data:Object = JSON.parse(e.target.data);
                if (data)
                {
                    if (data.result == 0)
                    {
                        //_gvars.gameMain.addAlert("Score Saved successfully!", 90);

                        // Server Message
                        if (data.gServerMessage != null)
                        {
                            _gvars.gameMain.addAlert(data.gServerMessage, 360);
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

                        // Update Judge Offset
                        updateJudgeOffset(result);

                        // Display Popup Queue
                        if (resultsDisplay != null)
                        {
                            _gvars.gameMain.displayPopupQueue();
                        }
                    }
                }
            }
            catch (e:Error)
            {
            }
        }

        /**
         * Loader Event: Alt Engine Score Save Failure
         */
        private function altSiteLoadError(e:Event = null):void
        {
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
            nR.level = result.song_entry.level;
            nR.settings = result.options.settingsEncode();
            if (result.song_entry.engine)
                nR.settings.arc_engine = _avars.legacyEncode(result.song_entry);
            nR.score = result.score;
            nR.perfect = (result.amazing + result.perfect);
            nR.good = result.good;
            nR.average = result.average;
            nR.miss = result.miss;
            nR.boo = result.boo;
            nR.maxcombo = result.max_combo;
            nR.replay = result.replay;
            nR.replay_bin = result.replay_bin;
            nR.timestamp = int(new Date().getTime() / 1000);
            _gvars.replayHistory.unshift(nR);

            // Display F2 Shortcut key only once per session.
            if (!Flags.VALUES[Flags.F2_REPLAYS])
            {
                _gvars.gameMain.addAlert("Replay saved to History. (Press F2)", 150);
                Flags.VALUES[Flags.F2_REPLAYS] = true;
            }

            // Write Local txt Replay Encode
            if (_gvars.air_autoSaveLocalReplays && result.replay_bin != null)
            {
                try
                {
                    var path:String = AirContext.getReplayPath(result.song);
                    path += (result.song.entry.levelid != null ? result.song.entry.levelid : result.song.id.toString())
                    path += "_" + (new Date().getTime())
                    path += "_" + (result.pa_string + "-" + result.max_combo);

                    var fileStream:FileStream;

                    // Store Bin Encoded Replay
                    if (!AirContext.doesFileExist(path + ".txt"))
                    {
                        var replayFileText:File = new File(AirContext.getAppPath(path + ".txt"));
                        fileStream = new FileStream();
                        fileStream.open(replayFileText, FileMode.WRITE);
                        fileStream.writeUTFBytes(nR.getEncode());
                        fileStream.close();
                    }
                }
                catch (e:Error)
                {
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

            var req:URLRequest = new URLRequest(Constant.USER_REPLAY_URL);
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
            scoreSender.replay = Replay.getReplayString(gameResult.replay);
            scoreSender.replay_bin = gameResult.replay_bin_encoded;
            scoreSender.save_settings = JSON.stringify(gameResult.options.settingsEncode());
            scoreSender.session = _gvars.userSession;
            scoreSender.start_time = gameResult.start_time;
            scoreSender.start_hash = gameResult.start_hash;
            scoreSender.hash = SHA1.hash(scoreSender.replay + _gvars.activeUser.id);

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

            _gvars.gameMain.addAlert(_lang.string("replay_save_status_" + data.result), 90, (data.result == 0 ? Alert.GREEN : Alert.RED));
        }

        /**
         * Loader Event: Replay Save Failure
         */
        private function replayLoadError(e:Event = null):void
        {
            removeLoaderListeners(replayLoadComplete, replayLoadError);
            _gvars.gameMain.addAlert(_lang.string("error_server_connection_failure"), 120, Alert.RED);
        }

    }
}
