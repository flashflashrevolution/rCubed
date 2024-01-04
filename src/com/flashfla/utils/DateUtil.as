package com.flashfla.utils
{
    import flash.globalization.DateTimeFormatter;

    public class DateUtil
    {
        public static function toRFC822(d:Date):String
        {
            var dtf:DateTimeFormatter = new DateTimeFormatter("en-US");
            dtf.setDateTimePattern("EEE, dd MMMMM yyyy HH.mm.ss");
            return dtf.formatUTC(new Date());
        }

        public static function minutesToString(length:int):String
        {
            if (length == 10080)
                return "1 week";
            if (length == 20160)
                return "2 weeks";
            if (length == 40320)
                return "1 month";
            if (length == 241920)
                return "6 months";

            // Years
            var years:int = Math.floor(length / 525600);
            length -= (years * 525600);

            // days
            var days:int = Math.floor(length / 1440);
            length -= (days * 1440);

            // hours
            var hours:int = Math.floor(length / 60);
            length -= (hours * 60);

            // minutes
            var minutes:int = length;

            // Format and return
            var timeParts:Array = [];
            var sections:Array = [['year', years],
                ['day', days],
                ['hour', hours],
                ['minute', minutes]];

            for each (var section:Array in sections)
            {
                if (section[1] > 0)
                {
                    timeParts.push(section[1] + ' ' + section[0] + (section[1] == 1 ? '' : 's'));
                }
            }

            return timeParts.join(", ");
        }
    }
}
