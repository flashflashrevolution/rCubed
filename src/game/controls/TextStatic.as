package game.controls
{
    import flash.display.Sprite;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class TextStatic extends Sprite
    {
        private var field:TextField;

        public function TextStatic(text:String)
        {
            field = new TextField();
            field.defaultTextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 17, 0x0098CB, true);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.autoSize = TextFieldAutoSize.LEFT;
            field.x = 0;
            field.y = 0;
            field.htmlText = text;
            addChild(field);
        }

        public function update(str:String):void
        {
            field.htmlText = str;
        }

        public function set alignment(value:String):void
        {
            field.autoSize = value;
        }

        public function setFormatting(color:Number = 0x0098CB, size:int = 17):void
        {
            field.setTextFormat(new TextFormat(Fonts.BASE_FONT_CJK, size, color, true));
            field.autoSize = TextFieldAutoSize.LEFT;
        }
    }
}
