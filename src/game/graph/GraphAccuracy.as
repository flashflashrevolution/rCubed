package game.graph
{
    import assets.menu.icons.fa.iconSmallF;
    import classes.BoxIcon;
    import classes.Language;
    import classes.Text;
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
        public var regions:Vector.<Rectangle>;

        public var last_nearest:int = -1;

        public var player_timings_length:int = 0;

        public var hover_text:Text;

        public var buttons:Sprite;

        public var judgeMinTime:Text;
        public var judgeMaxTime:Text;

        public var flipGraph:Boolean = false;

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
            last_nearest = -1;
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

            var flipGraphBtn:BoxIcon = new BoxIcon(16, 18, new iconSmallF());
            flipGraphBtn.x = -20;
            flipGraphBtn.y = 98;
            flipGraphBtn.padding = 6;
            flipGraphBtn.setHoverText(_lang.string("game_results_flip_graph"), "right");
            flipGraphBtn.addEventListener(MouseEvent.MOUSE_DOWN, e_flipGraph);
            buttons.addChild(flipGraphBtn);

            judgeMinTime = new Text((result.MIN_TIME > 0 ? "+" : "") + (result.MIN_TIME + 1) + "ms Early"); // It's greater then, so it's off by 1.
            judgeMinTime.alpha = 0.2;
            buttons.addChild(judgeMinTime);

            judgeMaxTime = new Text((result.MAX_TIME > 0 ? "+" : "") + result.MAX_TIME + "ms Late");
            judgeMaxTime.alpha = 0.2;
            buttons.addChild(judgeMaxTime);

            // Hover Text
            hover_text = new Text("", 14);
            hover_text.align = "center";
            hover_text.x = 30;
            hover_text.y = 270;
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
            for each (var point:GraphCrossPoint in cross_points)
            {
                if (point.index >= player_timings_length)
                    break;

                graph.graphics.lineStyle(1, point.color, 1);
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
                    last_nearest = -1;
                    hover_text.visible = false;
                }
                return;
            }

            hover_text.visible = true;

            // Find Nearest Cross to Mouse
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

            if (last_nearest == nearest_cross || nearest_cross < 0 || nearest_cross >= cross_points.length)
            {
                return;
            }

            // Store Current Index to prevent redraws.
            last_nearest = nearest_cross;

            // Get Cross 
            var noteResult:GraphCrossPoint = cross_points[nearest_cross];
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
            var player_timings:Array = result.replay_bin_notes;
            var note_judge:Object;

            var timing:int;
            var draw_color:uint;
            var timing_score:int;

            player_timings_length = player_timings.length;

            for (i = 0; i < player_timings_length; i++)
            {
                pos_x = i * ratio_x;
                timing_score = 0;

                // Judge Timing uses null for misses.
                if (player_timings[i] != null)
                {
                    note_judge = result.getJudgeRegion(player_timings[i]);

                    if (JUDGE_WINDOW_CROSS_COLORS[note_judge.s] != null && note_judge.s > 0)
                    {
                        pos_y = (player_timings[i] - result.MIN_TIME) * ratio_y;
                        draw_color = JUDGE_WINDOW_CROSS_COLORS[note_judge.s];
                        timing = player_timings[i];
                        timing_score = note_judge.s;
                    }
                }

                // Note Miss
                if (timing_score == 0)
                {
                    pos_y = 0;
                    timing = 0;
                    draw_color = JUDGE_WINDOW_CROSS_COLORS["0"];
                }

                if (flipGraph)
                    pos_y = graphHeight - pos_y;

                cross_points[cross_points.length] = new GraphCrossPoint(i, pos_x, pos_y, timing, draw_color, timing_score);
            }

            // Fill in Misses, Overlay uses cross point length.
            if (result.note_count > 0)
            {
                while (cross_points.length < result.note_count)
                {
                    pos_x = cross_points.length * ratio_x;
                    cross_points[cross_points.length] = new GraphCrossPoint(cross_points.length, pos_x, (flipGraph ? graphHeight : 0), 0, JUDGE_WINDOW_CROSS_COLORS["0"], 0);
                }
            }
        }

        /**
         * Flips the result graph.
         */
        private function e_flipGraph(event:MouseEvent):void
        {
            drawOverlay(-100, -100);
            flipGraph = !flipGraph;
            LocalStore.setVariable("result_flip_graph", flipGraph);
            generateGraph();
            draw();
        }

    }
}
