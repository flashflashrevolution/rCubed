package
{
    import classes.Alert;
    import classes.Language;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.sprintf;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;

    public class Updater
    {
        private static const _lang:Language = Language.instance;
        private static var didUpdate:Boolean = false;

        public static function handle(siteVersion:String, updateURL:String):void
        {
            if (!siteVersion || !updateURL || didUpdate || skipUpdate())
                return;

            // Only Update check once
            didUpdate = true;

            var airUpdateCheck:int = compareVersions(siteVersion);

            // No Update
            if (airUpdateCheck >= 0)
                return;

            //Alert.add(siteVersion + " " + (airUpdateCheck == -1 ? "&gt;" : (airUpdateCheck == 1 ? "&lt;" : "==")) + " " + Constant.AIR_VERSION, 240);

            var swfDownload:URLLoader = new URLLoader();
            swfDownload.dataFormat = URLLoaderDataFormat.BINARY;
            swfDownload.addEventListener(Event.COMPLETE, e_onComplete);
            swfDownload.addEventListener(IOErrorEvent.IO_ERROR, e_onError);
            swfDownload.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_onError);
            swfDownload.load(new URLRequest(URLs.resolve(updateURL)));

            function e_onComplete(e:Event):void
            {
                e_removeEvents();
                var data:ByteArray = e.target.data;
                Logger.info("Updater", "Game Download Finished [" + NumberUtil.bytesToString(data.length) + "]");

                try
                {
                    AirContext.writeFile(Main.SWF_FILE, data, 0, e_writeError);
                    Alert.add(sprintf(_lang.string("air_game_update_complete"), {"old": Constant.AIR_VERSION, "new": siteVersion}), 240, Alert.DARK_GREEN);
                }
                catch (e:Error)
                {
                    Logger.error("Updater", "Update SWF Write Exception Error:" + Logger.exception_error(e));
                    Alert.add(_lang.string("air_game_update_error"), 240, Alert.RED);
                }
            }

            function e_onError(e:ErrorEvent):void
            {
                e_removeEvents();
                Logger.error("Updater", "SWF Download Error:" + Logger.event_error(e));
                Alert.add(_lang.string("air_game_update_error"), 240, Alert.RED);
            }

            function e_writeError(e:ErrorEvent):void
            {
                Logger.error("Updater", "Update SWF Write Error Event:" + Logger.event_error(e));
                Alert.add(_lang.string("air_game_update_error"), 240, Alert.RED);
            }

            function e_removeEvents():void
            {
                swfDownload.removeEventListener(Event.COMPLETE, e_onComplete);
                swfDownload.removeEventListener(IOErrorEvent.IO_ERROR, e_onError);
                swfDownload.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, e_onError);
            }
        }

        public static function compareVersions(serverVersionString:String):int
        {
            var gameVersion:Array = Constant.AIR_VERSION.split(".").map(function(item:*, index:int, array:Array):int
            {
                return parseInt(item);
            });

            var serverVersion:Array = serverVersionString.split(".").map(function(item:*, index:int, array:Array):int
            {
                return parseInt(item);
            });

            var length:int = Math.max(gameVersion.length, serverVersion.length);
            for (var i:int = 0; i < length; i++)
            {
                var thisPart:int = i < gameVersion.length ? gameVersion[i] : 0;
                var thatPart:int = i < serverVersion.length ? serverVersion[i] : 0;

                if (thisPart < thatPart)
                    return -1;
                if (thisPart > thatPart)
                    return 1;
            }
            return 0;
        }

        private static function skipUpdate():Boolean
        {
            return AirContext.doesFileExist("skip_update.txt") || CONFIG::debug;
        }
    }
}
