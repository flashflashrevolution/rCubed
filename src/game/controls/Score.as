package game.controls
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import game.GameOptions;

    public class Score extends Sprite
    {
        private var options:GameOptions;

        private var field:TextField;

        public function Score(options:GameOptions, parent:DisplayObjectContainer)
        {
            if (parent)
                parent.addChild(this);

            this.options = options;

            field = new TextField();
            field.defaultTextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 25, 0xFFFFFF, false);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.autoSize = TextFieldAutoSize.CENTER;
            field.x = 0;
            field.y = 0;
            field.text = "0";
            addChild(field);
        }

        public function update(score:int):void
        {
            field.text = score.toString();
        }
    }
}
