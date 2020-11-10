package classes.ui
{
    import flash.display.CapsStyle;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.utils.getTimer;

    /**
     * Simple animated throbber.
     */
    public class Throbber extends Sprite
    {

        /**
         * The colors to use for the lines.  <br>
         * When there are 12 steps the colors are used as follows: <br>
         * - the first color is used at 12 o'clock <br>
         * - the second color is used at 11 o'clock, etc.<br>
         * - the last color is used for all remaining lines
         */
        public var colors:Array = [0xffffff];
        public var alphas:Array = [1, 0.9, 0.8, 0.7, 0.6, 0.5];

        // The alpha value for all lines. 
        public var lineAlpha:Number = 1;

        // The thickness of all lines. 
        public var lineThickness:int = 3;

        // The delay in milliseconds between drawing the animating lines. 
        public var delay:int = 100;

        // If true then when this throbber is added to stage it starts (defaults to false). 
        public var autoStart:Boolean = false;

        // If true then the throbber is hidden when it is stopped. 
        public var hideWhenStopped:Boolean = false;

        // the last time the lines were drawn
        private var lastDraw:int = 0;

        // the width of the throbber
        private var w:Number;

        // the height of the throbber
        private var h:Number;

        /**
         * Initializes the throbber with the given width, height, and autoStart values.
         */
        public function Throbber(w:int = 32, h:int = 32, lineThickness:int = 3)
        {
            super();
            this.w = w;
            this.h = h;
            this.lineThickness = lineThickness;

            addEventListener(Event.ADDED_TO_STAGE, addedToStage);
            addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
        }

        private function addedToStage(event:Event):void
        {
            if (autoStart)
            {
                start();
            }
            else if (!hideWhenStopped)
            {
                redraw();
            }
        }

        private function removedFromStage(event:Event):void
        {
            stop();
        }

        private var _running:Boolean;

        // Returns true when the throbber is animating. 
        public function get running():Boolean
        {
            return _running;
        }

        private var _currentStep:int = 0;

        // Returns the current step in the animation process. 
        public function get currentStep():int
        {
            return _currentStep;
        }

        // Moves to the next step and redraws. 
        public function nextStep():void
        {
            _currentStep = (_currentStep + 1) % maxSteps;
            redraw();
        }

        private var _maxSteps:int = 12;

        // Returns the maximum number of steps in the animation process. 
        public function get maxSteps():int
        {
            return _maxSteps;
        }

        // Starts the animation. 
        public function start():void
        {
            if (!_running)
            {
                _running = true;
                redraw();
                addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
            }
        }

        // Stops the animation. 
        public function stop():void
        {
            if (_running)
            {
                _running = false;
                removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
                if (hideWhenStopped)
                {
                    graphics.clear();
                    _currentStep = 0;
                }
            }
        }

        // Resets back to the first step.  Doesn't stop the animation if it's running. 
        public function reset():void
        {
            _currentStep = 0;
            if (!running)
            {
                if (hideWhenStopped)
                {
                    graphics.clear();
                }
                else
                {
                    redraw();
                }
            }
        }

        private function enterFrameHandler(event:Event):void
        {
            if (running)
            {
                var diff:int = getTimer() - lastDraw;
                if (diff > delay)
                {
                    nextStep();
                }
            }
        }

        protected function redraw():void
        {
            lastDraw = getTimer();
            drawLines();
        }

        /**
         * Draws the 12 lines.
         */
        protected function drawLines():void
        {
            var g:Graphics = graphics;
            g.clear();

            var midX:int = Math.round(w / 2);
            var midY:int = Math.round(w / 2);
            var radius:int = Math.min(midX, midY);

            if ((radius > 0) && (lineThickness > 0) && (lineAlpha > 0))
            {
                var angle:Number = 0;
                const maxAngle:Number = (2 * Math.PI);
                var incr:Number = maxAngle / maxSteps;
                var lineNum:int = 0;
                while (angle < maxAngle)
                {
                    var color:uint = getColor(lineNum);
                    g.lineStyle(lineThickness, color, getAlpha(lineNum), true, null, CapsStyle.ROUND);

                    // figure out the position around the circle
                    var x1:Number = midX + (radius * Math.sin(angle));
                    var y1:Number = midY - (radius * Math.cos(angle));
                    // make a hole in the center, make each line segment be 40% of the radius
                    var dr:int = (3 * radius / 5);
                    var x2:Number = midX + (dr * Math.sin(angle));
                    var y2:Number = midY - (dr * Math.cos(angle));
                    g.moveTo(x1, y1);
                    g.lineTo(x2, y2);

                    angle += incr;
                    lineNum++;
                }
            }
        }

        /**
         * Determines the color based on which line is being drawn.
         */
        private function getColor(lineNum:int):uint
        {
            var color:uint = colors[0];
            if (currentStep >= 0)
            {
                var diff:int = (currentStep - lineNum);
                if (diff < 0)
                {
                    diff += maxSteps;
                }
                var index:int = Math.min(colors.length - 1, diff);
                color = colors[index];
            }
            return color;
        }

        /**
         * Determines the alpha based on which line is being drawn.
         */
        private function getAlpha(lineNum:int):Number
        {
            var newAlpha:Number = alphas[0];
            if (currentStep >= 0)
            {
                var diff:int = (currentStep - lineNum);
                if (diff < 0)
                {
                    diff += maxSteps;
                }
                var index:int = Math.min(alphas.length - 1, diff);
                newAlpha = alphas[index];
            }
            return newAlpha;
        }

    }
}
