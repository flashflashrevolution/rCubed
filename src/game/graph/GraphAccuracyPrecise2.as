package game.graph
{
    import assets.menu.icons.fa.iconSmallF;
    import classes.Language;
    import classes.chart.Note;
    import classes.replay.ReplayBinFrame;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.Text;
    import com.flashfla.utils.VectorUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import game.GameScoreResult;

    /**
     * Largely the same as GraphAccuracyPrecise but has the following enhancements:
     * - Misses are displayed as vertical red lines instead of red Xs at the top/bottom of the graph
     * - Unplayed notes are displayed as vertical gray lines instead of red Xs at the top/bottom of the graph
     * - Judgements can be shown/hidden individually as desired
     * - "Accuracy Groups" can be shown/hidden with a cycle toggle (All, AAA judgements, non-AAA judgements, early hits only, late hits only)
     */
    public class GraphAccuracyPrecise2 extends GraphBase
    {
        public var _lang:Language = Language.instance;
        public var cross_points:Vector.<GraphCrossPoint>;
        public var miss_points:Vector.<GraphCrossPoint>;
        public var boo_points:Vector.<GraphCrossPoint>;
        public var regions:Vector.<Rectangle>;

        public var last_nearest_index:int = -1;

        public var player_timings_length:int = 0;

        public var hover_text:Text;

        public var buttons:Sprite;

        public var judgeMinTime:Text;
        public var judgeMaxTime:Text;
        public var maxNotes:Text;
        public var lastNotePlayed:int = 0;

        public var flipGraph:Boolean = false;

        public var columnFilter:int = 0;
        public var accuracyFilter:int = 0;
        public var showJudge:Array = [true, true, true, true, true, true]; // Amazing, Perfect, Good, Avg, Miss, Boo
        private const COLUMN_FILTERS:Array = ["A", "L", "D", "U", "R", "LHS", "RHS"];
        private const ACCURACY_GROUPS:Array = ["ALL", "AAA", "NON", "EARLY", "LATE"];
        private const ACCURACY_FILTERS:Array = ["AM", "P", "G", "AV", "M", "B"];
        private var filterColumnBtn:BoxButton;
        private var filterAccuracyBtn:BoxButton;
        private var filterAmazingBtn:BoxButton;
        private var filterPerfectBtn:BoxButton;
        private var filterGoodBtn:BoxButton;
        private var filterAverageBtn:BoxButton;
        private var filterMissBtn:BoxButton;
        private var filterBooBtn:BoxButton;

        public function GraphAccuracyPrecise2(target:Sprite, overlay:Sprite, result:GameScoreResult):void
        {
            super(target, overlay, result);
            init();
        }

        override public function onStage(container:DisplayObjectContainer):void
        {
            super.onStage(container);
            hover_text.visible = false;
            if (container != null)
            {
                container.addChild(buttons);
                container.addChild(hover_text);
            }
            last_nearest_index = -1;
        }

        override public function onStageRemove():void
        {
            if (buttons != null && buttons.parent != null)
                buttons.parent.removeChild(buttons);

            if (hover_text != null && hover_text.parent != null)
                hover_text.parent.removeChild(hover_text);
        }

        override public function init():void
        {
            flipGraph = LocalStore.getVariable("result_flip_graph", false);

            // Buttons
            buttons = new Sprite();
            buttons.x = overlay.x;
            buttons.y = overlay.y;

            var flipGraphBtn:BoxIcon = new BoxIcon(buttons, -20, 98, 16, 18, new iconSmallF(), e_flipGraph);
            flipGraphBtn.padding = 6;
            flipGraphBtn.setHoverText(_lang.string("game_results_flip_graph"), "right");

            filterColumnBtn = new BoxButton(buttons, -20, 78, 16, 18, "C", 16, e_filterColumn);
            filterColumnBtn.padding = 6;
            filterColumnBtn.setHoverText(_lang.string("game_results_filter_column_" + COLUMN_FILTERS[0]), "right");

            filterAccuracyBtn = new BoxButton(buttons, -20, 58, 16, 18, "A", 16, e_filterAccGroup);
            filterAccuracyBtn.padding = 6;
            filterAccuracyBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_GROUPS[0]), "right");

            // Judgement Buttons
            var yOff:Number = 4;

            filterAmazingBtn = new BoxButton(buttons, graphWidth + 5, yOff, 14, 14, "", 14, e_filterAccuracy);
            filterAmazingBtn.padding = 5;
            filterAmazingBtn.color = 0x97F658;
            filterAmazingBtn.borderColor = 0xFFFFFF;
            filterAmazingBtn.normalAlpha = 0.6;
            filterAmazingBtn.activeAlpha = 0.8;
            filterAmazingBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_FILTERS[0]), "right");

            yOff += 19;

            filterPerfectBtn = new BoxButton(buttons, graphWidth + 5, yOff, 14, 14, "", 14, e_filterAccuracy);
            filterPerfectBtn.padding = 5;
            filterPerfectBtn.color = 0x12E006;
            filterPerfectBtn.borderColor = 0xFFFFFF;
            filterPerfectBtn.normalAlpha = 0.6;
            filterPerfectBtn.activeAlpha = 0.8;
            filterPerfectBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_FILTERS[1]), "right");

            yOff += 19;

            filterGoodBtn = new BoxButton(buttons, graphWidth + 5, yOff, 14, 14, "", 14, e_filterAccuracy);
            filterGoodBtn.padding = 5;
            filterGoodBtn.color = 0x01AA0F;
            filterGoodBtn.borderColor = 0xFFFFFF;
            filterGoodBtn.normalAlpha = 0.6;
            filterGoodBtn.activeAlpha = 0.8;
            filterGoodBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_FILTERS[2]), "right");

            yOff += 19;

            filterAverageBtn = new BoxButton(buttons, graphWidth + 5, yOff, 14, 14, "", 14, e_filterAccuracy);
            filterAverageBtn.padding = 5;
            filterAverageBtn.color = 0xF99800;
            filterAverageBtn.borderColor = 0xFFFFFF;
            filterAverageBtn.normalAlpha = 0.6;
            filterAverageBtn.activeAlpha = 0.8;
            filterAverageBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_FILTERS[3]), "right");

            yOff += 19;

            filterMissBtn = new BoxButton(buttons, graphWidth + 5, yOff, 14, 14, "", 14, e_filterAccuracy);
            filterMissBtn.padding = 5;
            filterMissBtn.color = 0xFF0000;
            filterMissBtn.borderColor = 0xFFFFFF;
            filterMissBtn.normalAlpha = 0.6;
            filterMissBtn.activeAlpha = 0.8;
            filterMissBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_FILTERS[4]), "right");

            yOff += 19;

            filterBooBtn = new BoxButton(buttons, graphWidth + 5, yOff, 14, 14, "", 14, e_filterAccuracy);
            filterBooBtn.padding = 5;
            filterBooBtn.color = 0xB06100;
            filterBooBtn.borderColor = 0xFFFFFF;
            filterBooBtn.normalAlpha = 0.6;
            filterBooBtn.activeAlpha = 0.8;
            filterBooBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_FILTERS[5]), "right");

            formatButtons();

            judgeMinTime = new Text(buttons, 0, 0, sprintf(_lang.string("game_results_graph_graph_early"), {"value": ((result.MIN_TIME > 0 ? "+" : "") + (result.MIN_TIME + 1))})); // It's greater then, so it's off by 1.
            judgeMinTime.alpha = 0.2;

            judgeMaxTime = new Text(buttons, 0, 0, sprintf(_lang.string("game_results_graph_graph_late"), {"value": ((result.MAX_TIME > 0 ? "+" : "") + (result.MAX_TIME + 1))}));
            judgeMaxTime.alpha = 0.2;

            maxNotes = new Text(buttons, graphWidth - 2, -3, sprintf(_lang.string("game_results_graph_note_count"), {"notes": result.note_count}));
            maxNotes.alpha = 0.2;
            maxNotes.align = "right";

            // Hover Text
            hover_text = new Text(null, 30, 270, "", 14);
            hover_text.align = "center";
            hover_text.width = 300;
            hover_text.mouseEnabled = false;
            hover_text.mouseChildren = false;

            generateGraph();
        }

        private function formatButtons():void
        {
            showJudge[0] ? filterAmazingBtn.alpha = 1.0 : filterAmazingBtn.alpha = 0.4;
            showJudge[1] ? filterPerfectBtn.alpha = 1.0 : filterPerfectBtn.alpha = 0.4;
            showJudge[2] ? filterGoodBtn.alpha = 1.0 : filterGoodBtn.alpha = 0.4;
            showJudge[3] ? filterAverageBtn.alpha = 1.0 : filterAverageBtn.alpha = 0.4;
            showJudge[4] ? filterMissBtn.alpha = 1.0 : filterMissBtn.alpha = 0.4;
            showJudge[5] ? filterBooBtn.alpha = 1.0 : filterBooBtn.alpha = 0.4;
        }

        override public function draw():void
        {
            graph.graphics.clear();

            judgeMinTime.y = flipGraph ? graphHeight - 18 : -2;
            judgeMaxTime.y = flipGraph ? -2 : graphHeight - 18;

            // Draw Region
            var region:Rectangle;
            for each (region in regions)
            {
                graph.graphics.lineStyle(0, 0, 0);
                graph.graphics.beginFill(region.x, 0.25); // x contains color.
                graph.graphics.drawRect(0, region.y, graphWidth, region.height);
                graph.graphics.endFill();
            }

            // Draw Divider
            var region_y:Number;
            for (var region_index:int = 0; region_index < regions.length - 1; region_index++)
            {
                region = regions[region_index];
                region_y = region.y + (!flipGraph ? region.height : 0);
                graph.graphics.lineStyle(1, 0x000000, 0.35);
                graph.graphics.moveTo(0, region_y);
                graph.graphics.lineTo(graphWidth, region_y);
            }

            // Draw Crosses for hits
            var point:GraphCrossPoint;
            var miss:GraphCrossPoint;
            var alpha:Number = 1.0;
            var color:uint = 0xFFFFFF;

            var testNoteCount:int = Math.min(cross_points.length - 1, 15);

            if (result.last_note == 0)
            {
                for (var i:int = 0; i < testNoteCount; i++)
                {
                    // Check the first 15 notes, 10 misses (10 NaN) would have failed them
                    if (cross_points[i] != null && cross_points[i].score != 0)
                    {
                        // They played the whole song, otherwise we'd not have had last_note == 0
                        lastNotePlayed = 99999999;
                    }
                }
            }
            else
            {
                lastNotePlayed = result.last_note;
            }

            for each (point in cross_points)
            {
                if (point.index >= player_timings_length)
                    break;

                var isMiss:Boolean = false;

                for each (miss in miss_points)
                {
                    if (miss.index == point.index)
                    {
                        isMiss = true;
                        break;
                    }
                }

                if (isMiss) // Skip drawing this X as it's handled as a line instead
                    continue;

                alpha = point.index < lastNotePlayed ? 1.0 : 0.3;

                if (columnFilter != 0 && ((columnFilter < 5 && point.column != COLUMN_FILTERS[columnFilter]) || (columnFilter == 5 && (point.column == "U" || point.column == "R")) || (columnFilter == 6 && (point.column == "D" || point.column == "L"))))
                    alpha = 0.1;

                if (accuracyFilter == 3 || accuracyFilter == 4)
                {
                    switch (accuracyFilter)
                    {
                        case 3: // Early judgements only
                            if (point.timing > 0)
                                alpha = 0.1;
                            break;

                        case 4: // Late judgements only
                            if (point.timing < 0)
                                alpha = 0.1;
                            break;
                    }
                }

                switch (point.score) // Set the alpha if that judge is specifically hidden from the graph
                {
                    case 100:
                        if (!showJudge[0])
                            alpha = 0.1;
                        break;
                    case 50:
                        if (!showJudge[1])
                            alpha = 0.1;
                        break;
                    case 25:
                        if (!showJudge[2])
                            alpha = 0.1;
                        break;
                    case 5:
                        if (!showJudge[3])
                            alpha = 0.1;
                        break;
                }

                graph.graphics.lineStyle(1, point.color, alpha);
                graph.graphics.moveTo(point.x - 2, point.y - 2);
                graph.graphics.lineTo(point.x + 2, point.y + 2);
                graph.graphics.moveTo(point.x + 2, point.y - 2);
                graph.graphics.lineTo(point.x - 2, point.y + 2);
            }

            // Draw lines for misses & unplayed notes
            for each (point in miss_points)
            {
                if (point.index >= player_timings_length)
                    break;

                alpha = point.index < lastNotePlayed ? 0.7 : 0.3;
                color = point.index < lastNotePlayed ? point.color : 0x444444;

                if (columnFilter != 0 && ((columnFilter < 5 && point.column != COLUMN_FILTERS[columnFilter]) || (columnFilter == 5 && (point.column == "U" || point.column == "R")) || (columnFilter == 6 && (point.column == "D" || point.column == "L"))))
                    alpha = 0.1;

                if (accuracyFilter == 3) // Viewing only early hits, so hide misses
                    alpha = 0.1;

                if (!showJudge[4]) // Misses specifically are hidden
                    alpha = 0.1;

                graph.graphics.lineStyle(1, color, alpha);
                graph.graphics.moveTo(point.x, 0);
                graph.graphics.lineTo(point.x, graphHeight);
            }

            // Draw Crosses for boos
            for each (point in boo_points)
            {
                alpha = 1.0;

                if (columnFilter != 0 && ((columnFilter < 5 && point.column != COLUMN_FILTERS[columnFilter]) || (columnFilter == 5 && (point.column == "U" || point.column == "R")) || (columnFilter == 6 && (point.column == "D" || point.column == "L"))))
                    alpha = 0.1;

                if (accuracyFilter == 3 || accuracyFilter == 4) // Viewing only early or late hits, so hide boos
                    alpha = 0.1;

                if (!showJudge[5]) // Boos specifically are hidden
                    alpha = 0.1;

                graph.graphics.lineStyle(1, point.color, alpha);
                graph.graphics.moveTo(point.x - 2, point.y - 2);
                graph.graphics.lineTo(point.x + 2, point.y + 2);
                graph.graphics.moveTo(point.x + 2, point.y - 2);
                graph.graphics.lineTo(point.x - 2, point.y + 2);
            }
        }

        override public function drawOverlay(mx:Number, my:Number):void
        {
            // Make sure hovering over graph.
            if (!validHover(mx, my, 10))
            {
                if (hover_text.visible)
                {
                    overlay.graphics.clear();
                    last_nearest_index = -1;
                    hover_text.visible = false;
                }
                return;
            }

            hover_text.visible = true;

            var i:int;
            var dx:Number;
            var dy:Number;
            var distance:Number;

            function binarySearch(values:Vector.<GraphCrossPoint>, target:Number):int
            {
                var high:int = values.length;
                var low:int = -1;
                var is_closest_low:Boolean;

                while (high - low > 1)
                {
                    var probe:int = (low + high) / 2;

                    if (values[probe].x > target)
                        high = probe;
                    else
                        low = probe;
                }

                return low;
            }

            var nearest_cross_x:int = VectorUtil.binarySearch(cross_points, mx, 'x');
            var nearest_boo_x:int = VectorUtil.binarySearch(boo_points, mx, 'x');

            var nearest_is_boo:Boolean = false;
            var nearest_hit_index:int = -1;
            var min_distance:Number = 1000000;
            var dx_px_threshold:int = 3;

            function checkIfNearer(point:GraphCrossPoint, isBoo:Boolean):Boolean
            {
                dx = Math.abs(mx - point.x);
                if (dx > dx_px_threshold)
                {
                    return false;
                }
                dy = Math.abs(my - point.y);
                distance = Math.sqrt(dx * dx + dy * dy);

                if (distance < min_distance)
                {
                    min_distance = distance;
                    nearest_hit_index = point.index;
                    nearest_is_boo = isBoo;
                }

                return true;
            }

            if (nearest_cross_x >= 0)
            {
                for (i = nearest_cross_x; i >= 0; i--)
                {
                    if (!checkIfNearer(cross_points[i], false))
                    {
                        break;
                    }
                }

                for (i = nearest_cross_x; i < cross_points.length; i++)
                {
                    if (!checkIfNearer(cross_points[i], false))
                    {
                        break;
                    }
                }
            }

            if (nearest_boo_x >= 0)
            {
                for (i = nearest_boo_x; i >= 0; i--)
                {
                    if (!checkIfNearer(boo_points[i], true))
                    {
                        break;
                    }
                }

                for (i = nearest_boo_x; i < boo_points.length; i++)
                {
                    if (!checkIfNearer(boo_points[i], true))
                    {
                        break;
                    }
                }
            }

            if (nearest_hit_index == -1)
            {
                if (nearest_boo_x == -1)
                {
                    nearest_hit_index = nearest_cross_x;
                }
                else
                {
                    var boo_point:GraphCrossPoint = boo_points[nearest_boo_x];
                    var boo_dx:Number = Math.abs(mx - boo_point.x);

                    var cross_point:GraphCrossPoint = cross_points[nearest_cross_x];
                    var cross_dx:Number = Math.abs(mx - cross_point.x);

                    if (boo_dx < cross_dx)
                    {
                        nearest_hit_index = nearest_boo_x;
                        nearest_is_boo = true;
                    }
                    else
                    {
                        nearest_hit_index = nearest_cross_x;
                        nearest_is_boo = false;
                    }
                }
            }

            // Store Current Index to prevent redraws.
            // Also give boo a shift to prevent potential index overlaps.
            var nearest_cross_index:int = nearest_hit_index + (nearest_is_boo ? 1000000 : 0);
            if (nearest_cross_index < 0)
            {
                nearest_cross_index = 0;
            }
            if (last_nearest_index == nearest_cross_index || player_timings_length <= 0)
            {
                return;
            }
            last_nearest_index = nearest_cross_index;

            // Get Cross 
            var noteResult:GraphCrossPoint = nearest_is_boo ? boo_points[nearest_hit_index] : cross_points[nearest_hit_index];
            var pos_x:Number = noteResult.x;
            var pos_y:Number = noteResult.y;

            // Set Hover Text
            var note_judge:Object;
            var hover_text_id:String = "game_result_graph_accuracy_";
            var hover_text_judge:String = JUDGE_WINDOW_TEXT[noteResult.score];

            // Add Offset in MS
            if (noteResult.score > 0)
            {
                hover_text_id += "hit";
                if (noteResult.timing > 0)
                    hover_text_id += "_late";
                if (noteResult.timing < 0)
                    hover_text_id += "_early";
            }
            else if (noteResult.score == -5)
            {
                hover_text_id += "boo";
            }
            else if (noteResult.index < lastNotePlayed)
            {
                hover_text_id += "miss";
            }
            else
            {
                hover_text_id += "unplayed";
            }

            hover_text.text = sprintf(_lang.string(hover_text_id), {"note": (nearest_hit_index + 1),
                    "judge": _lang.string(hover_text_judge),
                    "time": noteResult.timing});

            // Update Hover Text - Keep on Screen
            var boxWidth:int = Math.max(150, hover_text.textfield.textWidth + 10);
            var boxX:int = Math.max(0, Math.min(graphWidth - boxWidth, pos_x - (boxWidth / 2)));

            hover_text.x = overlay.x + boxX + (boxWidth / 2) - (hover_text.width / 2);

            // Clear Overlay
            overlay.graphics.clear();

            if (noteResult.score > 0)
            {
                // Note Hit
                // Hover Cross
                overlay.graphics.lineStyle(3, 0x289bff, 1);
                overlay.graphics.moveTo(pos_x - 2, pos_y - 2);
                overlay.graphics.lineTo(pos_x + 2, pos_y + 2);
                overlay.graphics.moveTo(pos_x + 2, pos_y - 2);
                overlay.graphics.lineTo(pos_x - 2, pos_y + 2);

                // Hover Line
                overlay.graphics.lineStyle(1, noteResult.color, 1);
                overlay.graphics.moveTo(pos_x, 0);
                overlay.graphics.lineTo(pos_x, graphHeight);
            }
            else if (noteResult.score == -5)
            {
                // Boo Hit
                // Hover Cross
                overlay.graphics.lineStyle(3, 0xB06100, 2);
                overlay.graphics.moveTo(pos_x - 2, pos_y - 2);
                overlay.graphics.lineTo(pos_x + 2, pos_y + 2);
                overlay.graphics.moveTo(pos_x + 2, pos_y - 2);
                overlay.graphics.lineTo(pos_x - 2, pos_y + 2);

                // Hover Line
                overlay.graphics.lineStyle(1, noteResult.color, 1);
                overlay.graphics.moveTo(pos_x, 0);
                overlay.graphics.lineTo(pos_x, graphHeight);
            }
            else
            {
                // Note Miss
                // Hover Line
                var color:uint = noteResult.index < lastNotePlayed ? noteResult.color : 0x666666;
                overlay.graphics.lineStyle(1, color, 1);
                overlay.graphics.moveTo(pos_x, 0);
                overlay.graphics.lineTo(pos_x, graphHeight);
            }

            // Note Information Background
            overlay.graphics.lineStyle(1, 0xffffff, 0.33);
            overlay.graphics.beginFill(0x033242, 0.95);
            overlay.graphics.drawRect(boxX, -32, boxWidth, 30);
        }

        /**
         * Generates the Judge Region Rectangles and the Graph Cross points.
         */
        private function generateGraph():void
        {
            regions = new <Rectangle>[];
            cross_points = new <GraphCrossPoint>[];
            miss_points = new <GraphCrossPoint>[];
            boo_points = new <GraphCrossPoint>[];

            // Judge 
            var song_arrows:int = result.note_count;

            var i:int;

            var pos_x:Number;
            var pos_y:Number;
            var ratio_y:Number = graphHeight / result.GAP_TIME;

            var jncj:Object;
            var jnnj:Object;
            var judge_rect:Rectangle;
            var last_judge_height:Number = 0;
            var last_judge_y:Number = 0;

            var flip_graph_y:Number = graphHeight;

            // Draw Judge Regions
            for (i = 0; i < result.judge.length; i++)
            {
                // Has Judge Region
                jncj = result.judge[i];
                jnnj = result.judge[i + 1] ? result.judge[i + 1] : null;

                if (jncj == null || jnnj == null)
                    break;

                // Has Score for Judge
                if (JUDGE_WINDOW_COLORS[jncj.s] == null || jncj.s == 0)
                    continue;

                // Create Region. X = Judge Color, Width = Region Score Value
                last_judge_height = (jnnj.t - jncj.t) * ratio_y;
                judge_rect = new Rectangle(JUDGE_WINDOW_COLORS[jncj.s], last_judge_y, jncj.s, last_judge_height);

                last_judge_y += last_judge_height;

                // Flip Graph - Default Graph is Early = Bottom
                if (flipGraph)
                {
                    flip_graph_y -= last_judge_height;
                    judge_rect.y = flip_graph_y;
                }

                regions[regions.length] = judge_rect;
            }

            // Verify Exist
            if (result.replay_bin_notes == null || result.replay_bin_boos == null)
            {
                return;
            }

            // Draw Hit Markers
            var player_timings:Vector.<ReplayBinFrame> = result.replay_bin_notes;
            var note_judge:Object;

            var timing:int;
            var draw_color:uint;
            var timing_score:int;

            player_timings_length = player_timings.length;

            var times:Array = [];
            var notes_times:Array = [];

            function getTimeFromHit(timing:ReplayBinFrame, index:int, vector:Vector.<ReplayBinFrame>):void
            {
                times.push(timing.time);
            }
            function getTimeFromSongNote(note:Note, index:int, array:Vector.<Note>):void
            {
                notes_times.push(note.time || note.frame / 30.0);
            }

            player_timings.forEach(getTimeFromHit);
            result.song.chart.Notes.forEach(getTimeFromSongNote);

            var boos:Vector.<ReplayBinFrame> = result.replay_bin_boos;

            var first_hit_time:Number = notes_times[0] + (player_timings[0].time || 0) * 0.001;
            var last_hit_time:Number = notes_times[notes_times.length - 1] + (player_timings[player_timings.length - 1].time || 0) * 0.001;
            var last_boo_time:Number = boos.length > 0 ? boos[boos.length - 1].time * 0.001 : 0;

            var min_time:Number = Math.max(Math.min(0, first_hit_time), 0);
            var max_time:Number = Math.max(Math.max(notes_times[notes_times.length - 1], last_hit_time), last_boo_time);

            var ratio_x:Number = graphWidth / Math.max(1, max_time - min_time);

            for (i = 0; i < player_timings_length; i++)
            {
                timing_score = 0;

                // Judge Timing uses null for misses.
                if (player_timings[i] != null && !isNaN(player_timings[i].time))
                {
                    pos_x = (notes_times[i] - min_time) * ratio_x;
                    note_judge = result.getJudgeRegion(player_timings[i].time);

                    if (JUDGE_WINDOW_CROSS_COLORS[note_judge.s] != null && note_judge.s > 0)
                    {
                        pos_y = (player_timings[i].time - result.MIN_TIME) * ratio_y;
                        draw_color = JUDGE_WINDOW_CROSS_COLORS[note_judge.s];
                        timing = player_timings[i].time;
                        timing_score = note_judge.s;
                    }
                }

                // Note Miss
                if (timing_score == 0)
                {
                    pos_y = graphHeight;
                    timing = 0;
                    draw_color = JUDGE_WINDOW_CROSS_COLORS["0"];

                    pos_x = (notes_times[i] - min_time) * ratio_x;
                    miss_points[miss_points.length] = new GraphCrossPoint(i, pos_x, pos_y, timing, draw_color, timing_score, player_timings[i].direction);
                }

                if (flipGraph)
                    pos_y = graphHeight - pos_y;

                if (player_timings[i] != null)
                {
                    pos_x = (notes_times[i] - min_time) * ratio_x;
                    cross_points[cross_points.length] = new GraphCrossPoint(i, pos_x, pos_y, timing, draw_color, timing_score, player_timings[i].direction);
                }
            }

            // Boos
            var boo:ReplayBinFrame;
            var boo_y:Number = flipGraph ? graphHeight : 0;
            for (i = 0; i < boos.length; i++)
            {
                boo = boos[i];
                pos_x = (boo.time / 1000 - min_time) * ratio_x;
                boo_points[boo_points.length] = new GraphCrossPoint(boo_points.length, pos_x, boo_y, Number((boo.time / 1000).toFixed(2)), JUDGE_WINDOW_CROSS_COLORS["-5"], -5, boo.direction);
            }
        }

        /**
         * Flips the result graph.
         */
        private function e_flipGraph(event:MouseEvent):void
        {
            flipGraph = !flipGraph;
            LocalStore.setVariable("result_flip_graph", flipGraph);
            last_nearest_index = -1;
            generateGraph();
            draw();
            drawOverlay(overlay.stage.mouseX - overlay.x, overlay.stage.mouseY - overlay.y);
        }

        /**
         * Changes currently filtered column.
         */
        private function e_filterColumn(event:MouseEvent):void
        {
            columnFilter = (columnFilter >= COLUMN_FILTERS.length - 1) ? 0 : columnFilter + 1;
            filterColumnBtn.setHoverText(_lang.string("game_results_filter_column_" + COLUMN_FILTERS[columnFilter]), "right");

            redrawGraph();
        }

        /**
         * Changes currently filtered accuracy group.
         */
        private function e_filterAccGroup(event:MouseEvent):void
        {
            accuracyFilter = (accuracyFilter >= ACCURACY_GROUPS.length - 1) ? 0 : accuracyFilter + 1;
            filterAccuracyBtn.setHoverText(_lang.string("game_results_filter_acc_" + ACCURACY_GROUPS[accuracyFilter]), "right");

            runJudgementToggles();
            formatButtons();
            redrawGraph();
        }

        /**
         * Changes toggles display of a specific judgement.
         */
        private function e_filterAccuracy(event:MouseEvent):void
        {
            switch (event.target)
            {
                case filterAmazingBtn:
                    showJudge[0] = !showJudge[0];
                    break;

                case filterPerfectBtn:
                    showJudge[1] = !showJudge[1];
                    break;

                case filterGoodBtn:
                    showJudge[2] = !showJudge[2];
                    break;

                case filterAverageBtn:
                    showJudge[3] = !showJudge[3];
                    break;

                case filterMissBtn:
                    showJudge[4] = !showJudge[4];
                    break;

                case filterBooBtn:
                    showJudge[5] = !showJudge[5];
                    break;
            }

            formatButtons();
            redrawGraph();
        }

        private function runJudgementToggles():void
        {
            var i:int;

            // All should be shown to start so we only have to hide them
            for (i = 0; i < 6; i++)
            {
                showJudge[i] = true;
            }

            switch (accuracyFilter)
            {
                case 1: // AAA judgements only
                    for (i = 2; i < 6; i++)
                    {
                        showJudge[i] = false;
                    }
                    break;

                case 2: // Non-AAA judgements only
                    for (i = 0; i < 2; i++)
                    {
                        showJudge[i] = false;
                    }
                    break;
            }
        }

        private function redrawGraph():void
        {
            if (player_timings_length > 0)
            {
                generateGraph();
                draw();
                drawOverlay(overlay.stage.mouseX - overlay.x, overlay.stage.mouseY - overlay.y);
            }
        }
    }
}
