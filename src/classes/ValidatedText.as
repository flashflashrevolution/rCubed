package classes
{
    import flash.text.TextFormat;

    dynamic public class ValidatedText extends BoxText
    {
        public static const PARSE_COLOR:uint = 2;
        public static const PARSE_FLOAT:uint = 1;
        public static const PARSE_INT:uint = 0;

        public function ValidatedText(width:int = 100, height:int = 20, textformat:TextFormat = null)
        {
            super(width, height, textformat);
        }

        private function renderValid():void
        {
            super.color = 0xFFFFFF;
            super.borderColor = 0xFFFFFF;
        }

        private function renderInvalid():void
        {
            super.color = 0xFF0000;
            super.borderColor = 0xFF0000;
        }

        /**
         * Called to validate this class's text under a parsing mode.
         * Modes include the following:
         * --> PARSE_INT: Parses the text as an integer.
         * --> PARSE_FLOAT: Parses the text as a float.
         * --> PARSE_COLOR: Parses the text as a color (hexadecimal integer).
         * The parsed number is then checked to see if it's not NaN and it's within the bounds supplied by the users of this function.
         * If the text is valid:
         * --> The BoxText is rendered to display its default colours; otherwise, it turns red.
         * --> The parsed number is returned; otherwise, the default value is returned.
         * @param mode Parsing mode
         * @param default_value Value returned if validation fails
         * @param lower_bound Lower bound of valid region
         * @param upper_bound Upper bound of valid region
         * @return Number The parsed number if validation succeeds; the default value if validation fails
         */
        public function validate(mode:uint, default_value:Number, lower_bound:Number = NaN, upper_bound:Number = NaN):Number
        {
            var parse_color:Boolean = Boolean(mode & PARSE_COLOR);
            var parse_float:Boolean = !parse_color && Boolean(mode & PARSE_FLOAT);
            var radix:int = parse_color ? 16 : 0;

            var testString:String = this.text;
            if (parse_color)
                testString = "0x" + testString.replace("#", "");

            var to_test:Number = (parse_float) ? parseFloat(testString) : parseInt(testString, radix);
            var valid:Boolean = !(isNaN(to_test) || (!isNaN(lower_bound) && to_test < lower_bound) || (!isNaN(upper_bound) && to_test > upper_bound));
            if (valid)
            {
                renderValid();
                return to_test;
            }
            else
            {
                renderInvalid();
                return default_value;
            }
        }
    }
}
