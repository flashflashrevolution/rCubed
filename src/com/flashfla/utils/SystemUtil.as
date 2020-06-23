package com.flashfla.utils
{
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.system.Capabilities;
    import flash.system.System;

    public class SystemUtil
    {
        public static var OS:String;
        public static var flashMajorVersion:int;
        public static var flashMinorVersion:int;
        public static var flashBuildVersion:int;

        private static var isLoaded:Boolean = false;

        public static function init():void
        {
            // Get the player’s version by using the flash.system.Capabilities class.
            var versionArray:Array = StringUtil.splitMultiple(Capabilities.version, [" ", ","]);

            //versionArray = ["WIN", 9, 0, 0];

            OS = versionArray[0].toLowerCase();
            flashMajorVersion = parseInt(versionArray[1]);
            flashMinorVersion = parseInt(versionArray[2]);
            flashBuildVersion = parseInt(versionArray[3]);
            isLoaded = true;
        }

        public static function getMajorVersion():int
        {
            return flashMajorVersion;
        }

        public static function getMinorVersion():int
        {
            return flashMinorVersion;
        }

        public static function getBuildVersion():int
        {
            return flashBuildVersion;
        }

        public static function getOS():String
        {
            return OS;
        }

        public static function getFlashVersion():Object
        {
            return {os: OS, major: flashMajorVersion, minor: flashMinorVersion, build: flashBuildVersion};
        }

        public static function isFlashNewerThan(major:int, minor:int = 0, build:int = 0):Boolean
        {
            if (flashMajorVersion > major)
                return true;
            if (flashMajorVersion < major)
                return false;

            if (minor <= 0)
                return true;
            if (flashMinorVersion < minor)
                return false;
            if (build <= 0)
                return true;
            if (flashBuildVersion >= build)
                return true;

            return false;
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
