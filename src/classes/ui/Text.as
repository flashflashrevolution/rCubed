package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;

    public dynamic class Text extends Sprite
    {
        public static const LEFT:String = "left";
        public static const CENTER:String = "center";
        public static const RIGHT:String = "right";

        private var _textTF:TextField;
        private var _textTFormat:TextFormat;
        private var _message:String;
        private var _width:Number = -1;
        private var _height:Number = 22.6;
        private var _fontSize:Number;
        private var _fontColor:String;
        private var _useArea:Boolean = false;
        private var _align:String = LEFT;
        private var _isUnicode:Boolean = false;

        ///- Constructor
        public function Text(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, message:* = "", fontSize:int = 12, fontColor:String = "#FFFFFF")
        {
            if (parent)
                parent.addChild(this);

            this.x = xpos;
            this.y = ypos;

            this._message = message.toString();
            this._fontSize = fontSize;
            this._fontColor = fontColor;
            this.mouseChildren = false;
            this.mouseEnabled = false;

            // Build Text
            _textTF = new TextField();
            _textTF.selectable = false;
            _textTF.embedFonts = true;
            _textTF.antiAliasType = AntiAliasType.ADVANCED;
            _textTF.autoSize = "left";
            //_textTF.border = true;
            //_textTF.borderColor = 0xFF0000;
            this.addChild(_textTF);

            draw();
        }

        public function setAreaParams(width:Number, height:Number, align:String = LEFT):void
        {
            _width = width;
            _height = height;
            _align = align;
            _useArea = true;
            draw();
        }

        override public function set width(nW:Number):void
        {
            _width = nW;
            _useArea = true;
            draw();
        }

        override public function set height(nH:Number):void
        {
            _height = nH;
            _useArea = true;
            draw();
        }

        public function get useArea():Boolean
        {
            return _useArea;
        }

        public function set useArea(inBool:Boolean):void
        {
            _useArea = inBool;
            draw();
        }

        public function set align(inString:String):void
        {
            _align = inString;
            _useArea = true;
            draw();
        }

        public function get textfield():TextField
        {
            return _textTF;
        }

        public function get text():String
        {
            return _message;
        }

        public function set text(value:String):void
        {
            if (_message != value)
            {
                _message = value;
                draw();
            }
        }

        public function get fontColor():String
        {
            return _fontColor;
        }

        public function set fontColor(value:String):void
        {
            _fontColor = value;
            draw();
        }

        public function get fontSize():int
        {
            return _fontSize;
        }

        public function set fontSize(value:int):void
        {
            if (_fontSize != value)
            {
                _fontSize = value;
                draw();
            }
        }

        private function html():String
        {
            var fnt:String = isUnicode(_message) ? Fonts.BASE_FONT_CJK : Fonts.BASE_FONT;
            return "<font face=\"" + fnt + "\" color=\"" + _fontColor + "\" size=\"" + _fontSize + "\"><b>" + _message + "</b></font>";
        }

        private function draw():void
        {
            _textTF.htmlText = html();

            if (_useArea)
            {
                //- Clickable Area
                this.graphics.clear();
                //this.graphics.lineStyle(1, Math.random() * 0xFFFFFF, 1);
                this.graphics.beginFill(0, 0);
                this.graphics.drawRect(0, 0, _width, _height);
                this.graphics.endFill();

                //- Auto Center Y axis.
                if (_width > 0)
                {
                    //- Fit Witin Area
                    _textTF.scaleX = _textTF.scaleY = 1;
                    if (_textTF.width > _width)
                        _textTF.scaleX = _textTF.scaleY = _width / _textTF.width;

                }
                _textTF.y = ((_height - _textTF.height) / 2);

                //- Text Alignment to Area
                if (_align == LEFT)
                {
                    _textTF.x = 0;
                }
                else if (_align == CENTER)
                {
                    _textTF.x = ((_width - _textTF.width) / 2);
                }
                else if (_align == RIGHT)
                {
                    _textTF.x = (_width - _textTF.width);
                }
            }
        }

        public function dispose():void
        {
            if (_textTF)
            {
                this.removeChild(_textTF);
                _textTF = null;
            }
            _textTF = null;
        }

        public static function isUnicode(str:String):Boolean
        {
            return !((/^[\x20-\x7E]*$/).test(str));
        }
    }
}
