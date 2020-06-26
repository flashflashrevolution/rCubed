package classes
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;

    dynamic public class BoxText extends Sprite
    {
        protected var _textFormat:TextFormat = Constant.TEXT_FORMAT_UNICODE;
        protected var _box:Box;
        protected var _input:TextField;
        protected var _isFocused:Boolean = false;

        protected var _width:Number;
        protected var _height:Number;

        public function BoxText(width:int = 100, height:int = 20, textformat:TextFormat = null, registerChangeEvent:Boolean = true)
        {
            super();

            this._width = width;
            this._height = height;

            if (textformat)
                _textFormat = textformat;

            _box = new Box(this._width, this._height, false, false);
            this.addChild(_box);

            _input = new TextField();
            _input.width = this._width - 4;
            _input.type = "input";
            _input.embedFonts = true;
            _input.antiAliasType = AntiAliasType.ADVANCED;
            _input.defaultTextFormat = _textFormat;

            // Position Input within Box
            _input.text = "X";
            _input.height = Math.min(_input.textHeight + 4, _height);
            _input.text = "";
            _input.x = 2;
            _input.y = Math.round(_height / 2 - _input.height / 2) - 1;

            _input.addEventListener(FocusEvent.FOCUS_IN, onFocus);
            _input.addEventListener(FocusEvent.FOCUS_OUT, onFocus);

            if (registerChangeEvent)
            {
                _input.addEventListener(Event.CHANGE, onChange);
            }

            this.addChild(_input);
        }

        public function dispose():void
        {
            _box.dispose();
            _box = null;

            _input.removeEventListener(FocusEvent.FOCUS_IN, onFocus);
            _input.removeEventListener(FocusEvent.FOCUS_OUT, onFocus);
            _input.removeEventListener(Event.CHANGE, onChange);
            _input = null;
        }

        private function onFocus(e:FocusEvent):void
        {
            _isFocused = (e.type == "focusIn");
        }

        private function onChange(e:Event):void
        {
            this.dispatchEvent(e);
        }

        // Proxy Methods
        public function get borderColor():uint
        {
            return _box.borderColor;
        }

        public function set borderColor(newVal:uint):void
        {
            _box.borderColor = newVal;
        }

        public function get color():uint
        {
            return _box.color;
        }

        public function set color(newVal:uint):void
        {
            _box.color = newVal;
        }

        public function get text():String
        {
            return _input.text;
        }

        public function set text(newString:String):void
        {
            _input.text = newString;
        }

        public function get htmlText():String
        {
            return _input.htmlText;
        }

        public function set htmlText(newString:String):void
        {
            _input.htmlText = newString;
        }

        public function get restrict():String
        {
            return _input.restrict;
        }

        public function set restrict(newString:String):void
        {
            _input.restrict = newString;
        }

        public function get autoSize():String
        {
            return _input.autoSize;
        }

        public function set autoSize(newString:String):void
        {
            _input.x = newString == "center" ? 2 : 0;
            _input.autoSize = newString;
        }

        public function get type():String
        {
            return _input.type;
        }

        public function set type(newString:String):void
        {
            _input.type = newString;
        }

        public function get selectable():Boolean
        {
            return _input.selectable;
        }

        public function set selectable(newBool:Boolean):void
        {
            _input.selectable = newBool;
        }

        public function get displayAsPassword():Boolean
        {
            return _input.displayAsPassword;
        }

        public function set displayAsPassword(newBool:Boolean):void
        {
            _input.displayAsPassword = newBool;
        }

        public function get textColor():int
        {
            return _input.textColor;
        }

        public function set textColor(newint:int):void
        {
            _input.textColor = newint;
        }

        public function get focus():Boolean
        {
            return _isFocused;
        }

        public function get field():TextField
        {
            return _input;
        }
    }
}
