package classes
{
    import flash.display.Sprite;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;

    public class Alert extends Sprite
    {
        public static const RED:uint = 0x6D0E0E;
        public static const GREEN:uint = 0x116D0E;
        public static const DARK_GREEN:uint = 0x084400;
        public static const BLUE:uint = 0x0E3F6D;

        public var message:String;
        public var age:int = 120;
        public var time:int = 0;

        private var _textfield:TextField;

        public function Alert(message:String, age:int = 120, color:uint = 0x000000)
        {
            this.mouseEnabled = false;
            this.mouseChildren = false;

            this.message = message;
            this.age = age;

            _textfield = new TextField();
            _textfield.x = 6;
            _textfield.y = 2;
            _textfield.selectable = false;
            _textfield.embedFonts = true;
            _textfield.antiAliasType = AntiAliasType.ADVANCED;
            _textfield.autoSize = TextFieldAutoSize.LEFT;
            _textfield.defaultTextFormat = Constant.TEXT_FORMAT;
            _textfield.htmlText = message;

            this.graphics.lineStyle(1, 0xFFFFFF, 2, true);
            this.graphics.beginFill(color, 0.75);
            this.graphics.drawRect(0, 0, _textfield.width + 13, _textfield.height + 5);
            this.graphics.endFill();

            this.addChild(_textfield);

            this.alpha = 0;
        }

        public function progress():void
        {
            time += 1;
            if (time <= 15)
            {
                this.alpha = (time / 15);
            }
            else if (time >= age - 14)
            {
                this.alpha = 1 + ((age - 14 - time) / 15);
            }
            else
            {
                this.alpha = 1;
            }
        }
    }
}
