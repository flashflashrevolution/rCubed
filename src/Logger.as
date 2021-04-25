package
{
    import com.flashfla.utils.TimeUtil;
    import flash.utils.getTimer;
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
    import flash.events.SecurityErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.FileMode;
    import flash.events.ErrorEvent;

    public class Logger
    {
        private static var LOG_FILE:File;
        private static var LOG_STREAM:FileStream;
        public static const DEBUG_LINES:Array = ["Info: ", "Debug: ", "Warning: ", "Error: ", "Fatal: "];
        public static const INFO:Number = 0; // Gray
        public static const DEBUG:Number = 1; // Black
        public static const WARNING:Number = 2; // Orange
        public static const ERROR:Number = 3; // Red
        public static const NOTICE:Number = 4; // Purple

        public static var enabled:Boolean = CONFIG::debug;
        public static var file_log:Boolean = false;
        public static var history:Array = [];

        private static var file_log_buffer:String = "";
        private static var file_log_buffer_time:Number = 0;

        public static function init():void
        {
            // Check for special file to enable file logging.
            if (new File(AirContext.getAppPath("logging.txt")).exists)
            {
                trace("Logging Flag Found, enabling.")
                file_log = true;
                enabled = true;
            }

            if (file_log && LOG_STREAM == null)
            {
                var now:Date = new Date();
                var filename:String = AirContext.createFileName(now.toLocaleString(), " ");
                LOG_FILE = new File(AirContext.getAppPath("logs/" + filename + ".txt"));
                LOG_STREAM = new FileStream();
                LOG_STREAM.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_logFileFail);
                LOG_STREAM.addEventListener(IOErrorEvent.IO_ERROR, e_logFileFail);
                LOG_STREAM.open(LOG_FILE, FileMode.WRITE);
                LOG_STREAM.writeUTFBytes("======================" + filename + "======================\n");
                LOG_STREAM.writeUTFBytes("R3 Version: " + Constant.AIR_VERSION + " | " + CONFIG::timeStamp + "\n");
                LOG_STREAM.close();
            }

            function e_logFileFail(e:Event):void
            {
                trace("Unable to use file logging.");
                LOG_STREAM.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, e_logFileFail);
                LOG_STREAM.removeEventListener(IOErrorEvent.IO_ERROR, e_logFileFail);
                LOG_FILE = null;
                LOG_STREAM = null;
            }
        }

        public static function divider(clazz:*):void
        {
            log(clazz, WARNING, "------------------------------------------------------------------------------------------------", true);
        }

        public static function info(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, INFO, text, simple);
        }

        public static function debug(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, DEBUG, text, simple);
        }

        public static function warning(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, WARNING, text, simple);
        }

        public static function error(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, ERROR, text, simple);
        }

        public static function notice(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, NOTICE, text, simple);
        }

        public static function log(clazz:*, level:int, text:*, simple:Boolean = false):void
        {
            // Check if Logger Enabled
            if (!enabled)
                return;

            // Store History
            var currentTime:Number = getTimer();
            history.push([currentTime, class_name(clazz), level, text, simple]);
            if (history.length > 250)
                history.unshift();

            // Create Log Message
            var msg:String = "";
            if (text is Error)
            {
                var err:Error = (text as Error);
                msg = "Error: " + exception_error(err);
            }
            else
            {
                msg = text;
            }

            msg = ((!simple ? "[" + TimeUtil.convertToHHMMSS(getTimer() / 1000) + "][" + class_name(clazz) + "] " : "") + msg);

            // Display
            trace(level + ":" + msg);

            if (LOG_STREAM != null)
            {
                file_log_buffer += (msg + "\n");

                // Buffer file writes if within the last 150ms of a write to prevent file writing bottlenecks.
                if (currentTime - file_log_buffer_time > 150)
                {
                    LOG_STREAM.open(LOG_FILE, FileMode.APPEND);
                    LOG_STREAM.writeUTFBytes(file_log_buffer);
                    LOG_STREAM.close();

                    file_log_buffer = "";
                    file_log_buffer_time = currentTime;
                }
            }
        }

        public static function destroy():void
        {
            if (LOG_STREAM != null)
            {
                if (file_log_buffer.length > 0)
                {
                    LOG_STREAM.open(LOG_FILE, FileMode.APPEND);
                    LOG_STREAM.writeUTFBytes(file_log_buffer);
                    LOG_STREAM.close();
                }
            }
        }

        public static function exception_error(err:Error):String
        {
            return err.name + "\n" + err.message + "\n" + err.errorID + "\n" + err.getStackTrace();
        }

        public static function event_error(e:ErrorEvent):String
        {
            return "(" + e.type + ") " + e.errorID + ": " + e.text;
        }

        public static function class_name(clazz:*):String
        {
            if (clazz is String)
                return clazz;
            var t:String = (Object(clazz).constructor).toString();
            return t.substr(7, t.length - 8);
        }
    }
}
