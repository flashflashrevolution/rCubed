package popups
{
    import classes.Language;
    import classes.filter.EngineLevelFilter;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.BoxText;
    import classes.ui.Text;
    import classes.ui.ValidatedText;
    import com.bit101.components.ComboBox;
    import com.flashfla.utils.ArrayUtil;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;

    public class FilterItemButton extends Box
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        private var updater:PopupFilterManager;
        private var filter:EngineLevelFilter;

        private var combo_stat:ComboBox;
        private var input_box:BoxText;
        private var combo_compare:ComboBox;
        private var remove_button:BoxButton;

        public function FilterItemButton(parent:DisplayObjectContainer, xpos:Number, ypos:Number, filter:EngineLevelFilter, updater:PopupFilterManager)
        {
            this.filter = filter;
            this.updater = updater;
            super(parent, xpos + 23, ypos, false, false);
            super.setSize(parent.parent.width - xpos - 30, 33);

            init();
        }

        protected function init():void
        {
            remove_button = new BoxButton(this, -23, 0, 23, height, "×", 10, e_clickRemovefilter);
            remove_button.color = 0xFF0000;
            remove_button.normalAlpha = 0.35;
            remove_button.activeAlpha = 0.45;

            var typeText:Text;
            var xOff:Number = 0;

            switch (filter.type)
            {
                case EngineLevelFilter.FILTER_STATS:
                    combo_stat = new ComboBox(this, 8, 4, "", EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS_STAT, "compare_stat"));
                    
                    combo_stat.addEventListener(Event.SELECT, e_valueStatChange);
                    combo_stat.setSize(130, 26);
                    combo_stat.selectedItemByData = filter.input_stat;
                    combo_stat.fontSize = 11;

                    xOff += combo_stat.x + combo_stat.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.FILTERS_NUMBER);
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    input_box = new ValidatedText(this, xOff, 4, 107, 24, ValidatedText.R_FLOAT, e_valueNumberChange);
                    input_box.text = filter.input_number.toString();
                    break;

                case EngineLevelFilter.FILTER_SONG_FLAGS:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS_FLAGS, "compare_flags"));
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    combo_stat = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createSimpleOptions(GlobalVariables.SONG_ICON_TEXT_FLAG));
                    combo_stat.addEventListener(Event.SELECT, e_valueComboNumberChange);
                    combo_stat.setSize(130, 26);
                    combo_stat.selectedItemByData = filter.input_number;
                    combo_stat.fontSize = 11;
                    break;

                case EngineLevelFilter.FILTER_SONG_ACCESS:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    var playableText:Text = new Text(this, xOff, 6, _lang.string("filter_setting_playable"));
                    break;

                case EngineLevelFilter.FILTER_AAA_EQUIV:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    var improvementText:Text = new Text(this, xOff, 6, _lang.string("filter_setting_possible"));
                    break;

                case EngineLevelFilter.FILTER_SONG_TYPE:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    combo_stat = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_SONG_TYPES, "compare_types"));
                    combo_stat.addEventListener(Event.SELECT, e_valueComboNumberChange);
                    combo_stat.setSize(130, 26);
                    combo_stat.selectedItemByData = filter.input_number;
                    combo_stat.fontSize = 11;
                    break;

                case EngineLevelFilter.FILTER_ARROWCOUNT:
                case EngineLevelFilter.FILTER_BPM:
                case EngineLevelFilter.FILTER_DIFFICULTY:
                case EngineLevelFilter.FILTER_MAX_NPS:
                case EngineLevelFilter.FILTER_MIN_NPS:
                case EngineLevelFilter.FILTER_RANK:
                case EngineLevelFilter.FILTER_SCORE:
                case EngineLevelFilter.FILTER_COMBO_SCORE:
                case EngineLevelFilter.FILTER_TIME:
                case EngineLevelFilter.FILTER_SONG_RATING:
                case EngineLevelFilter.FILTER_PERSONAL_SONG_RATING:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.FILTERS_NUMBER);
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    input_box = new ValidatedText(this, xOff, 4, 107, 24, ValidatedText.R_FLOAT, e_valueNumberChange);
                    input_box.text = filter.input_number.toString();
                    break;

                case EngineLevelFilter.FILTER_ID:
                case EngineLevelFilter.FILTER_NAME:
                case EngineLevelFilter.FILTER_STYLE:
                case EngineLevelFilter.FILTER_ARTIST:
                case EngineLevelFilter.FILTER_STEPARTIST:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS_STRING, "compare_string"));
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    input_box = new BoxText(this, xOff, 4, 107, 24);
                    input_box.text = filter.input_string;
                    input_box.addEventListener(Event.CHANGE, e_valueStringChange);
                    break;

                case EngineLevelFilter.FILTER_SONG_GENRE:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;

                    xOff += combo_compare.width + 10;

                    combo_stat = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createSimpleOptionsFromLanguage(_gvars.TOTAL_GENRES, "genre_"));
                    combo_stat.addEventListener(Event.SELECT, e_valueComboNumberChange);
                    combo_stat.setSize(130, 26);
                    combo_stat.selectedItemByData = filter.input_number;
                    combo_stat.fontSize = 11;
                    break;

                case EngineLevelFilter.FILTER_FAVORITE:
                    typeText = new Text(this, 8, 8, _lang.string("filter_type_" + filter.type));

                    xOff += typeText.x + typeText.width + 10;

                    combo_compare = new ComboBox(this, xOff, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(130, 26);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;
                    break;

                default:
                    typeText = new Text(this, 8, 8, filter.type);
                    break;
            }
        }

        private function e_valueBooleanCompareChange(e:Event):void
        {
            var item:Object = e.target.selectedItem;

            if (item.hasOwnProperty("data"))
                filter.inverse = Number(item.data) >= 1;
            else
                filter.inverse = Number(item) >= 1;
        }

        private function e_valueComboNumberChange(e:Event):void
        {
            var item:Object = e.target.selectedItem;

            if (item.hasOwnProperty("data"))
                filter.input_number = Number(item.data);
            else
                filter.input_number = Number(item);
        }

        private function e_valueStatChange(e:Object):void
        {
            var item:Object = e.target.selectedItem;

            if (item.hasOwnProperty("data"))
                filter.input_stat = item.data;
            else
                filter.input_stat = (item as String);
        }

        private function e_valueCompareChange(e:Event):void
        {
            var item:Object = e.target.selectedItem;

            if (item.hasOwnProperty("data"))
                filter.comparison = item.data;
            else
                filter.comparison = (item as String);
        }

        private function e_valueStringChange(e:Event):void
        {
            filter.input_string = input_box.text;
        }

        private function e_valueNumberChange(e:Event):void
        {
            filter.input_number = (input_box as ValidatedText).validate(0);
        }

        private function e_clickRemovefilter(e:Event):void
        {
            if (ArrayUtil.remove(filter, filter.parent_filter.filters))
                updater.draw();
        }
    }
}
