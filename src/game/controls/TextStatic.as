package game.controls
{
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import flash.text.AntiAliasType;
    import classes.Language;

    public class TextStatic extends Sprite
    {
        private var field:TextField;

        public function TextStatic(text:String)
        {
            field = new TextField();
            field.defaultTextFormat = new TextFormat(Language.UNI_FONT_NAME, 17, 0x0098CB, true);
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
    }
}
