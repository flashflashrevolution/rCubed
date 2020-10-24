package com.flashfla.utils
{
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.system.Capabilities;
    import flash.system.System;

    public class SystemUtil
    {
        public static var versionArray:Array;
        public static var OS:String;
        public static var flashMajorVersion:int;
        public static var flashMinorVersion:int;
        public static var flashBuildVersion:int;

        {
            // Get the player’s version by using the flash.system.Capabilities class.
            versionArray = StringUtil.splitMultiple(Capabilities.version, [" ", ","]);

            //versionArray = ["WIN", 9, 0, 0];

            OS = versionArray[0].toLowerCase();
            flashMajorVersion = parseInt(versionArray[1]);
            flashMinorVersion = parseInt(versionArray[2]);
            flashBuildVersion = parseInt(versionArray[3]);
        }

        public static function getFlashVersion():Object
        {
            return {"os": OS, "major": flashMajorVersion, "minor": flashMinorVersion, "build": flashBuildVersion};
        }

        public static function gc():void
        {
            System.gc();
        }

        static public function setClipboard(value:String):Boolean
        {
            // FP10+
            try
            {
                Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, value);
                return true;
            }
            catch (e:Error)
            {
            }

            // FP9
            try
            {
                System.setClipboard(value);
                return true;
            }
            catch (e:Error)
            {
            }

            return false;
        }
    }
}
