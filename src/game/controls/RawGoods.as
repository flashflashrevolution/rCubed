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
            colors_dark = new Number(options.rawGoodsColor);
            colors = options.rawGoodsColor;
            colors_dark = ColorUtil.darkenColor(options.rawGoodsColor, 0.5);

            fieldShadow = new TextField();
            fieldShadow.defaultTextFormat = new TextFormat(Language.UNI_FONT_NAME, 30, colors_dark, true);
            fieldShadow.antiAliasType = AntiAliasType.ADVANCED;
            fieldShadow.embedFonts = true;
            fieldShadow.selectable = false;
            fieldShadow.autoSize = TextFieldAutoSize.RIGHT;
            fieldShadow.x = 2;
            fieldShadow.y = 2;
            fieldShadow.text = "0";
            addChild(fieldShadow);

            field = new TextField();
            field.defaultTextFormat = new TextFormat(Language.UNI_FONT_NAME, 30, colors, true);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.autoSize = TextFieldAutoSize.RIGHT;
            field.x = 0;
            field.y = 0;
            field.text = "0";
            addChild(field);

            if (options && options.isAutoplay && !options.isEditor && !options.mpRoom)
            {
                field.textColor = 0xDC00C2;
                fieldShadow.textColor = 0x6E0061;
            }
        }

        public function update(raw_goods:Number):void
        {
            field.text = NumberUtil.numberFormat(raw_goods, 1, true).toString();
            fieldShadow.text = NumberUtil.numberFormat(raw_goods, 1, true).toString();
        }

        public function set alignment(value:String):void
        {
            field.autoSize = value;
            fieldShadow.autoSize = value;
        }
    }
}
