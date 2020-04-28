package classes
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public dynamic class BoxButton extends Sprite
    {
        private var _box:Box;
        private var _text:Text;

        private var _width:Number;
        private var _height:Number;
        private var _useHover:Boolean;
        private var _enabled:Boolean = true;

        public function BoxButton(width:Number, height:Number, text:String, size:int = 12, color:String = "#FFFFFF", useHover:Boolean = true, useGradient:Boolean = false)
        {
            super();

            this._width = width;
            this._height = height;
            this._useHover = useHover;

            //- Box
            _box = new Box(this._width, this._height, false, useGradient);
            this.addChild(_box);

            //- Add Text
            _text = new Text(text, size, color);
            _text.height = _height + 1;
            _text.width = _width;
            _text.align = Text.CENTER;
            this.addChild(_text);

            //- Set Defaults
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            if (this._useHover)
            {
                this.addEventListener(MouseEvent.ROLL_OVER, boxOver, false, 0, true);
            }
        }

        override public function set width(value:Number):void
        {
            _text.width = value;
            var nb:Box = new Box(value, _box.height, false, _box.useGradient);
            this.addChild(nb);
            this.swapChildren(nb, _box);
            this.removeChild(_box);
            _box = nb;
        }

        public function set enabled(value:Boolean):void
        {
            _enabled = value;
            useHandCursor = value;
            this.removeEventListener(MouseEvent.ROLL_OVER, boxOver);

            if (value && _useHover)
                this.addEventListener(MouseEvent.ROLL_OVER, boxOver, false, 0, true);

            if (_box)
                _box.boxOut();
        }

        public function get enabled():Boolean
        {
            return _enabled;
        }

        public function get text():String
        {
            return _text.text;
        }

        public function set text(value:String):void
        {
            _text.text = value;
        }

        public function set boxColor(value:uint):void
        {
            _box.color = value;
        }

        public function dispose():void
        {
            // Remove Events
            if (this._useHover)
            {
                this.removeEventListener(MouseEvent.ROLL_OVER, boxOver);
                this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);
            }

            //- Remove is already existed.
            if (_text != null)
            {
                _text.dispose();
                this.removeChild(_text);
                _text = null;
            }
            if (_box != null)
            {
                _box.dispose();
                this.removeChild(_box);
                _box = null;
            }
        }

        private function boxOver(e:MouseEvent):void
        {
            this.addEventListener(MouseEvent.ROLL_OUT, boxOut, false, 0, true);
            _box.boxOver();
        }

        private function boxOut(e:MouseEvent):void
        {
            this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);
            _box.boxOut();
        }
    }
}
