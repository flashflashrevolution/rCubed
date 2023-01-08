package popups.settings
{
    import classes.Language;
    import classes.ui.BoxButton;
    import classes.ui.BoxCheck;
    import classes.ui.BoxText;
    import classes.ui.ColorField;
    import classes.ui.Text;
    import classes.ui.ValidatedText;
    import com.flashfla.utils.ColorUtil;
    import com.flashfla.utils.StringUtil;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class SettingsTabColors extends SettingsTabBase
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        private var optionJudgeColors:Array;
        private var optionComboColors:Array;
        private var optionComboColorCheck:BoxCheck;
        private var optionGameColors:Array;
        private var optionRawGoodTracker:ValidatedText;
        private var optionRawGoodsColor:String;

        public function SettingsTabColors(settingsWindow:SettingsWindow):void
        {
            super(settingsWindow);
        }

        override public function get name():String
        {
            return "colors";
        }

        override public function openTab():void
        {
            container.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            container.graphics.moveTo(295, 10);
            container.graphics.lineTo(295, 405);

            var i:int;
            var xOff:int = 15;
            var yOff:int = 10;

            /// Col 1
            var gameJudgeColorTitle:Text = new Text(container, xOff, yOff, _lang.string("options_judge_colors_title"), 14);
            gameJudgeColorTitle.width = 265;
            gameJudgeColorTitle.align = Text.CENTER;
            yOff += 20;
            yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);

            optionJudgeColors = [];
            for (i = 0; i < judgeTitles.length; i++)
            {
                var gameJudgeColor:Text = new Text(container, xOff, yOff, _lang.string("game_" + judgeTitles[i]));
                gameJudgeColor.width = 115;

                var optionJudgeColor:ValidatedText = new ValidatedText(container, xOff + 120, yOff, 70, 20, ValidatedText.R_COLOR, changeHandler);
                optionJudgeColor.judge_color_id = i;
                optionJudgeColor.field.maxChars = 7;

                var gameJudgeColorDisplay:ColorField = new ColorField(container, xOff + 195, yOff, 0, 45, 21, changeHandler);
                gameJudgeColorDisplay.key_name = "optionJudgeColor";

                var optionJudgeColorReset:BoxButton = new BoxButton(container, xOff + 245, yOff, 20, 21, "R", 12, clickHandler);
                optionJudgeColorReset.judge_color_reset_id = i;
                optionJudgeColorReset.color = 0xff0000;
                optionJudgeColors.push({"text": optionJudgeColor, "display": gameJudgeColorDisplay, "reset": optionJudgeColorReset});

                yOff += 20;
                yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);
            }

            var gameRawGoodsColor:Text = new Text(container, xOff, yOff, _lang.string("game_raw_goods"));
            gameRawGoodsColor.width = 115;

            var optionRawGoodsColor:ValidatedText = new ValidatedText(container, xOff + 120, yOff, 70, 20, ValidatedText.R_COLOR, changeHandler);
            optionRawGoodsColor.rawgoods_color_id = 1;
            optionRawGoodsColor.field.maxChars = 7;

            var gameRawGoodsColorDisplay:ColorField = new ColorField(container, xOff + 195, yOff, 0, 45, 21, changeHandler);
            gameRawGoodsColorDisplay.key_name = "optionRawGoodsColor";

            var optionRawGoodsColorReset:BoxButton = new BoxButton(container, xOff + 245, yOff, 20, 21, "R", 12, clickHandler);
            optionRawGoodsColorReset.rawgoods_color_reset_id = 1;
            optionRawGoodsColorReset.color = 0xDC00C2;
            optionJudgeColors.push({"text": optionRawGoodsColor, "display": gameRawGoodsColorDisplay, "reset": optionRawGoodsColorReset});

            yOff += 20;
            yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);

            yOff += 5;

            var gameGameColorTitle:Text = new Text(container, xOff, yOff, _lang.string("options_game_colors_title"), 14);
            gameGameColorTitle.width = 265;
            gameGameColorTitle.align = Text.CENTER;
            yOff += 20;
            yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);

            optionGameColors = [];
            for (i = 0; i < DEFAULT_OPTIONS.gameColors.length; i++)
            {
                if (i == 2 || i == 3)
                {
                    optionGameColors.push(null);
                    continue;
                }

                var gameGameColor:Text = new Text(container, xOff, yOff, _lang.string("options_game_colors_" + i));
                gameGameColor.width = 115;

                var optionGameColor:ValidatedText = new ValidatedText(container, xOff + 120, yOff, 70, 20, ValidatedText.R_COLOR, changeHandler);
                optionGameColor.game_color_id = i;
                optionGameColor.field.maxChars = 7;

                var gameGameColorDisplay:ColorField = new ColorField(container, xOff + 195, yOff, 0, 45, 21, changeHandler);
                gameGameColorDisplay.key_name = "gameGameColorDisplay";

                var optionGameColorReset:BoxButton = new BoxButton(container, xOff + 245, yOff, 20, 21, "R", 12, clickHandler);
                optionGameColorReset.game_color_reset_id = i;
                optionGameColorReset.color = 0xff0000;
                optionGameColors.push({"text": optionGameColor, "display": gameGameColorDisplay, "reset": optionGameColorReset});

                yOff += 20;
                yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);
            }

            /// Col 2
            xOff = 310;
            yOff = 10;

            var gameComboColorTitle:Text = new Text(container, xOff, yOff, _lang.string("options_combo_colors_title"), 14);
            gameComboColorTitle.width = 265;
            gameComboColorTitle.align = Text.CENTER;
            yOff += 20;
            yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);

            optionComboColors = [];
            for (i = 0; i < DEFAULT_OPTIONS.comboColors.length; i++)
            {
                var gameComboColor:Text = new Text(container, xOff, yOff, _lang.string("options_combo_colors_" + i));
                gameComboColor.width = 95;

                var optionComboColor:ValidatedText = new ValidatedText(container, xOff + 100, yOff, 70, 20, ValidatedText.R_COLOR, changeHandler);
                optionComboColor.combo_color_id = i;
                optionComboColor.field.maxChars = 7;

                var gameComboColorDisplay:ColorField = new ColorField(container, xOff + 175, yOff, 0, 45, 21, changeHandler);
                gameComboColorDisplay.key_name = "gameComboColorDisplay";

                var optionComboColorReset:BoxButton = new BoxButton(container, xOff + 225, yOff, 20, 21, "R", 12, clickHandler);
                optionComboColorReset.combo_color_reset_id = i;
                optionComboColorReset.color = 0xff0000;

                if (i > 0)
                {
                    optionComboColorCheck = new BoxCheck(container, xOff + 250, yOff + 3, clickHandler);
                    optionComboColorCheck.combo_color_enable_id = i;
                }

                optionComboColors.push({"text": optionComboColor, "display": gameComboColorDisplay, "reset": optionComboColorReset, "enable": optionComboColorCheck});

                yOff += 20;
                yOff += drawSeperator(container, xOff, 265, yOff, -3, -4);
            }

            var gameRawGoodTracker:Text = new Text(container, xOff, yOff, _lang.string("options_raw_goods_tracker"));
            gameRawGoodTracker.width = 144;
            optionRawGoodTracker = new ValidatedText(container, xOff + 149, yOff, 70, 20, ValidatedText.R_FLOAT_P, changeHandler);
        }

        override public function setValues():void
        {
            var i:int;

            // Set Judge Colors
            for (i = 0; i < judgeTitles.length; i++)
            {
                optionJudgeColors[i]["text"].text = "#" + StringUtil.pad(_gvars.activeUser.judgeColors[i].toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                optionJudgeColors[i]["display"].color = _gvars.activeUser.judgeColors[i];
            }

            // Set Raw Goods Display Color
            optionJudgeColors[judgeTitles.length]["text"].text = "#" + StringUtil.pad(_gvars.activeUser.rawGoodsColor.toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
            optionJudgeColors[judgeTitles.length]["display"].color = _gvars.activeUser.rawGoodsColor;

            // Set Combo Colors
            for (i = 0; i < DEFAULT_OPTIONS.comboColors.length; i++)
            {
                optionComboColors[i]["text"].text = "#" + StringUtil.pad(_gvars.activeUser.comboColors[i].toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                optionComboColors[i]["display"].color = _gvars.activeUser.comboColors[i];
                if (i > 0)
                {
                    optionComboColors[i]["enable"].checked = (_gvars.activeUser.enableComboColors[i]);
                }
            }

            // Set Raw Good Tracker
            optionRawGoodTracker.text = _gvars.activeUser.rawGoodTracker.toString();

            // Set Game Colors
            for (i = 0; i < DEFAULT_OPTIONS.gameColors.length; i++)
            {
                if (i == 2 || i == 3)
                    continue;

                optionGameColors[i]["text"].text = "#" + StringUtil.pad(_gvars.activeUser.gameColors[i].toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                optionGameColors[i]["display"].color = _gvars.activeUser.gameColors[i];
            }
        }

        override public function clickHandler(e:MouseEvent):void
        {
            // Judge Color Reset
            if (e.target.hasOwnProperty("judge_color_reset_id"))
            {
                _gvars.activeUser.judgeColors[e.target.judge_color_reset_id] = DEFAULT_OPTIONS.judgeColors[e.target.judge_color_reset_id];
                setValues();
            }

            // Raw Goods Color Reset
            if (e.target.hasOwnProperty("rawgoods_color_reset_id"))
            {
                _gvars.activeUser.rawGoodsColor = DEFAULT_OPTIONS.rawGoodsColor;
                setValues();
            }

            // Combo Color Reset
            else if (e.target.hasOwnProperty("combo_color_reset_id"))
            {
                _gvars.activeUser.comboColors[e.target.combo_color_reset_id] = DEFAULT_OPTIONS.comboColors[e.target.combo_color_reset_id];
                setValues();
            }

            // Combo Color Enable/Disable
            else if (e.target.hasOwnProperty("combo_color_enable_id"))
            {
                _gvars.activeUser.enableComboColors[e.target.combo_color_enable_id] = !_gvars.activeUser.enableComboColors[e.target.combo_color_enable_id];
                e.target.checked = !e.target.checked;
            }

            // Game Background Color Reset
            else if (e.target.hasOwnProperty("game_color_reset_id"))
            {
                var gid:int = e.target.game_color_reset_id;
                _gvars.activeUser.gameColors[gid] = DEFAULT_OPTIONS.gameColors[gid];

                if (gid == 0)
                    _gvars.activeUser.gameColors[2] = ColorUtil.darkenColor(DEFAULT_OPTIONS.gameColors[gid], 0.27);
                if (gid == 1)
                    _gvars.activeUser.gameColors[3] = ColorUtil.brightenColor(DEFAULT_OPTIONS.gameColors[gid], 0.08);

                setValues();
            }
        }

        override public function changeHandler(e:Event):void
        {
            if (e.target == optionRawGoodTracker)
            {
                _gvars.activeUser.rawGoodTracker = optionRawGoodTracker.validate(0, 0);
            }
            else if (e.target.hasOwnProperty("judge_color_id"))
            {
                var jid:int = e.target.judge_color_id;
                _gvars.activeUser.judgeColors[jid] = e.target.validate(0, 0);
                optionJudgeColors[jid]["display"].color = _gvars.activeUser.judgeColors[jid];
            }
            else if (e.target.hasOwnProperty("rawgoods_color_id"))
            {
                _gvars.activeUser.rawGoodsColor = e.target.validate(0, 0);
                optionJudgeColors[judgeTitles.length]["display"].color = _gvars.activeUser.rawGoodsColor;
            }
            else if (e.target.hasOwnProperty("combo_color_id"))
            {
                var cid:int = e.target.combo_color_id;
                _gvars.activeUser.comboColors[cid] = e.target.validate(0, 0);
                optionComboColors[cid]["display"].color = _gvars.activeUser.comboColors[cid];
            }
            else if (e.target.hasOwnProperty("game_color_id"))
            {
                var gid:int = e.target.game_color_id;
                var newColorG:Number = e.target.validate(0, 0);
                _gvars.activeUser.gameColors[gid] = newColorG;

                if (gid == 0)
                    _gvars.activeUser.gameColors[2] = ColorUtil.darkenColor(newColorG, 0.27);
                if (gid == 1)
                    _gvars.activeUser.gameColors[3] = ColorUtil.brightenColor(newColorG, 0.08);

                optionGameColors[gid]["display"].color = _gvars.activeUser.gameColors[gid];
            }
            else if (e.target is ColorField)
            {
                var sourceArray:Array;
                switch (e.target.key_name)
                {
                    case "optionJudgeColor":
                        sourceArray = optionJudgeColors;
                        break;
                    case "optionRawGoodsColor":
                        sourceArray = optionJudgeColors;
                        break;
                    case "gameComboColorDisplay":
                        sourceArray = optionComboColors;
                        break;
                    case "gameGameColorDisplay":
                        sourceArray = optionGameColors;
                        break;
                }
                for each (var item:Object in sourceArray)
                {
                    if (item != null && item.display == e.target)
                    {
                        (item.text as BoxText).text = "#" + StringUtil.pad((e.target as ColorField).color.toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                        (item.text as BoxText).dispatchEvent(new Event(Event.CHANGE));
                    }
                }
            }
        }
    }
}
