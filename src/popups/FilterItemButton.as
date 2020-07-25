package popups
{
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxText;
    import classes.Language;
    import classes.Text;
    import classes.filter.EngineLevelFilter;
    import com.bit101.components.ComboBox;
    import com.flashfla.utils.ArrayUtil;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;

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
            parent.addChild(this);
            this.x = xpos;
            this.y = ypos;
            this.filter = filter;
            this.updater = updater;
            super(327, 33, false, false);
        }

        override protected function init():void
        {
            super.init();

            remove_button = new BoxButton(23, height, "X");
            remove_button.x = width;
            remove_button.y = 0;
            remove_button.addEventListener(MouseEvent.CLICK, e_clickRemovefilter);
            addChild(remove_button);

            var typeText:Text;
            switch (filter.type)
            {
                case EngineLevelFilter.FILTER_STATS:
                    combo_stat = new ComboBox(this, 5, 4, "", EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS_STAT, "compare_stat"));
                    combo_stat.addEventListener(Event.SELECT, e_valueStatChange);
                    combo_stat.setSize(120, 25);
                    combo_stat.selectedItemByData = filter.input_stat;
                    combo_stat.fontSize = 11;

                    combo_compare = new ComboBox(this, 130, 4, "", EngineLevelFilter.FILTERS_NUMBER);
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(80, 25);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    input_box = new BoxText(107, 23);
                    input_box.text = filter.input_number.toString();
                    input_box.x = 215;
                    input_box.y = 5;
                    input_box.addEventListener(Event.CHANGE, e_valueNumberChange);
                    addChild(input_box);
                    break;

                case EngineLevelFilter.FILTER_SONG_FLAGS:
                    typeText = new Text(_lang.string("filter_type_" + filter.type));
                    typeText.x = 5;
                    typeText.y = 6;
                    addChild(typeText);

                    combo_compare = new ComboBox(this, 100, 4, "", EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS_FLAGS, "compare_flags"));
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(110, 25);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    combo_stat = new ComboBox(this, 215, 4, "", EngineLevelFilter.createSimpleOptions(GlobalVariables.SONG_ICON_TEXT_FLAG));
                    combo_stat.addEventListener(Event.SELECT, e_valueComboNumberChange);
                    combo_stat.setSize(107, 25);
                    combo_stat.selectedItemByData = filter.input_number;
                    combo_stat.fontSize = 11;
                    break;

                case EngineLevelFilter.FILTER_SONG_ACCESS:
                    typeText = new Text(_lang.string("filter_type_" + filter.type));
                    typeText.x = 5;
                    typeText.y = 6;
                    addChild(typeText);

                    combo_compare = new ComboBox(this, 100, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(110, 25);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;

                    var playableText:Text = new Text(_lang.string("filter_setting_playable"));
                    playableText.x = 215;
                    playableText.y = 6;
                    addChild(playableText);
                    break;

                case EngineLevelFilter.FILTER_SONG_TYPE:
                    typeText = new Text(_lang.string("filter_type_" + filter.type));
                    typeText.x = 5;
                    typeText.y = 6;
                    addChild(typeText);

                    combo_compare = new ComboBox(this, 100, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(110, 25);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;

                    combo_stat = new ComboBox(this, 215, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_SONG_TYPES, "compare_types"));
                    combo_stat.addEventListener(Event.SELECT, e_valueComboNumberChange);
                    combo_stat.setSize(107, 25);
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
                    typeText = new Text(_lang.string("filter_type_" + filter.type));
                    typeText.x = 5;
                    typeText.y = 6;
                    addChild(typeText);

                    combo_compare = new ComboBox(this, 100, 4, "", EngineLevelFilter.FILTERS_NUMBER);
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(110, 25);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    input_box = new BoxText(107, 23);
                    input_box.text = filter.input_number.toString();
                    input_box.x = 215;
                    input_box.y = 5;
                    input_box.addEventListener(Event.CHANGE, e_valueNumberChange);
                    addChild(input_box);
                    break;

                case EngineLevelFilter.FILTER_ID:
                case EngineLevelFilter.FILTER_NAME:
                case EngineLevelFilter.FILTER_STYLE:
                case EngineLevelFilter.FILTER_ARTIST:
                case EngineLevelFilter.FILTER_STEPARTIST:
                    typeText = new Text(_lang.string("filter_type_" + filter.type));
                    typeText.x = 5;
                    typeText.y = 6;
                    addChild(typeText);

                    combo_compare = new ComboBox(this, 100, 4, "", EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS_STRING, "compare_string"));
                    combo_compare.addEventListener(Event.SELECT, e_valueCompareChange);
                    combo_compare.setSize(110, 25);
                    combo_compare.selectedItemByData = filter.comparison;
                    combo_compare.fontSize = 11;

                    input_box = new BoxText(107, 23);
                    input_box.text = filter.input_string;
                    input_box.x = 215;
                    input_box.y = 5;
                    input_box.addEventListener(Event.CHANGE, e_valueStringChange);
                    addChild(input_box);
                    break;
                case EngineLevelFilter.FILTER_SONG_GENRE:
                    typeText = new Text(_lang.string("filter_type_" + filter.type));
                    typeText.x = 5;
                    typeText.y = 6;
                    addChild(typeText);

                    combo_compare = new ComboBox(this, 100, 4, "", EngineLevelFilter.createIndexOptions(EngineLevelFilter.FILTERS_BOOLEAN, "compare_boolean"));
                    combo_compare.addEventListener(Event.SELECT, e_valueBooleanCompareChange);
                    combo_compare.setSize(110, 25);
                    combo_compare.selectedItemByData = filter.inverse ? 1 : 0;
                    combo_compare.fontSize = 11;

                    combo_stat = new ComboBox(this, 215, 4, "", EngineLevelFilter.createSimpleOptionsFromLanguage(_gvars.TOTAL_GENRES, "genre_"));
                    combo_stat.addEventListener(Event.SELECT, e_valueComboNumberChange);
                    combo_stat.setSize(107, 25);
                    combo_stat.selectedItemByData = filter.input_number;
                    combo_stat.fontSize = 11;
                    break;

                default:
                    typeText = new Text(filter.type);
                    typeText.x = 5;
                    typeText.y = 6;
                    addChild(typeText);
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
            var newNumber:Number = Number(input_box.text)
            if (isNaN(newNumber))
                newNumber = 0;
            filter.input_number = newNumber;
        }

        private function e_clickRemovefilter(e:Event):void
        {
            if (ArrayUtil.remove(filter, filter.parent_filter.filters))
                updater.draw();
        }
    }

}
