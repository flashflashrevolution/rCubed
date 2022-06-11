package
{
    import com.flashfla.utils.TimeUtil;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.system.Capabilities;
    import flash.utils.getTimer;

    public class Logger
    {
        private static var LOG_FILE:File;
        private static var LOG_STREAM:FileStream;

        private static const DEBUG_LINES:Array = ["Info: ", "Debug: ", "Warning: ", "Error: ", "Success: "];
        private static const DEBUG_COLORS:Array = ["", "\u001b[1;35m", "\u001b[1;33m", "\u001b[1;31m", "\u001b[1;32m"];
        private static const DEBUG_COLOR_RESET:String = "\u001b[0m";

        public static const INFO:Number = 0; // Blue
        public static const DEBUG:Number = 1; // Purple
        public static const WARNING:Number = 2; // Yellow
        public static const ERROR:Number = 3; // Red
        public static const SUCCESS:Number = 4; // Green

        public static var enabled:Boolean = CONFIG::debug;
        public static var file_log:Boolean = false;
        public static var history:Array = [];

        private static var file_log_buffer:String = "";
        private static var file_log_buffer_time:Number = 0;

        public static function init():void
        {
            // Check for special file to enable file logging.
            if (AirContext.doesFileExist("logging.txt"))
            {
                trace("Logging Flag Found, enabling.");
                file_log = true;
                enabled = true;
            }

            initLogFile();
        }

        public static function initLogFile():void
        {
            if (file_log && LOG_STREAM == null)
            {
                var now:Date = new Date();
                var filename:String = AirContext.createFileName(now.toLocaleString(), " ");
                LOG_FILE = AirContext.getAppFile("logs/" + filename + ".txt");
                LOG_STREAM = new FileStream();
                LOG_STREAM.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_logFileFail);
                LOG_STREAM.addEventListener(IOErrorEvent.IO_ERROR, e_logFileFail);
                LOG_STREAM.open(LOG_FILE, FileMode.WRITE);
                LOG_STREAM.writeUTFBytes("======================" + filename + "======================\n");
                LOG_STREAM.writeUTFBytes("OS: " + Capabilities.os + " | " + Capabilities.version + "\n");
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

        public static function enableLogger():void
        {
            file_log = true;
            enabled = true;
            initLogFile();
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

        public static function success(clazz:*, text:*, simple:Boolean = false):void
        {
            log(clazz, SUCCESS, text, simple);
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
            else if (text is ErrorEvent)
            {
                var erre:ErrorEvent = (text as ErrorEvent);
                msg = "Error: " + event_error(erre);
            }
            else
            {
                msg = text;
            }

            msg = ((!simple ? "[" + TimeUtil.convertToHHMMSS(currentTime / 1000) + "][" + class_name(clazz) + "] " : "") + msg);

            // Display
            //trace(DEBUG_COLORS[level] + msg + DEBUG_COLOR_RESET); // For consoles that support color.
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
            return "(" + err.errorID + ") " + err.name + "\n" + err.message + "\n" + err.getStackTrace();
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
