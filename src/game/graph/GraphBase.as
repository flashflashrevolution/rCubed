package game.graph
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import game.GameResults;
    import game.GameScoreResult;

    public class GraphBase
    {
        protected static const JUDGE_WINDOW_COLORS:Object = {"100": 0x97f658,
                "50": 0x12e006,
                "25": 0x01aa0f,
                "5": 0xf99800,
                "0": 0x000000,
                "-5": 0xB06100};

        protected static const JUDGE_WINDOW_CROSS_COLORS:Object = {"100": 0xffffff,
                "50": 0xd0ffd4,
                "25": 0x76dd7e,
                "5": 0xf99800,
                "0": 0xff0000,
                "-5": 0xB06100};

        protected static const JUDGE_WINDOW_TEXT:Object = {"100": "game_amazing",
                "50": "game_perfect",
                "25": "game_good",
                "5": "game_average",
                "0": "game_miss",
                "-5": "game_boo"};

        protected var graphWidth:Number = GameResults.GRAPH_WIDTH;
        protected var graphHeight:Number = GameResults.GRAPH_HEIGHT;

        protected var result:GameScoreResult;
        protected var graph:Sprite;
        protected var overlay:Sprite;

        public function GraphBase(target:Sprite, overlay:Sprite, result:GameScoreResult):void
        {
            this.graph = target;
            this.overlay = overlay;
            this.result = result;
        }

        /**
         * Abstract Stage Addition Function
         * @param container
         */
        public function onStage(container:DisplayObjectContainer):void
        {
            if (graph)
                graph.graphics.clear();
            if (overlay)
                overlay.graphics.clear();
        }

        /**
         * Abstract Stage Remove Function
         */
        public function onStageRemove():void
        {

        }

        /**
         * Abstract Init Function
         */
        public function init():void
        {

        }

        /**
         * Abstract Draw Function
         */
        public function draw():void
        {
        }

        /**
         * Abstract Draw Ovarlay Function
         */
        public function drawOverlay(mx:Number, my:Number):void
        {
        }

        /**
         * Check mouse position is within the graph
         * @param mx Mouse X
         * @param my Mouse Y
         * @return
         */
        public function validHover(mx:Number, my:Number, tolerance:Number = 0):Boolean
        {
            return mx >= -tolerance && my >= -tolerance && mx <= graphWidth + tolerance && my <= graphHeight + tolerance;
        }
    }
}
