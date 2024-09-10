package classes.chart.parse
{
    import by.blooddy.crypto.MD5;
    import classes.chart.parse.ChartBase;
    import classes.chart.parse.ChartOSU;
    import classes.chart.parse.ChartQuaver;
    import classes.chart.parse.ChartSSC;
    import classes.chart.parse.ChartStepmania;
    import com.flashfla.utils.TimeUtil;
    import flash.events.ErrorEvent;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;

    public class ExternalChartBase
    {
        public static const VALID_CHART_EXTENSIONS:Array = ["sm", "ssc", "osu", "qua"];

        public var ID:String;
        public var DATE:Number;

        public var DEFAULT_CHART_ID:int = 0;

        private var CHART_BYTES:ByteArray;
        private var AUDIO_BYTES:ByteArray;

        private var fileQueue:Array = [];

        private var info:Object = {"name": "External File",
                "display": "???",
                "difficulty": 1,
                "author": "???",
                "stepauthor": "???",
                "description": "???"}

        public var parser:ChartBase;

        public function parseData():void
        {
            if (!parser.parsed)
                parser.parse();
        }

        public function getInfo():Object
        {
            return info;
        }

        public function getAudioData():ByteArray
        {
            return AUDIO_BYTES;
        }

        public function getChartData():ByteArray
        {
            return CHART_BYTES;
        }

        public function getAllCharts():Array
        {
            return parser.data['notes'];
        }

        public function getValidChartData(chart_index:Object = null):Object
        {
            if (parser.charts[chart_index] != null)
                return parser.charts[chart_index];

            return parser.charts[DEFAULT_CHART_ID];
        }

        public function getNoteData(chart_index:Object = null):Array
        {
            return getValidChartData(chart_index)['notes'];
        }

        public function getMineData(chart_index:Object = null):Array
        {
            return getValidChartData(chart_index)['mines'];
        }

        public function getColumnCount(chart_index:Object = null):int
        {
            return getValidChartData(chart_index)['columns'];
        }

        public function getChartTime(chart_index:Object = null):Number
        {
            if (!this.parser.parsed)
                return this.parser.getChartTimeFast(chart_index);

            // We have parsed data, use note timings.
            var nd:Array = getNoteData(chart_index);
            var md:Array = getMineData(chart_index);

            if (nd.length <= 0)
                return 0;

            var maxTime:Number = 0;
            for (var i:int = nd.length - 1; i >= 0; i--)
                maxTime = Math.max(maxTime, nd[i][0] + nd[i][3]);

            if (md.length > 0)
                maxTime = Math.max(maxTime, md[md.length - 1][0]);

            return maxTime;
        }

        public function getChartTimeFormat(maxTime:Number):String
        {
            if (isNaN(maxTime) || maxTime < 0)
                return "0:00";

            var s:Number = maxTime % 60;
            var m:Number = Math.floor((maxTime % 3600) / 60);
            var h:Number = Math.floor(maxTime / (60 * 60));

            var hourStr:String = (h == 0) ? "" : (h) + ":";
            var minuteStr:String = (h == 0) ? (m + ":") : (TimeUtil.doubleDigitFormat(m) + ":");
            var secondsStr:String = TimeUtil.doubleDigitFormat(s);

            return hourStr + minuteStr + secondsStr;
        }

        //----------------------------------------------------------------------------------------------------------//

        public function load(folder:File, skipMusicLoad:Boolean = false):Boolean
        {
            // Search Folder for Parseable Files
            if (folder.isDirectory)
            {
                for each (var file:File in folder.getDirectoryListing())
                {
                    if (VALID_CHART_EXTENSIONS.indexOf(file.extension.toLowerCase()) != -1)
                    {
                        fileQueue.push(file);
                    }
                }
            }
            // Given File, Assume Good
            else
            {
                if (VALID_CHART_EXTENSIONS.indexOf(folder.extension.toLowerCase()) != -1)
                {
                    fileQueue.push(folder);
                }
            }

            // Validate and Load File Queue, Stop after first valid chart.
            while (fileQueue.length > 0)
            {
                var firstFile:File = fileQueue.pop();

                if (!firstFile.exists)
                    continue;

                info['filename'] = firstFile.name;

                parser = getParser(firstFile.extension.toLowerCase());

                CHART_BYTES = readFile(firstFile);

                if (parser.load(CHART_BYTES, info['filename']))
                {
                    info['ext'] = firstFile.extension.toLowerCase();
                    info['name'] = parser.data.title || "???";
                    info['display'] = parser.data.title || "???";
                    info['author'] = parser.data.artist || "???";
                    info['stepauthor'] = parser.data.stepauthor || "???";
                    info['difficulty'] = parser.data.difficulty || 1;
                    info['arrows'] = parser.data.notes[DEFAULT_CHART_ID].arrows;
                    info['holds'] = parser.data.notes[DEFAULT_CHART_ID].holds;
                    info['mines'] = parser.data.notes[DEFAULT_CHART_ID].mines;
                    info['time_secs'] = getChartTime(DEFAULT_CHART_ID);
                    info['time'] = getChartTimeFormat(info['time_secs']);
                    info['music'] = parser.data.music || "";
                    info['banner'] = parser.data.banner || "";
                    info['background'] = parser.data.background || "";

                    ID = MD5.hashBytes(CHART_BYTES);
                    DATE = firstFile.modificationDate.getTime();

                    // Folder Path
                    var path:String = firstFile.nativePath;
                    var endOfFolder:int = path.lastIndexOf(File.separator) + 1;
                    info['folder'] = path.substr(0, endOfFolder);

                    // Music Validation
                    if (parser.data.music.length < 4 || parser.data.music.substr(-3).toLowerCase() != "mp3")
                        return false;

                    if (!skipMusicLoad)
                    {
                        var musicFile:File = firstFile.parent.resolvePath(parser.data.music);

                        if (!musicFile.exists)
                            return false;

                        AUDIO_BYTES = readFile(firstFile.parent.resolvePath(parser.data.music));
                    }

                    fileQueue.length = 0;
                    return true;
                }
            }

            return false;
        }

        public function getParser(ext:String):ChartBase
        {
            switch (ext)
            {
                case "sm":
                    return new ChartStepmania();

                case "ssc":
                    return new ChartSSC();

                case "osu":
                    return new ChartOSU();

                case "qua":
                    return new ChartQuaver();
            }

            return null;
        }

        public function readFile(file:File):ByteArray
        {
            if (!file.exists)
                return null;

            var fileStream:FileStream = new FileStream();
            fileStream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_error);
            fileStream.addEventListener(IOErrorEvent.IO_ERROR, e_error);
            var readData:ByteArray = new ByteArray();
            fileStream.open(file, FileMode.READ);
            fileStream.readBytes(readData);
            fileStream.close();

            return readData;

            function e_error(e:ErrorEvent):void
            {

            }
        }
    }
}
