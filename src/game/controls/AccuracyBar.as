package game.controls
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObjectContainer;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import game.GameOptions;

    public class AccuracyBar extends Sprite
    {
        private static var CLEAR_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 0);
        private static var ADJUST_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 0.95)

        private var options:GameOptions;

        private var _renderTarget:Shape;
        private var _displayBM:Bitmap;
        private var _displayBMD:BitmapData;
        private var _alphaArea:Rectangle;

        private var fade_tick:int = 33;
        private var fade_timer:int = 0;

        private const LINE_WIDTH:int = 3;

        private var bound_lower:int = -117;
        private var bound_upper:int = 117;
        private var bound_range:int = 234;

        private var _width:Number = 200;
        private var _height:Number = 16;

        private var _colors:Array;

        public function AccuracyBar(options:GameOptions, parent:DisplayObjectContainer):void
        {
            if (parent)
                parent.addChild(this);

            this.options = options;

            updateJudge();

            // Parse Colors
            _colors = [];
            _colors[100] = options.judgeColors[0];
            _colors[50] = options.judgeColors[1];
            _colors[25] = options.judgeColors[2];
            _colors[5] = options.judgeColors[3];

            // Setup ColorTransform for Fade
            _renderTarget = new Shape();
            _alphaArea = new Rectangle(0, 0, _width, _height);

            draw();
        }

        public function onScoreSignal(_score:int, _judgeMS:int):void
        {
            // Judge Accuracy Lines
            _renderTarget.graphics.clear();

            _renderTarget.graphics.beginFill(_colors[_score], 1);
            _renderTarget.graphics.drawRect((_judgeMS / bound_range * (_width - LINE_WIDTH)) + (_width / 2), 0, LINE_WIDTH, _height);
            _renderTarget.graphics.endFill();

            _displayBMD.draw(_renderTarget);
            _displayBMD.colorTransform(_alphaArea, ADJUST_TRANSFORM);
        }

        public function onResetSignal():void
        {
            _displayBMD.colorTransform(_alphaArea, CLEAR_TRANSFORM);
        }

        /**
         * Updates Judge Region Min Time, Max Time, and Total Size
         * either from the default judge, or a custom set judge.
         */
        public function updateJudge():void
        {
            // Get Judge Window
            var judge:Array = Constant.JUDGE_WINDOW;
            if (options.judgeWindow)
                judge = options.judgeWindow;

            // Get Judge Window Size
            for (var jn:int = 0; jn < judge.length; jn++)
            {
                var jni:Object = judge[jn];
                if (jni.t < bound_lower)
                    bound_lower = jni.t;

                if (jni.t > bound_upper)
                    bound_upper = jni.t;
            }

            bound_range = bound_upper - bound_lower;
        }

        public function draw():void
        {
            this.graphics.clear();

            this.graphics.lineStyle(1, 0xFFFFFF, 0.13);
            this.graphics.beginFill(0xFFFFFF, 0.02);
            this.graphics.drawRect(-(_width / 2), -(_height / 2), _width, _height);
            this.graphics.endFill();

            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.moveTo(0, -(_height / 2) - 8);
            this.graphics.lineTo(0, (_height / 2) + 8);

            drawJudgeRegions();

            // Setup Bitmap for Display
            if (_displayBM != null)
                removeChild(_displayBM);

            _displayBMD = new BitmapData(_width, _height, true, 0)
            _displayBM = new Bitmap(_displayBMD);

            _displayBM.x = -(_width / 2);
            _displayBM.y = -(_height / 2);

            addChild(_displayBM);
        }

        public function drawJudgeRegions():void
        {
            // Get Judge Window
            var judge:Array = Constant.JUDGE_WINDOW;
            if (options.judgeWindow)
                judge = options.judgeWindow;

            this.graphics.lineStyle(1, 0xFFFFFF, 0.13);

            for (var jn:int = 1; jn < judge.length - 1; jn++)
            {
                var dX:Number = _width * ((judge[jn]["t"] - bound_lower) / bound_range);
                this.graphics.moveTo(-(_width / 2) + dX, -(_height / 2) + 1);
                this.graphics.lineTo(-(_width / 2) + dX, (_height / 2) - 1);
            }
        }

        override public function set width(val:Number):void
        {
            _width = val;
            _alphaArea.width = _width;
            draw();
        }

        override public function set height(val:Number):void
        {
            _height = val;
            _alphaArea.height = _height;
            draw();
        }
    }

}
