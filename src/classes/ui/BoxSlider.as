package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    public class BoxSlider extends Sprite
    {
        private var _width:Number;
        private var _height:Number;
        private var _slider:Sprite;
        private var _slideValue:Number = 0;
        private var _minValue:Number = 0;
        private var _maxValue:Number = 1;

        private var _listener:Function = null;

        public function BoxSlider(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:int = 0, height:int = 0, listener:Function = null)
        {
            if (parent)
                parent.addChild(this);

            this.x = xpos;
            this.y = ypos;

            this._width = width;
            this._height = height;

            init();

            if (listener != null)
            {
                this._listener = listener;
                this.addEventListener(Event.CHANGE, listener);
            }
        }

        protected function init():void
        {
            this.graphics.lineStyle(1, 0xFFFFFF, 0.3);
            this.graphics.moveTo(0, _height / 2);
            this.graphics.lineTo(_width, _height / 2);

            _slider = new Sprite();
            _slider.graphics.lineStyle(1, 0xFFFFFF, 0.55);
            _slider.graphics.beginFill(0xFFFFFF, 0.2);
            _slider.graphics.drawRect(0, 0, 10, _height);
            _slider.graphics.endFill();
            _slider.buttonMode = true;
            _slider.useHandCursor = true;
            _slider.mouseChildren = false;
            _slider.addEventListener(MouseEvent.MOUSE_DOWN, e_startDrag);
            addChild(_slider);
        }

        private function e_startDrag(e:MouseEvent):void
        {
            _slider.startDrag(false, new Rectangle(0, 0, _width - _slider.width, 0));
            stage.addEventListener(MouseEvent.MOUSE_MOVE, e_dragMove);
            stage.addEventListener(MouseEvent.MOUSE_UP, e_stopDrag);
        }

        private function e_dragMove(e:MouseEvent):void
        {
            _slideValue = (_slider.x / (_width - _slider.width)) * valueRange + _minValue;

            this.dispatchEvent(new Event(Event.CHANGE));
        }

        private function e_stopDrag(e:MouseEvent):void
        {
            _slider.stopDrag();
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, e_dragMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, e_stopDrag);
            _slideValue = (_slider.x / (_width - _slider.width)) * valueRange + _minValue;
        }

        /**
         * Returns the slider value and capped between the min and max values.
         */
        public function get slideValue():Number
        {
            return Math.max(Math.min(_slideValue, _maxValue), _minValue);
        }

        public function set slideValue(value:Number):void
        {
            _slideValue = value;
            var moveVal:Number = (slideValue - minValue) / valueRange;
            _slider.x = (_width - _slider.width) * moveVal;
        }

        public function get valueRange():Number
        {
            return _maxValue - _minValue;
        }

        public function get minValue():Number
        {
            return _minValue;
        }

        public function set minValue(val:Number):void
        {
            _minValue = val;
        }

        public function get maxValue():Number
        {
            return _maxValue;
        }

        public function set maxValue(val:Number):void
        {
            _maxValue = val;
        }
    }

}
