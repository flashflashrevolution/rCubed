package classes.mp.components.chatlog
{
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class MPChatLogEntryText extends MPChatLogEntry
    {
        private static const FORMAT:TextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 11, 0xFFFFFF, true);

        private var field:TextField;
        public var message:String;

        public function MPChatLogEntryText(message:String)
        {
            this.message = message;

            this.mouseChildren = false;
            this.cacheAsBitmap = true;
        }

        override public function build(pane_width:Number):void
        {
            if (built)
                return;

            _width = pane_width;

            field = new TextField();
            field.width = _width - 10;
            field.x = 5;
            field.y = 3;

            field.autoSize = TextFieldAutoSize.LEFT;
            field.multiline = true;
            field.wordWrap = true;
            field.embedFonts = true;
            field.selectable = false;
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.autoSize = "left";
            field.defaultTextFormat = FORMAT;

            field.htmlText = message;

            addChild(field);

            _height = field.textHeight + 7;
            built = true;
        }
    }
}
