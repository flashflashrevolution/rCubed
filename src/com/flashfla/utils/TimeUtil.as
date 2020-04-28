package com.flashfla.utils
{

    /**
     * @author Jonathan (Velocity)
     */
    public class TimeUtil
    {
        public static function getCurrentDate():String
        {
            return getFormattedDate(new Date());
        }

        public static function getFormattedDate(date:Date):String
        {
            var cHH:Number = date.hoursUTC;
            var cAM:String = "am";
            if (cHH > 12)
            {
                cHH -= 12;
                cAM = "pm";
            }
            else if (cHH == 12)
            {
                cAM = "pm";
            }
            return doubleDigitFormat(cHH) + ":" + doubleDigitFormat(date.minutesUTC) + ":" + doubleDigitFormat(date.secondsUTC) + cAM + ", " + date.dateUTC + "/" + (date.monthUTC + 1) + "/" + date.fullYearUTC;
        }

        public static function getTimezoneOffset():Number
        {
            // Create two dates: one summer and one winter
            var d1:Date = new Date(0, 0, 1);
            var d2:Date = new Date(0, 6, 1);

            // Use current month to determin which to use
            var curMonth:int = new Date().getMonth();
            if (curMonth >= 0 && curMonth <= 5)
            {
                return d1.timezoneOffset;
            }
            else
            {
                return d2.timezoneOffset;
            }
        }

        public static function convertToHHMMSS(_seconds:Number):String
        {
            if (_seconds < 0)
                return "Never";
            var s:Number = _seconds % 60;
            var m:Number = Math.floor((_seconds % 3600) / 60);
            var h:Number = Math.floor(_seconds / (60 * 60));

            var hourStr:String = (h == 0) ? "" : doubleDigitFormat(h) + ":";
            var minuteStr:String = doubleDigitFormat(m) + ":";
            var secondsStr:String = doubleDigitFormat(s);

            return hourStr + minuteStr + secondsStr;
        }

        private static function doubleDigitFormat(_num:uint):String
        {
            if (_num < 10)
            {
                return ("0" + _num);
            }
            return String(_num);
        }
    }
}
