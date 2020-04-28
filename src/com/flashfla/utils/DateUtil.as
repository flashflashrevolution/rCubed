package com.flashfla.utils
{
    import flash.globalization.DateTimeFormatter;

    /**
     * ...
     * @author Zageron
     */
    public class DateUtil
    {
        public static function toRFC822(d:Date):String
        {
            var dtf:DateTimeFormatter = new DateTimeFormatter("en-US");
            dtf.setDateTimePattern("EEE, dd MMMMM yyyy HH.mm.ss");
            return dtf.formatUTC(new Date());
        }
    }
}
