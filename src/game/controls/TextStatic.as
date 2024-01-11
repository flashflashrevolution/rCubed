package game.controls
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class TextStatic extends Sprite
    {
        private var field:TextField;

        public function TextStatic(text:String, parent:DisplayObjectContainer, color:Number = 0x0098CB, size:uint = 17)
        {
            if (parent)
                parent.addChild(this);

            field = new TextField();
            field.defaultTextFormat = new TextFormat(Fonts.BASE_FONT_CJK, size, color, true);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.autoSize = TextFieldAutoSize.LEFT;
            field.x = field.y = 0; // Fixes Bug
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
