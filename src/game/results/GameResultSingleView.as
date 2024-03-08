package game.results
{
    import assets.menu.icons.fa.iconRight;
    import assets.menu.icons.fa.iconSmallT;
    import assets.results.ResultsBackground;
    import classes.Language;
    import classes.SongInfo;
    import classes.score.ScoreHandler;
    import classes.score.ScoreHandlerEvent;
    import classes.ui.BoxIcon;
    import classes.ui.Text;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.TimeUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLRequest;
    import game.GameScoreResult;
    import game.SkillRating;
    import game.graph.GraphAccuracy;
    import game.graph.GraphAccuracyPrecise;
    import game.graph.GraphAccuracyPrecise2;
    import game.graph.GraphBase;
    import game.graph.GraphCombo;

    public class GameResultSingleView extends Sprite
    {
        public static const GRAPH_WIDTH:int = 718;
        public static const GRAPH_HEIGHT:int = 117;
        public static const GRAPH_COMBO:int = 0;
        public static const GRAPH_ACCURACY:int = 1;
        public static const GRAPH_ACCURACY_PRECISE:int = 2;
        public static const GRAPH_ACCURACY_PRECISE2:int = 3;

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _score:ScoreHandler = ScoreHandler.instance;

        private var resultsDisplay:ResultsBackground;
        private var result:GameScoreResult;

        private var graphCache:Object = {"0": {}, "1": {}, "2": {}, "3": {}};

        private var bgImage:Bitmap;
        private var userAvatar:DisplayObject;

        // Title Bar
        private var resultsTime:String = TimeUtil.getCurrentDate();
        private var header:Text;
        private var time:Text;

        // Game Result
        public var songName:Text;
        public var songDecription:Text;

        private var textAmazing:Text;
        private var textPerfect:Text;
        private var textGood:Text;
        private var textAverage:Text;
        private var textMiss:Text;
        private var textBoo:Text;
        private var valueAmazing:Text;
        private var valuePerfect:Text;
        private var valueGood:Text;
        private var valueAverage:Text;
        private var valueMiss:Text;
        private var valueBoo:Text;

        private var textAAAeq:Text;
        private var textRawGoods:Text;
        private var textRawScore:Text;
        private var textGrandtotal:Text;
        private var textMaxCombo:Text;
        private var textCredits:Text;
        private var valueAAAeq:Text;
        private var valueRawGoods:Text;
        private var valueRawScore:Text;
        private var valueGrandtotal:Text;
        private var valueMaxCombo:Text;
        private var valueCredits:Text;

        private var currentRank:Text;
        private var lastRank:Text;
        private var scoreHash:Text;

        private var resultsMods:Text;

        // Graph
        private var graphType:int = 0;
        private var graphToggle:BoxIcon;
        private var graphAccuracy:BoxIcon;
        private var activeGraph:GraphBase;
        private var graphDraw:Sprite;
        private var graphOverlay:Sprite;
        private var graphOverlayText:Text;

        public function GameResultSingleView():void
        {
            // Background
            resultsDisplay = new ResultsBackground();
            this.addChild(resultsDisplay);

            // Get Graph Type
            graphType = LocalStore.getVariable("result_graph_type", 0);

            // Text
            header = new Text(this, 20, 8, "", 16, "#E2FEFF");
            header.setAreaParams(420, 26);

            time = new Text(this, 576, 8, "", 16, "#E2FEFF");
            time.setAreaParams(196, 26, "center");

            songName = new Text(this, 115, 56, "If you see this, something broke.", 16, "#E2FEFF");
            songName.setAreaParams(545, 30, "center");
            songName.mouseChildren = true;
            songName.mouseEnabled = true;

            songDecription = new Text(this, 115, 83, "Which isn't good. Anyways Hello!", 12, "#E2FEFF");
            songDecription.textfield.styleSheet = Constant.STYLESHEET;
            songDecription.setAreaParams(545, 20, "center");
            songDecription.mouseChildren = true;
            songDecription.mouseEnabled = true;

            textAmazing = new Text(this, 15, 115, _lang.string("results_amazing"), 14, "#79F02A");
            textAmazing.setAreaParams(104, 24, "right");
            textPerfect = new Text(this, 15, 143, _lang.string("results_perfect"), 14, "#12FF00");
            textPerfect.setAreaParams(104, 24, "right");
            textGood = new Text(this, 15, 170, _lang.string("results_good"), 14, "#00AD0F");
            textGood.setAreaParams(104, 24, "right");
            textAverage = new Text(this, 15, 196, _lang.string("results_average"), 14, "#FF9A00");
            textAverage.setAreaParams(104, 24, "right");
            textMiss = new Text(this, 15, 223, _lang.string("results_miss"), 14, "#FF0000");
            textMiss.setAreaParams(104, 24, "right");
            textBoo = new Text(this, 15, 249, _lang.string("results_boo"), 14, "#874300");
            textBoo.setAreaParams(104, 24, "right");

            valueAmazing = new Text(this, 122, 114, "", 19, "#DCFFCB");
            valueAmazing.setAreaParams(130, 28);
            valuePerfect = new Text(this, 122, 141, "", 18, "#C1FFBD");
            valuePerfect.setAreaParams(130, 28);
            valueGood = new Text(this, 122, 167, "", 17, "#BCE9C1");
            valueGood.setAreaParams(130, 28);
            valueAverage = new Text(this, 122, 193, "", 17, "#FFEFD7");
            valueAverage.setAreaParams(130, 28);
            valueMiss = new Text(this, 122, 219, "", 17, "#FFE0E0");
            valueMiss.setAreaParams(130, 28);
            valueBoo = new Text(this, 122, 246, "", 17, "#E7D0B8");
            valueBoo.setAreaParams(130, 28);

            textAAAeq = new Text(this, 257, 113, _lang.string("results_aaaeq"), 14, "#B1E8EA");
            textAAAeq.setAreaParams(148, 24, "right");
            textRawGoods = new Text(this, 258, 139, _lang.string("results_raw_goods"), 14, "#B1E8EA");
            textRawGoods.setAreaParams(148, 24, "right");
            textRawScore = new Text(this, 257, 167, _lang.string("results_raw_score"), 14, "#B1E8EA");
            textRawScore.setAreaParams(148, 24, "right");
            textGrandtotal = new Text(this, 257, 194, _lang.string("results_grandtotal"), 14, "#B1E8EA");
            textGrandtotal.setAreaParams(148, 24, "right");
            textMaxCombo = new Text(this, 257, 221, _lang.string("results_max_combo"), 14, "#B1E8EA");
            textMaxCombo.setAreaParams(148, 24, "right");
            textCredits = new Text(this, 257, 248, _lang.string("results_credits"), 14, "#B1E8EA");
            textCredits.setAreaParams(148, 24, "right");

            valueAAAeq = new Text(this, 408, 111, "0", 16, "#FFFFFF");
            valueAAAeq.setAreaParams(130, 28);
            valueRawGoods = new Text(this, 408, 138, "0", 16, "#FFFFFF");
            valueRawGoods.setAreaParams(130, 28);
            valueRawScore = new Text(this, 408, 165, "0", 16, "#FFFFFF");
            valueRawScore.setAreaParams(130, 28);
            valueGrandtotal = new Text(this, 408, 192, "0", 16, "#FFFFFF");
            valueGrandtotal.setAreaParams(130, 28);
            valueMaxCombo = new Text(this, 408, 219, "0", 16, "#FFFFFF");
            valueMaxCombo.setAreaParams(130, 28);
            valueCredits = new Text(this, 408, 246, "0", 16, "#FFFFFF");
            valueCredits.setAreaParams(130, 28);

            currentRank = new Text(this, 575, 220, "", 15, "#FFFFFF");
            currentRank.setAreaParams(180, 28, "center");
            lastRank = new Text(this, 575, 248, "", 14, "#FFFFFF");
            lastRank.setAreaParams(180, 28, "center");

            resultsMods = new Text(this, 18, 276, "---");
            scoreHash = new Text(this, 18, 276, "");
            scoreHash.setAreaParams(750, 22, "right");
            scoreHash.alpha = 0.03;

            // Graph
            resultsDisplay.grid.visible = false;

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
        }

        public function onScoreResult(e:ScoreHandlerEvent):void
        {
            if (result == e.result)
            {
                currentRank.text = e.rank;
                lastRank.text = e.last_best;
                scoreHash.text = e.hash;
            }
        }

        public function update(result:GameScoreResult):void
        {
            this.result = result;

            // Variables
            var skillLevel:String = (result.user != null) ? ("[Lv." + result.user.skillLevel + "]" + " ") : "";
            var displayTime:String = "";
            var songInfo:SongInfo = result.songInfo;
            var songTitle:String = "";
            var songSubTitle:String = "";
            var canScoreSave:Boolean = _score.canSendScore(result, true, true, false, false);

            // Queue Total
            if (result.game_index == -1)
            {
                songTitle = sprintf(_lang.string("game_results_total_songs"), {"total": NumberUtil.numberFormat(songInfo.order)});
                songSubTitle = songInfo.name;
                displayTime = resultsTime;
            }
            else
            {
                var seconds:Number = Math.floor(songInfo.time_secs * (1 / result.options.songRate));
                var songLength:String = (Math.floor(seconds / 60)) + ":" + (seconds % 60 >= 10 ? "" : "0") + (seconds % 60);
                var rateString:String = result.options.songRate != 1 ? sprintf(_lang.string("results_rate"), {value: result.options.songRate}) : "";

                // Song Title
                songTitle = songInfo.engine ? songInfo.name + rateString : "<a href=\"" + URLs.resolve(URLs.LEVEL_STATS_URL) + songInfo.level + "\">" + songInfo.name + rateString + "</a>";
                songSubTitle = sprintf(_lang.string("game_results_subtitle_difficulty"), {"value": songInfo.difficulty}) + " - " + sprintf(_lang.string("game_results_subtitle_length"), {"value": songLength});
                if (songInfo.author != "")
                    songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_author"), {"value": songInfo.author_html}));
                if (songInfo.stepauthor != "")
                    songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_stepauthor"), {"value": songInfo.stepauthor_html}));

                displayTime = result.end_time;
            }

            // Local Backgrounds
            if (bgImage)
            {
                removeChild(bgImage);
                bgImage = null;
            }

            addBackgroundImage();

            // Avatar
            if (userAvatar)
            {
                removeChild(userAvatar);
                userAvatar = null;
            }

            if (result.user)
            {
                userAvatar = result.user.avatar;
                if (userAvatar && userAvatar.height > 0 && userAvatar.width > 0)
                {
                    userAvatar.x = 616 + ((99 - userAvatar.width) / 2);
                    userAvatar.y = 114 + ((99 - userAvatar.height) / 2);
                    addChild(userAvatar);
                }
                else
                    userAvatar = null;
            }

            // Skill rating
            var song_weight:Number = SkillRating.getSongWeight(result);
            if (result.last_note > 0)
                song_weight = 0;

            // Text
            header.text = sprintf(_lang.string(result.options.replay ? "results_header_replay" : "results_header_play"), {name: skillLevel + result.user.name});
            time.text = displayTime;
            songName.text = songTitle;
            songDecription.text = songSubTitle;

            valueAmazing.text = NumberUtil.numberFormat(result.amazing);
            valuePerfect.text = NumberUtil.numberFormat(result.perfect);
            valueGood.text = NumberUtil.numberFormat(result.good);
            valueAverage.text = NumberUtil.numberFormat(result.average);
            valueMiss.text = NumberUtil.numberFormat(result.miss);
            valueBoo.text = NumberUtil.numberFormat(result.boo);

            valueAAAeq.text = NumberUtil.numberFormat(song_weight, 2, true);
            valueRawScore.text = NumberUtil.numberFormat(result.score);
            valueRawGoods.text = NumberUtil.numberFormat(result.raw_goods, 1, true);
            valueGrandtotal.text = NumberUtil.numberFormat(result.score_total);
            valueMaxCombo.text = NumberUtil.numberFormat(result.max_combo);
            valueCredits.text = NumberUtil.numberFormat(result.credits);

            /// - Rank Text
            currentRank.text = "";
            lastRank.text = "";
            scoreHash.text = "";
            if (result.user.siteId == _gvars.playerUser.siteId)
            {
                // Has R3 Highscore
                var savedRankResult:Object = _gvars.songResultRanks[result.game_index];
                if (savedRankResult != null)
                {
                    if (savedRankResult.error)
                    {
                        currentRank.text = savedRankResult.text1;
                        lastRank.text = savedRankResult.text2;
                    }
                    else
                    {
                        currentRank.text = sprintf(_lang.string("results_rank"), {rank: savedRankResult.new_ranking});
                        lastRank.text = sprintf(_lang.string("results_last_rank"), {rank: savedRankResult.old_ranking});
                        scoreHash.text = savedRankResult.hash;
                    }
                }
                // Alt Engine Score
                else if (result.songInfo && result.songInfo.engine)
                {
                    valueCredits.text = "0";
                    var rank:Object = result.legacyLastRank;
                    if (rank)
                    {
                        currentRank.text = sprintf(_lang.string((rank.score < result.score ? "results_last_best" : "results_best")), {score: rank.score});
                        lastRank.text = rank.results;
                    }
                    else
                    {
                        currentRank.text = _lang.string("results_saved_score_locally");
                        lastRank.text = "";
                    }
                }
                // Getting Rank / Unsendable Score
                else if (!result.options.replay && result.game_index >= 0 && !result.user.isGuest)
                {
                    currentRank.text = _lang.string(canScoreSave ? "results_saving_score" : "results_score_not_saved");
                    lastRank.text = "";
                }
            }

            // Edited Replay
            if (result.options.replay && result.options.replay.isEdited)
            {
                currentRank.text = _lang.string("results_replay_modified");
                resultsDisplay.result_rank.textColor = 0xF06868;
            }

            // Song Preview
            if (result.is_preview)
            {
                header.text = _lang.string("results_song_preview");
                valueCredits.text = "0";
            }

            // Mod Text
            resultsMods.text = sprintf(_lang.string("results_scroll_speed"), {value: result.options.scrollSpeed});
            if (result.restarts > 0)
                resultsMods.text += ", " + sprintf(_lang.string("results_restarts"), {value: result.restarts});

            var mods:Array = [];
            for each (var mod:String in result.options.mods)
                mods.push(_lang.string("options_mod_" + mod));

            if (result.options.judgeWindow)
                mods.push(_lang.string("options_mod_judge"));
            if (mods.length > 0)
                resultsMods.text += ", " + sprintf(_lang.string("results_game_mods"), {value: mods.join(", ")});
            if (result.last_note > 0)
                resultsMods.text += ", " + sprintf(_lang.string("results_last_note"), {value: result.last_note});

            if (result.game_index != -1)
            {
                graphAccuracy.setHoverText(sprintf(_lang.string("result_accuracy_deviation"), {"acc_frame": result.accuracy_frames.toFixed(3),
                        "acc_dev_frame": result.accuracy_deviation_frames.toFixed(3),
                        "acc_ms": result.accuracy.toFixed(3),
                        "acc_dev_ms": result.accuracy_deviation.toFixed(3)}), "right");
            }

            drawResultGraph();
        }

        private function addBackgroundImage():void
        {
            const songInfo:SongInfo = result.songInfo;

            // Background
            if (songInfo.background != null)
            {
                var bgValid:Boolean = false;
                var bgPath:String = songInfo.background;
                if (bgPath.substring(0, 4) == "http")
                {
                    bgValid = true;
                }
                else
                {
                    var bgExt:String = songInfo.background.substr(songInfo.background.lastIndexOf(".") + 1).toLowerCase();
                    if (bgExt == "jpg" || bgExt == "png" || bgExt == "gif" || bgExt == "jpeg")
                    {
                        bgPath = "file:///" + bgPath;
                        bgValid = true;
                    }
                }

                if (bgValid)
                {
                    var imageLoader:Loader = new Loader();
                    imageLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_backgroundLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, e_backgroundLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_backgroundLoaded);
                    imageLoader.load(new URLRequest(bgPath), AirContext.getLoaderContext());

                    function e_backgroundLoaded(e:Event):void
                    {
                        // Position Loaded Banner Image
                        if (e.type == Event.COMPLETE && e.target != null && ((e.target as LoaderInfo).content) != null)
                        {
                            bgImage = ((e.target as LoaderInfo).content) as Bitmap;
                            bgImage.smoothing = true;
                            bgImage.pixelSnapping = "always";
                            addChildAt(bgImage, 1);
                            bgImage.alpha = 0.5;

                            var imageScale:Number = 780 / bgImage.width;

                            bgImage.scaleX = bgImage.scaleY = imageScale;

                            if (bgImage.height < 480)
                            {
                                bgImage.scaleX = bgImage.scaleY = 1;
                                imageScale = 480 / bgImage.height;
                                bgImage.scaleX = bgImage.scaleY = imageScale;
                                bgImage.x = -((bgImage.width - 780) / 2);
                            }
                            else
                                bgImage.y = -((bgImage.height - 480) / 2);
                        }
                    }
                }
            }
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
        private function drawResultGraph():void
        {
            var graph_type:int = graphType;

            // Check for Totals Index
            if (result.song == null || result.replay_bin_notes == null)
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
            var cacheId:String = graphType + "_" + result.game_index;

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
                else if (graphType == GRAPH_ACCURACY_PRECISE)
                {
                    newGraph = new GraphAccuracyPrecise(graphDraw, graphOverlay, result);
                }
                else if (graphType == GRAPH_ACCURACY_PRECISE2)
                {
                    newGraph = new GraphAccuracyPrecise2(graphDraw, graphOverlay, result);
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
        public function e_graphHover(e:MouseEvent):void
        {
            //trace(e.stageX - graphOverlay.x, e.stageY - graphOverlay.y);
            if (activeGraph != null)
            {
                activeGraph.drawOverlay(e.stageX - graphOverlay.x, e.stageY - graphOverlay.y);
            }
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

            if (target == graphToggle)
            {
                if (result.song != null)
                {
                    graphType = (graphType + 1) % 4;
                    LocalStore.setVariable("result_graph_type", graphType);
                    drawResultGraph();
                }
            }
        }
    }
}
