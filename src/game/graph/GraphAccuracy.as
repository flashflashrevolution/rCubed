package game.graph
{
    import assets.menu.icons.fa.iconSmallF;
    import classes.Language;
    import classes.replay.ReplayBinFrame;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.Text;
    import com.flashfla.utils.sprintf;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import game.GameScoreResult;

    public class GraphAccuracy extends GraphBase
    {
        public var _lang:Language = Language.instance;
        public var cross_points:Vector.<GraphCrossPoint>;
        public var boo_points:Vector.<GraphCrossPoint>;
        public var regions:Vector.<Rectangle>;

        public var last_nearest_index:int = -1;

        public var player_timings_length:int = 0;

        public var hover_text:Text;

        public var buttons:Sprite;

        public var judgeMinTime:Text;
        public var judgeMaxTime:Text;
        public var maxNotes:Text;

        public var flipGraph:Boolean = false;

        public var columnFilter:int = 0;
        private const COLUMN_FILTERS:Array = ["A", "L", "D", "U", "R", "LHS", "RHS"]
        private var filterColumnBtn:BoxButton;

        public function GraphAccuracy(target:Sprite, overlay:Sprite, result:GameScoreResult):void
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

            // Draw Crosses
            var point:GraphCrossPoint;
            var alpha:Number = 1.0;
            for each (point in cross_points)
            {
                if (point.index >= player_timings_length)
                    break;

                if (columnFilter != 0 && ((columnFilter < 5 && point.column != COLUMN_FILTERS[columnFilter]) || (columnFilter == 5 && (point.column == "U" || point.column == "R")) || (columnFilter == 6 && (point.column == "D" || point.column == "L"))))
                {
                    alpha = 0.1;
                }
                else
                    alpha = 1.0;

                graph.graphics.lineStyle(1, point.color, alpha);
                graph.graphics.moveTo(point.x - 2, point.y - 2);
                graph.graphics.lineTo(point.x + 2, point.y + 2);
                graph.graphics.moveTo(point.x + 2, point.y - 2);
                graph.graphics.lineTo(point.x - 2, point.y + 2);
            }

            // Draw Crosses
            for each (point in boo_points)
            {
                if (columnFilter != 0 && ((columnFilter < 5 && point.column != COLUMN_FILTERS[columnFilter]) || (columnFilter == 5 && (point.column == "U" || point.column == "R")) || (columnFilter == 6 && (point.column == "D" || point.column == "L"))))
                {
                    alpha = 0.1;
                }
                else
                    alpha = 1.0;

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

            // Find Nearest Note Cross to Mouse
            var nearest_boo:Boolean = false;
            var i:int;
            var dx:Number;
            var dy:Number;
            var distance:Number;
            var minDistance:int = 1000;
            var nearest_cross:int = Math.max(0, Math.min(cross_points.length - 1, (mx / graphWidth) * cross_points.length)); // Rough Ballpark;
            var minCheckNote:int = Math.max(0, nearest_cross - 10);
            var maxCheckNote:int = Math.min(cross_points.length - 1, nearest_cross + 10);

            for (i = minCheckNote; i <= maxCheckNote; i++)
            {
                // Distance
                dx = cross_points[i].x - mx;
                dy = cross_points[i].y - my;
                distance = Math.sqrt(dx * dx + dy * dy);
                if (distance <= minDistance)
                {
                    minDistance = distance;
                    nearest_cross = i;
                }
            }

            // Boos
            maxCheckNote = boo_points.length;
            for (i = 0; i < maxCheckNote; i++)
            {
                // Distance
                dx = boo_points[i].x - mx;
                dy = boo_points[i].y - my;
                distance = Math.sqrt(dx * dx + dy * dy);
                if (distance <= minDistance)
                {
                    minDistance = distance;
                    nearest_cross = i;
                    nearest_boo = true;
                }
            }

            // Store Current Index to prevent redraws.
            var nearest_cross_index:int = nearest_cross + (nearest_boo ? 1000000 : 0); // Give boo a shift to prevent potential index overlaps.
            if (last_nearest_index == nearest_cross_index || player_timings_length <= 0)
            {
                return;
            }
            last_nearest_index = nearest_cross_index;

            // Get Cross
            var noteResult:GraphCrossPoint = nearest_boo ? boo_points[nearest_cross] : cross_points[nearest_cross];
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
            else
            {
                hover_text_id += "miss";
            }

            hover_text.text = sprintf(_lang.string(hover_text_id), {"note": (nearest_cross + 1),
                    "judge": _lang.string(hover_text_judge),
                    "time": noteResult.timing});

            // Update Hover Text - Keep on Screen
            var boxWidth:int = Math.max(150, hover_text.textfield.textWidth + 10);
            var boxX:int = Math.max(0, Math.min(graphWidth - boxWidth, pos_x - (boxWidth / 2)));

            hover_text.x = overlay.x + boxX + (boxWidth / 2) - (hover_text.width / 2);

            // Clear Overlay
            overlay.graphics.clear();

            // Hover Cross
            overlay.graphics.lineStyle(3, 0x289bff, 1);
            overlay.graphics.moveTo(pos_x - 2, pos_y - 2);
            overlay.graphics.lineTo(pos_x + 2, pos_y + 2);
            overlay.graphics.moveTo(pos_x + 2, pos_y - 2);
            overlay.graphics.lineTo(pos_x - 2, pos_y + 2);

            // Hover Line
            overlay.graphics.lineStyle(1, 0x00ff00, 1);
            overlay.graphics.moveTo(pos_x, 0);
            overlay.graphics.lineTo(pos_x, graphHeight);

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
            boo_points = new <GraphCrossPoint>[];

            // Judge
            var song_arrows:int = result.note_count;

            var i:int;

            var pos_x:Number;
            var pos_y:Number;
            var ratio_x:Number = graphWidth / Math.max(1, song_arrows - 1);
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

            // Draw Hit Markers
            var player_timings:Vector.<ReplayBinFrame> = result.replay_bin_notes;
            var note_judge:Object;

            var timing:int;
            var draw_color:uint;
            var timing_score:int;

            var boos:Vector.<ReplayBinFrame> = result.replay_bin_boos;

            player_timings_length = player_timings.length;

            for (i = 0; i < player_timings_length; i++)
            {
                pos_x = i * ratio_x;
                timing_score = 0;

                // Judge Timing uses null for misses.
                if (player_timings[i] != null && !isNaN(player_timings[i].time))
                {
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
                }

                if (flipGraph)
                    pos_y = graphHeight - pos_y;

                if (player_timings[i] != null)
                {
                    cross_points[cross_points.length] = new GraphCrossPoint(i, pos_x, pos_y, timing, draw_color, timing_score, player_timings[i].direction);
                }
                else
                {
                    cross_points[cross_points.length] = new GraphCrossPoint(i, pos_x, pos_y, timing, draw_color, timing_score, "M");
                }
            }

            // Fill in Misses, Overlay uses cross point length.
            if (result.note_count > 0)
            {
                var miss_y:Number = flipGraph ? 0 : graphHeight;
                while (cross_points.length < result.last_note)
                {
                    pos_x = cross_points.length * ratio_x;
                    cross_points[cross_points.length] = new GraphCrossPoint(cross_points.length, pos_x, miss_y, 0, JUDGE_WINDOW_CROSS_COLORS["0"], 0, player_timings[i].direction);
                }
            }

            // Boos
            var boo:ReplayBinFrame;
            var boo_y:Number = flipGraph ? graphHeight : 0;
            ratio_x = graphWidth / result.song.getNote(Math.max(0, song_arrows - 1)).time;
            for (i = 0; i < boos.length; i++)
            {
                boo = boos[i];
                pos_x = (boo.time / 1000) * ratio_x;
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
            if (player_timings_length > 0)
            {
                generateGraph();
                draw();
                drawOverlay(overlay.stage.mouseX - overlay.x, overlay.stage.mouseY - overlay.y);
            }
        }
    }
}
