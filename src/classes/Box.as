package classes
{
    import flash.display.GradientType;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;

    public dynamic class Box extends Sprite
    {
        private var _width:Number;
        private var _height:Number;
        private var _box:Sprite;
        private var _border:Sprite;
        private var _isActive:Boolean = false;
        private var _useHover:Boolean = true;
        private var _useGradient:Boolean = true;

        private var _normalAlpha:Number = 0.2;
        private var _borderAlpha:Number = 0.55;
        private var _activeAlpha:Number = 0.35;
        private var _color:uint = 0xFFFFFF;
        private var _borderColor:uint = 0xFFFFFF;

        public function Box(width:Number, height:Number, useHover:Boolean = true, useGradient:Boolean = true):void
        {
            this._width = width;
            this._height = height;
            this._useHover = useHover;
            this._useGradient = useGradient;

            init();
        }

        protected function init(e:Event = null):void
        {
            //- Remove Stage Listener
            if (e != null)
                this.removeEventListener(Event.ADDED_TO_STAGE, init);

            //- Gradient Box
            var matrix:Matrix = new Matrix();
            matrix.createGradientBox(100, 100, (Math.PI / 180) * 225);

            //- Draw Box
            _box = new Sprite();
            _box.graphics.lineStyle(1, _color, 0, true);
            if (_useGradient)
                _box.graphics.beginGradientFill(GradientType.LINEAR, [_color, _color], [1, _normalAlpha], [0, 255], matrix);
            else
                _box.graphics.beginFill(_color, _activeAlpha);
            _box.graphics.drawRect(0, 0, _width, _height);
            _box.graphics.endFill();
            _box.alpha = (_isActive ? _activeAlpha : _normalAlpha);
            this.addChildAt(_box, 0);

            //- Draw Border
            _border = new Sprite();
            _border.graphics.lineStyle(1, _borderColor, 1, true);
            _border.graphics.beginFill(_borderColor, 0);
            _border.graphics.drawRect(0, 0, _width, _height);
            _border.graphics.endFill();
            _border.alpha = (_isActive ? _borderAlpha : _activeAlpha);
            this.addChildAt(_border, 1);

            //- Add Hover Listeners
            if (_useHover)
            {
                this.addEventListener(MouseEvent.ROLL_OVER, boxOver, false, 0, true);
            }
        }

        public function dispose():void
        {
            this.removeEventListener(MouseEvent.ROLL_OVER, boxOver);
            this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);

            if (_box != null)
            {
                this.removeChild(_box);
                _box = null;
            }
            if (_border != null)
            {
                this.removeChild(_border);
                _border = null;
            }
        }

        public function boxOver(e:MouseEvent = null):void
        {
            this.addEventListener(MouseEvent.ROLL_OUT, boxOut, false, 0, true);
            _box.alpha = _activeAlpha;
            _border.alpha = _borderAlpha;
        }

        public function boxOut(e:MouseEvent = null):void
        {
            this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);
            _box.alpha = (_isActive ? _activeAlpha : _normalAlpha);
            _border.alpha = (_isActive ? _borderAlpha : _activeAlpha);
        }

        public function set active(inBool:Boolean):void
        {
            _isActive = inBool;
            if (_box != null)
            {
                _box.alpha = (_isActive ? _activeAlpha : _normalAlpha);
                _border.alpha = (_isActive ? _borderAlpha : _activeAlpha);
            }
        }

        public function get activeAlpha():Number
        {
            return _activeAlpha;
        }

        public function set activeAlpha(value:Number):void
        {
            _activeAlpha = value;
            dispose();
            init();
        }

        public function get normalAlpha():Number
        {
            return _normalAlpha;
        }

        public function set normalAlpha(value:Number):void
        {
            _normalAlpha = value;
            dispose();
            init();
        }

        public function get color():uint
        {
            return _color;
        }

        public function set color(value:uint):void
        {
            _color = value;
            dispose();
            init();
        }

        public function get borderAlpha():Number
        {
            return _borderAlpha;
        }

        public function set borderAlpha(value:Number):void
        {
            _borderAlpha = value;
            dispose();
            init();
        }

        override public function get width():Number
        {
            return _width;
        }

        override public function get height():Number
        {
            return _height;
        }

        public function get useGradient():Boolean
        {
            return _useGradient;
        }

        public function get borderColor():uint
        {
            return _borderColor;
        }

        public function set borderColor(value:uint):void
        {
            _borderColor = value;
            dispose();
            init();
        }
    }

}
