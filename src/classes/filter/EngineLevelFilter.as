package classes.filter
{
    import classes.Language;
    import classes.SongInfo;
    import classes.User;
    import classes.user.UserSongData;
    import classes.user.UserSongNotes;

    public class EngineLevelFilter
    {
        /// Filter Types
        public static const FILTER_AND:String = "and";
        public static const FILTER_OR:String = "or";
        public static const FILTER_STYLE:String = "style";
        public static const FILTER_NAME:String = "name";
        public static const FILTER_ARTIST:String = "artist";
        public static const FILTER_STEPARTIST:String = "stepartist";
        public static const FILTER_BPM:String = "bpm";
        public static const FILTER_DIFFICULTY:String = "difficulty";
        public static const FILTER_AAA_EQUIV:String = "aaa_eq";
        public static const FILTER_ARROWCOUNT:String = "arrows";
        public static const FILTER_ID:String = "id";
        public static const FILTER_MIN_NPS:String = "min_nps";
        public static const FILTER_MAX_NPS:String = "max_nps";
        public static const FILTER_RANK:String = "rank";
        public static const FILTER_SCORE:String = "score";
        public static const FILTER_COMBO_SCORE:String = "combo_score";
        public static const FILTER_STATS:String = "stats";
        public static const FILTER_TIME:String = "time";
        public static const FILTER_SONG_RATING:String = "song_rating";
        public static const FILTER_PERSONAL_SONG_RATING:String = "personal_rating";
        public static const FILTER_SONG_FLAGS:String = "song_flags";
        public static const FILTER_SONG_ACCESS:String = "song_access";
        public static const FILTER_SONG_TYPE:String = "song_type";
        public static const FILTER_SONG_GENRE:String = "song_genre";
        public static const FILTER_FAVORITE:String = "song_favorite";


        public static const FILTERS:Array = [FILTER_AND, FILTER_OR, FILTER_ARTIST, FILTER_STEPARTIST,
            FILTER_STYLE, FILTER_TIME, FILTER_DIFFICULTY, FILTER_AAA_EQUIV, FILTER_ARROWCOUNT, FILTER_MIN_NPS, FILTER_MAX_NPS,
            FILTER_RANK, FILTER_SCORE, FILTER_STATS, FILTER_SONG_FLAGS, FILTER_SONG_ACCESS, FILTER_SONG_TYPE,
            FILTER_SONG_RATING, FILTER_PERSONAL_SONG_RATING, FILTER_SONG_GENRE, FILTER_FAVORITE];
        public static const FILTERS_STAT:Array = ["perfect", "good", "average", "miss", "boo", "combo"];
        public static const FILTERS_NUMBER:Array = ["=", "!=", "<=", ">=", "<", ">"];
        public static const FILTERS_STRING:Array = ["equal", "start_with", "end_with", "contains"];
        public static const FILTERS_FLAGS:Array = ["equal", "not_equal", "contains", "not_contains"];

        public static const FILTERS_BOOLEAN:Array = ["is", "isnt"];
        public static const FILTERS_SONG_TYPES:Array = ["public", "token", "purchased", "secret"];

        public var name:String;
        private var _type:String;
        public var comparison:String;
        public var inverse:Boolean = false;
        public var is_default:Boolean = false;

        public var parent_filter:EngineLevelFilter;
        public var filters:Array = [];
        public var input_number:Number = 0;
        public var input_string:String = "";
        public var input_stat:String = FILTERS_STAT[0]; // Display4

        public function EngineLevelFilter(topLevelFilter:Boolean = false)
        {
            if (topLevelFilter)
            {
                name = "Untitled Filter";
                type = "and";
                filters = [];
            }
        }

        public function get type():String
        {
            return _type;
        }

        public function set type(value:String):void
        {
            _type = value;
            setDefaultComparison();
        }

        /**
         * Process the engine level to see if it has passed the requirements of the filters currently set.
         *
         * @param	songInfo	Engine Level to be processed.
         * @param	userData	User Data from comparisons.
         * @return	Song passed filter.
         */
        public function process(songInfo:SongInfo, userData:User):Boolean
        {
            switch (type)
            {
                case FILTER_AND:
                    if (!filters || filters.length == 0)
                        return true;

                    // Check ALL Sub Filters Pass
                    for each (var filter_and:EngineLevelFilter in filters)
                    {
                        if (!filter_and.process(songInfo, userData))
                            return false;
                    }
                    return true;

                case FILTER_OR:
                    if (!filters || filters.length == 0)
                        return true;

                    var out:Boolean = false;
                    // Check if any Sub Filters Pass
                    for each (var filter_or:EngineLevelFilter in filters)
                    {
                        if (filter_or.process(songInfo, userData))
                            out = true;
                    }
                    return out;

                case FILTER_ID:
                    return compareNumber(songInfo.level, input_number);

                case FILTER_NAME:
                    return compareString(songInfo.name, input_string);

                case FILTER_STYLE:
                    return compareString(songInfo.style, input_string);

                case FILTER_ARTIST:
                    return compareString(songInfo.author, input_string);

                case FILTER_STEPARTIST:
                    return compareString(songInfo.stepauthor, input_string);

                case FILTER_BPM:
                    return true; // TODO: compareNumber(songData.bpm, input_number);

                case FILTER_DIFFICULTY:
                    return compareNumber(songInfo.difficulty, input_number);

                case FILTER_ARROWCOUNT:
                    return compareNumber(songInfo.note_count, input_number);

                case FILTER_MIN_NPS:
                    return compareNumber(songInfo.min_nps, input_number);

                case FILTER_MAX_NPS:
                    return compareNumber(songInfo.max_nps, input_number);

                case FILTER_RANK:
                    return compareNumber(userData.getLevelRank(songInfo).rank, input_number);

                case FILTER_SCORE:
                    return compareNumber(userData.getLevelRank(songInfo).score, input_number);

                case FILTER_STATS:
                    return compareNumber(userData.getLevelRank(songInfo)[input_stat], input_number);

                case FILTER_TIME:
                    return compareNumber(songInfo.time_secs, input_number);

                case FILTER_SONG_RATING:
                    return compareNumber(songInfo.song_rating, input_number);

                case FILTER_PERSONAL_SONG_RATING:
                    return compareNumber(userData.getSongRating(songInfo), input_number);

                case FILTER_SONG_FLAGS:
                    return compareSongFlag(songInfo, userData.getLevelRank(songInfo), input_number);

                case FILTER_AAA_EQUIV:
                    if (!songInfo.engine)
                        return greaterThan(songInfo.difficulty, userData.skill_rating_levelranks[userData.skill_rating_levelranks.length - 1].equiv) && userData.getLevelRank(songInfo).rawscore < songInfo.score_raw;

                case FILTER_SONG_ACCESS:
                    return compareNumberEqual(songInfo.access, input_number);

                case FILTER_SONG_TYPE:
                    return compareSongType(songInfo, input_number);

                case FILTER_SONG_GENRE:
                    return compareNumberEqual(songInfo.genre, input_number + 1);

                case FILTER_FAVORITE:
                    var details:UserSongData = UserSongNotes.getSongUserInfo(songInfo);
                    if (details)
                        return compareNumberEqual(details.song_favorite ? 0 : 1, input_number);
                    return compareNumberEqual(1, input_number);
            }
            return true;
        }

        private function compareSongType(songInfo:SongInfo, value:Number):Boolean
        {
            var out:Boolean = songInfo.song_type == value;
            return inverse ? !out : out;
        }

        /**
         * Compares a Bitmask from Song Flags with a Bit Flag
         * @param	flag_bits
         * @param	bitmask
         */
        private function compareSongFlag(songInfo:SongInfo, levelRank:Object, value:Number):Boolean
        {
            var flag_int:int = GlobalVariables.getSongIconIndex(songInfo, levelRank);
            var flag_bits:int = GlobalVariables.getSongIconIndexBitmask(songInfo, levelRank);
            var bitmask:int = 1 << value;

            if (isNaN(flag_int) || isNaN(flag_bits) || isNaN(bitmask))
                return true;

            switch (comparison)
            {
                case "equal":
                    return flag_int == value;

                case "not_equal":
                    return flag_int != value;

                case "contains":
                    return (flag_bits & bitmask) != 0;

                case "not_contains":
                    return (flag_bits & bitmask) == 0;
            }
            return false;
        }

        /**
         * Compares 2 Number values with the selected comparision.
         * @param	value1	Input Value
         * @param	value2	Value to compare to.
         * @param	comparison	Method of comparision.
         * @return	If comparision was successful.
         */
        private function compareNumber(value1:Number, value2:Number):Boolean
        {
            if (isNaN(value1) || isNaN(value2))
                return true;
            switch (comparison)
            {
                case "=":
                    return value1 == value2;

                case "!=":
                    return value1 != value2;

                case "<=":
                    return value1 <= value2;

                case ">=":
                    return value1 >= value2;

                case "<":
                    return value1 < value2;

                case ">":
                    return value1 > value2;
            }
            return false;
        }

        /**
         * Compares 2 Number values with a greater than comparison, unless inverted.
         * @param	value1	Input Value
         * @param	value2	Value to compare to.
         * @param	inverse	Use inverse comparisons.
         * @return	If comparision was successful.
         */
        private function greaterThan(value1:Number, value2:Number):Boolean
        {
            if (isNaN(value1) || isNaN(value2))
                return true;
            
            var out:Boolean = value1 > value2;
            return inverse ? !out : out;
        }

        private function compareNumberEqual(value1:Number, value2:Number):Boolean
        {
            var out:Boolean = value1 == value2;
            return inverse ? !out : out;
        }

        /**
         * Compares 2 String values with the selected comparision.
         * @param	value1	Input Value
         * @param	value2	Value to compare to.
         * @param	comparison	Method of comparision.
         * @param	inverse	Use inverse comparisions.
         * @return	If comparision was successful.
         */
        private function compareString(value1:String, value2:String):Boolean
        {
            if (value1 == null || value2 == null)
                return true;

            var out:Boolean = false;
            value1 = value1.toLowerCase();
            value2 = value2.toLowerCase();

            switch (comparison)
            {
                case "equal":
                    out = (value1 == value2);
                    break;

                case "start_with":
                    out = (value2 == value1.substring(0, value2.length));
                    break;

                case "end_with":
                    out = (value2 == value1.substring(value1.length - value2.length));
                    break;

                case "contains":
                    out = (value1.indexOf(value2) >= 0);
                    break;
            }
            return inverse ? !out : out;
        }

        public function setup(obj:Object):void
        {
            if (obj.hasOwnProperty("type"))
                type = obj["type"];

            if (obj.hasOwnProperty("is_default"))
                is_default = obj["is_default"];

            if (obj.hasOwnProperty("filters"))
            {
                var in_filter:EngineLevelFilter;
                var in_filters:Array = obj["filters"];
                for (var i:int = 0; i < in_filters.length; i++)
                {
                    in_filter = new EngineLevelFilter();
                    in_filter.setup(in_filters[i]);
                    in_filter.parent_filter = this;
                    filters.push(in_filter);
                }
                if (obj.hasOwnProperty("name"))
                    name = obj["name"];

            }
            else
            {
                if (obj.hasOwnProperty("comparison"))
                    comparison = obj["comparison"];

                if (obj.hasOwnProperty("input_number"))
                    input_number = obj["input_number"];

                if (obj.hasOwnProperty("input_string"))
                    input_string = obj["input_string"];

                if (obj.hasOwnProperty("input_stat"))
                    input_stat = obj["input_stat"];

                if (obj.hasOwnProperty("inverse"))
                    inverse = obj["inverse"];
            }
        }

        public function export():Object
        {
            var obj:Object = {"type": type};

            if (is_default)
                obj["is_default"] = is_default;

            // Filter AND/OR
            if (type == FILTER_AND || type == FILTER_OR)
            {
                var ex_array:Array = [];
                for (var i:int = 0; i < filters.length; i++)
                {
                    ex_array.push(filters[i].export());
                }

                if (ex_array.length > 0) // Don't export blank filters.
                    obj["filters"] = ex_array;

                if (name && name != "")
                    obj["name"] = name;
            }
            else
            {
                obj["comparison"] = comparison;
                obj["input_number"] = input_number;
                obj["input_string"] = input_string;

                if (inverse)
                    obj["inverse"] = inverse;

                if (type == FILTER_STATS)
                    obj["input_stat"] = input_stat;
            }
            return obj;
        }

        public function setDefaultComparison():void
        {
            switch (type)
            {
                case FILTER_STATS:
                    input_stat = FILTERS_STAT[0];
                    comparison = FILTERS_NUMBER[0];
                    break;

                case FILTER_SONG_FLAGS:
                    input_number = 0;
                    comparison = FILTERS_FLAGS[0];
                    break;

                case FILTER_SONG_TYPE:
                    input_number = 0;
                    comparison = FILTERS_SONG_TYPES[0];
                    break;

                case FILTER_ARROWCOUNT:
                case FILTER_BPM:
                case FILTER_DIFFICULTY:
                case FILTER_MAX_NPS:
                case FILTER_MIN_NPS:
                case FILTER_RANK:
                case FILTER_SCORE:
                case FILTER_TIME:
                case FILTER_SONG_RATING:
                case FILTER_PERSONAL_SONG_RATING:
                    comparison = FILTERS_NUMBER[0];
                    break;

                case FILTER_ID:
                case FILTER_NAME:
                case FILTER_STYLE:
                case FILTER_ARTIST:
                case FILTER_STEPARTIST:
                    comparison = FILTERS_STRING[0];
                    break;
            }
        }

        public function toString():String
        {
            return type + " [" + comparison + "]" + (!isNaN(input_number) ? " input_number=" + input_number : "") + (input_string != null ? " input_string=" + input_string : "") + (input_stat != null ? " input_stat=" + input_stat : "");
        }

        static public function createSimpleOptions(filtersString:Array):Array
        {
            var options:Array = [];
            for (var i:int = 0; i < filtersString.length; i++)
            {
                options.push({"label": filtersString[i], "data": i});
            }
            return options;
        }

        static public function createSimpleOptionsFromLanguage(endIndex:int, prefix:String = "", suffix:String = "", startIndex:int = 0):Array
        {
            var removeHtmlRegExp:RegExp = new RegExp("<[^<]+?>", "gi");
            var _lang:Language = Language.instance;
            var options:Array = [];
            for (var i:int = startIndex; i < endIndex; i++)
            {
                options.push({"label": _lang.stringSimple(prefix + i + suffix).replace(removeHtmlRegExp, ""), "data": i});
            }
            return options;
        }

        static public function createOptions(filtersString:Array, type:String):Array
        {
            var _lang:Language = Language.instance;
            var options:Array = [];
            for (var i:int = 0; i < filtersString.length; i++)
            {
                options.push({"label": _lang.stringSimple("filter_" + type + "_" + filtersString[i]), "data": filtersString[i]});
            }

            return options;
        }

        static public function createIndexOptions(filtersString:Array, type:String):Array
        {
            var _lang:Language = Language.instance;
            var options:Array = [];
            for (var i:int = 0; i < filtersString.length; i++)
            {
                options.push({"label": _lang.stringSimple("filter_" + type + "_" + filtersString[i]), "data": i});
            }

            return options;
        }
    }
}
