package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;

    dynamic public class BoxText extends Box
    {
        private var _textFormat:TextFormat = Constant.TEXT_FORMAT_UNICODE;
        private var _input:TextField;
        private var _isFocused:Boolean = false;

        public function BoxText(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:int = 100, height:int = 20, textformat:TextFormat = null)
        {
            if (textformat)
                _textFormat = textformat;

            super(parent, xpos, ypos, false, false);
            super.setSize(width + 1, height + 1);

            init();
        }

        protected function init():void
        {
            _input = new TextField();
            _input.width = width - 4;
            _input.type = "input";
            _input.embedFonts = true;
            _input.antiAliasType = AntiAliasType.ADVANCED;
            _input.defaultTextFormat = _textFormat;

            // Position Input within Box
            _input.text = "X";
            _input.height = Math.min(_input.textHeight + 4, height);
            _input.text = "";
            _input.x = 2;
            _input.y = Math.round(height / 2 - _input.height / 2) - 1;

            _input.addEventListener(FocusEvent.FOCUS_IN, onFocus);
            _input.addEventListener(FocusEvent.FOCUS_OUT, onFocus);
            _input.addEventListener(Event.CHANGE, onChange);
            this.addChild(_input);
        }

        override public function dispose():void
        {
            super.dispose();
            _input.removeEventListener(FocusEvent.FOCUS_IN, onFocus);
            _input.removeEventListener(FocusEvent.FOCUS_OUT, onFocus);
            _input.removeEventListener(Event.CHANGE, onChange);
        }

        ////////////////////////////////////////////////////////////////////////
        //- Events
        private function onFocus(e:FocusEvent):void
        {
            _isFocused = (e.type == FocusEvent.FOCUS_IN);
            draw();
        }

        private function onChange(e:Event):void
        {
            this.dispatchEvent(e);
        }

        override public function get highlight():Boolean
        {
            return _isFocused || super.highlight;
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
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
            _input.x = newString == "center" ? 4 : 0;
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
