package game.controls
{
    import com.flashfla.utils.ColorUtil;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import flash.text.AntiAliasType;
    import game.GameOptions;
    import classes.Language;
    import com.flashfla.utils.NumberUtil;

    public class RawGoods extends Sprite
    {
        private var options:GameOptions;

        private var colors:Number;
        private var colors_dark:Number;

        private var field:TextField;
        private var fieldShadow:TextField;

        public function RawGoods(options:GameOptions)
        {
            this.options = options;

            // Copy Raw Goods Colors
            colors = new Number(options.rawGoodsColor);

            field = new TextField();
            field.defaultTextFormat = new TextFormat(Language.UNI_FONT_NAME, 30, colors, true);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.autoSize = TextFieldAutoSize.LEFT;
            field.x = 0;
            field.y = 0;
            field.text = "0.0";
            addChild(field);
        }

        public function update(raw_goods:Number):void
        {
            field.text = NumberUtil.numberFormat(raw_goods, 1, true).toString();
        }

        public function updateFromPA(good:int, average:int, miss:int, boo:int):void
        {
            field.text = NumberUtil.numberFormat(good + (average * 1.8) + (miss * 2.4) + (boo * 0.2), 1, true).toString();
        }

        public function set alignment(value:String):void
        {
            field.autoSize = value;
        }
    }
}
