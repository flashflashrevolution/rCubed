package game.controls
{
    import com.flashfla.utils.ColorUtil;
    import flash.display.Sprite;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import game.GameOptions;

    public class Combo extends Sprite
    {
        private var options:GameOptions;

        private var colors:Vector.<Number>;
        private var colors_dark:Vector.<Number>;
        private var colors_enabled:Vector.<Boolean>;

        private var field:TextField;
        private var fieldShadow:TextField;

        public function Combo(options:GameOptions)
        {
            this.options = options;

            // Copy Combo Colors
            colors = new Vector.<Number>(options.comboColors.length, true);
            colors_dark = new Vector.<Number>(options.comboColors.length, true);
            for (var i:int = 0; i < options.comboColors.length; i++)
            {
                colors[i] = options.comboColors[i];
                colors_dark[i] = ColorUtil.darkenColor(options.comboColors[i], 0.5);
            }

            // Copy Enabled Colors
            colors_enabled = new Vector.<Boolean>(options.enableComboColors.length, true);
            for (i = 0; i < options.enableComboColors.length; i++)
            {
                colors_enabled[i] = options.enableComboColors[i];
            }

            fieldShadow = new TextField();
            fieldShadow.defaultTextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 50, colors_dark[2], true);
            fieldShadow.antiAliasType = AntiAliasType.ADVANCED;
            fieldShadow.embedFonts = true;
            fieldShadow.selectable = false;
            fieldShadow.autoSize = TextFieldAutoSize.LEFT;
            fieldShadow.x = 2;
            fieldShadow.y = 2;
            fieldShadow.text = "0";
            addChild(fieldShadow);

            field = new TextField();
            field.defaultTextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 50, colors[2], true);
            field.antiAliasType = AntiAliasType.ADVANCED;
            field.embedFonts = true;
            field.selectable = false;
            field.autoSize = TextFieldAutoSize.LEFT;
            field.x = 0;
            field.y = 0;
            field.text = "0";
            addChild(field);

            if (options && options.isAutoplay && !options.isEditor)
            {
                field.textColor = 0xD00000;
                fieldShadow.textColor = 0x5B0000;
            }
        }

        public function update(combo:int, amazing:int = 0, perfect:int = 0, good:int = 0, average:int = 0, miss:int = 0, boo:int = 0, raw_goods:Number = 0):void
        {
            field.text = combo.toString();
            fieldShadow.text = combo.toString();

            /* colors[i]:
               [0] = Normal,
               [1] = FC,
               [2] = AAA,
               [3] = SDG,
               [4] = Black Flag,
               [5] = Average Flag,
               [6] = Boo Flag,
               [7] = Miss Flag,
               [8] = Raw Goods
             */

            if (options && (!options.isAutoplay || options.isEditor))
            {
                if (colors_enabled[2] && good + average + boo + miss == 0) // Display AAA color
                {
                    field.textColor = colors[2];
                    fieldShadow.textColor = colors_dark[2];
                }
                else if (colors_enabled[6] && boo == 1 && good + average + miss == 0) // Display Boo Flag color
                {
                    field.textColor = colors[6];
                    fieldShadow.textColor = colors_dark[6];
                }
                else if (colors_enabled[4] && good == 1 && average + boo + miss == 0) // Display Black Flag color
                {
                    field.textColor = colors[4];
                    fieldShadow.textColor = colors_dark[4];
                }
                else if (colors_enabled[5] && average == 1 && good + boo + miss == 0) // Display Average Flag color
                {
                    field.textColor = colors[5];
                    fieldShadow.textColor = colors_dark[5];
                }
                else if (colors_enabled[7] && miss == 1 && good + average + boo == 0) // Display Miss Flag color
                {
                    field.textColor = colors[7];
                    fieldShadow.textColor = colors_dark[7];
                }
                else if (colors_enabled[8] && raw_goods >= options.rawGoodTracker) // Display color for raw good tracker
                {
                    field.textColor = colors[8];
                    fieldShadow.textColor = colors_dark[8];
                }
                else if (colors_enabled[3] && raw_goods < 10) // Display SDG color if raw goods < 10
                {
                    field.textColor = colors[3];
                    fieldShadow.textColor = colors_dark[3];
                }
                else if (colors_enabled[1] && miss == 0) // Display green for FC
                {
                    field.textColor = colors[1];
                    fieldShadow.textColor = colors_dark[1];
                }
                else // Display blue combo text
                {
                    field.textColor = colors[0];
                    fieldShadow.textColor = colors_dark[0];
                }
            }
        }

        public function set alignment(value:String):void
        {
            field.autoSize = value;
            fieldShadow.autoSize = value;
        }
    }
}
