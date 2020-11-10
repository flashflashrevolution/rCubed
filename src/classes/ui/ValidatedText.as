package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.text.TextFormat;

    dynamic public class ValidatedText extends BoxText
    {
        private static const PARSE_COLOR:uint = 2;
        private static const PARSE_FLOAT:uint = 1;
        private static const PARSE_INT:uint = 0;

        public static const R_FLOAT_P:uint = 0;
        public static const R_FLOAT:uint = 1;
        public static const R_INT_P:uint = 2;
        public static const R_INT:uint = 3;
        public static const R_COLOR:uint = 4;
        public static const R_ALL:uint = 5;

        private var m_parseMode:uint = PARSE_INT;
        private var m_validator:RegExp;

        private var _listener:Function = null;

        /**
         * The ValidatedText constructor.
         * restrict_mode determines what characters could be entered into the textfield:
         * --> R_FLOAT_P: A positive decimal.
         * --> R_FLOAT: A decimal.
         * --> R_INT_P: A positive integer.
         * --> R_INT: An integer.
         * --> R_COLOR: A hex string, including the pound ('#') sign.
         * --> R_ALL: No restriction.
         * @param width Width of the textfield
         * @param height Height of the textfield
         * @param restrict_mode Which restricted character set to be used
         * @param textformat TextFormat of the textfield
         */
        public function ValidatedText(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:int = 0, height:int = 0, restrict_mode:uint = 0, listener:Function = null, textformat:TextFormat = null)
        {
            super(parent, xpos, ypos, width, height, textformat);
            switch (restrict_mode)
            {
                case R_FLOAT_P:
                    this.restrict = "0-9.";
                    m_parseMode = PARSE_FLOAT;
                    m_validator = /^\d*\.?\d*$/;
                    break;
                case R_FLOAT:
                    this.restrict = "\\-0-9.";
                    m_parseMode = PARSE_FLOAT;
                    m_validator = /^-?\d*\.?\d*$/;
                    break;
                case R_INT_P:
                    this.restrict = "0-9";
                    m_parseMode = PARSE_INT;
                    break;
                case R_INT:
                    this.restrict = "\\-0-9";
                    m_parseMode = PARSE_INT;
                    m_validator = /^-?\d+$/;
                    break;
                case R_COLOR:
                    this.restrict = "#0-9a-f";
                    m_parseMode = PARSE_COLOR;
                    m_validator = /^#[0-9a-f]{6}$/;
                    break;
            }

            if (listener)
            {
                this._listener = listener;
                this.addEventListener(Event.CHANGE, listener);
            }
        }

        override public function dispose():void
        {
            if (this._listener != null)
                this.removeEventListener(Event.CHANGE, this._listener);
            super.dispose();
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
         * Called to validate the text of a ValidatedText according to the restricted character set.
         * First, the text is checked if it passes a regex test.
         * Then, the parsed number is checked to see if it's not NaN and it's within the bounds supplied by the users of this function.
         * If the text is valid:
         * --> The BoxText is rendered to display its default colours; otherwise, it turns red.
         * --> The parsed number is returned; otherwise, the default value is returned.
         * @param default_value Value returned if validation fails
         * @param lower_bound Lower bound of valid region
         * @param upper_bound Upper bound of valid region
         * @return Number The parsed number if validation succeeds; the default value if validation fails
         */
        public function validate(default_value:Number, lower_bound:Number = NaN, upper_bound:Number = NaN):Number
        {
            var parse_color:Boolean = (m_parseMode == PARSE_COLOR);
            var parse_float:Boolean = (m_parseMode == PARSE_FLOAT);
            var radix:int = parse_color ? 16 : 0;

            var testString:String = this.text;
            var regex_passed:Boolean = (m_validator != null) ? m_validator.test(testString) : true;
            if (parse_color)
                testString = "0x" + testString.replace("#", "");

            var to_test:Number = (parse_float) ? parseFloat(testString) : parseInt(testString, radix);
            var valid:Boolean = !(!regex_passed || isNaN(to_test) || (!isNaN(lower_bound) && to_test < lower_bound) || (!isNaN(upper_bound) && to_test > upper_bound));
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
