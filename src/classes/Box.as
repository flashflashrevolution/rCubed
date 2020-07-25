package classes
{
    import flash.display.GradientType;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    dynamic public class Box extends Sprite
    {
        // Display
        private var _width:Number;
        private var _height:Number;
        private var _highlight:Boolean = false;
        private var _active:Boolean = false;

        // Variables
        protected var _useHover:Boolean = true;
        private var _useGradient:Boolean = true;

        // Colors & Gradient
        private var GRADIENT_COLOR:Array = [0xFFFFFF, 0xFFFFFF];
        private var GRADIENT_ALPHA_HIGHLIGHT:Array = [0.35, 0.1225];
        private var GRADIENT_ALPHA:Array = [0.2, 0.04];
        private var GRADIENT_RATIO:Array = [0, 255];

        private var BOX_COLOR:uint = 0xFFFFFF;
        private var BOX_ALPHA:Number = 0.07;
        private var BOX_ALPHA_ACTIVE:Number = 0.1225;

        private var BORDER_COLOR:uint = 0xFFFFFF;
        private var BORDER_ALPHA:Number = 0.35;
        private var BORDER_ALPHA_ACTIVE:Number = 0.55;

        public function Box(width:Number, height:Number, useHover:Boolean = true, useGradient:Boolean = true):void
        {
            this._width = width;
            this._height = height;
            this._useHover = useHover;
            this._useGradient = useGradient;

            init();

            //- Add Hover Listeners
            setHoverStatus(_useHover);
        }

        protected function init():void
        {
            draw();
        }

        public function draw():void
        {
            var gradient_alphas:Array = (highlight ? GRADIENT_ALPHA_HIGHLIGHT : GRADIENT_ALPHA);
            var draw_fill_alpha:Number = (highlight ? BOX_ALPHA_ACTIVE : BOX_ALPHA);
            var draw_border_alpha:Number = (highlight ? BORDER_ALPHA_ACTIVE : BORDER_ALPHA);

            this.graphics.clear();

            this.graphics.lineStyle(1, BORDER_COLOR, draw_border_alpha, true);
            if (_useGradient)
                this.graphics.beginGradientFill(GradientType.LINEAR, GRADIENT_COLOR, gradient_alphas, GRADIENT_RATIO, Constant.GRADIENT_MATRIX);
            else
                this.graphics.beginFill(BOX_COLOR, draw_fill_alpha);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();
        }

        public function dispose():void
        {
            this.removeEventListener(MouseEvent.ROLL_OVER, e_onHover);
            this.removeEventListener(MouseEvent.ROLL_OUT, e_onHoverOut);
        }

        public function setHoverStatus(enabled:Boolean):void
        {
            if (enabled)
            {
                this.addEventListener(MouseEvent.ROLL_OVER, e_onHover, false, 0, true);
            }
            else
            {
                this.removeEventListener(MouseEvent.ROLL_OVER, e_onHover);
                this.removeEventListener(MouseEvent.ROLL_OUT, e_onHoverOut);
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Events
        private function e_onHover(e:MouseEvent):void
        {
            _highlight = true;
            draw();
            this.addEventListener(MouseEvent.ROLL_OUT, e_onHoverOut, false, 0, true);
        }

        private function e_onHoverOut(e:MouseEvent):void
        {
            _highlight = false;
            draw();
            this.removeEventListener(MouseEvent.ROLL_OUT, e_onHoverOut);
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        override public function get width():Number
        {
            return _width;
        }

        override public function get height():Number
        {
            return _height;
        }

        public function get highlight():Boolean
        {
            return _highlight || _active;
        }

        public function set active(val:Boolean):void
        {
            _active = val;
            draw();
        }

        public function get active():Boolean
        {
            return _active;
        }

        public function set color(val:uint):void
        {
            GRADIENT_COLOR = [val, val];
            BOX_COLOR = val;
            draw();
        }

        public function set borderColor(val:uint):void
        {
            BORDER_COLOR = val;
            draw();
        }

        public function set normalAlpha(val:Number):void
        {
            BOX_ALPHA = val;
            draw();
        }

        public function set activeAlpha(val:Number):void
        {
            BOX_ALPHA_ACTIVE = val;
            draw();
        }

        public function set borderAlpha(val:Number):void
        {
            BORDER_ALPHA = val;
            BORDER_ALPHA_ACTIVE = Math.min(1, BORDER_ALPHA + 0.25);
            draw();
        }

        public function set borderActiveAlpha(val:Number):void
        {
            BORDER_ALPHA_ACTIVE = val;
            draw();
        }
    }
}
