package classes.chart.parse
{
    import com.flashfla.utils.StringUtil;
    import flash.utils.ByteArray;

    public class ChartOSU extends ChartBase
    {
        public var COLORS:Object = {"4": ["white", "pink", "pink", "white"],
                "5": ["white", "pink", "purple", "pink", "white"],
                "6": ["white", "pink", "white", "white", "pink", "white"],
                "7": ["white", "pink", "white", "purple", "white", "pink", "white"],
                "8": ["white", "pink", "pink", "white", "white", "pink", "pink", "white"],
                "9": ["white", "pink", "pink", "white", "purple", "white", "pink", "pink", "white"]};

        private static const COLLECT_ARRAY_TYPES:Array = ["Events", "TimingPoints", "HitObjects"];
        private static const COLLECT_KEY_TYPES:Array = ["General", "Editor", "Metadata", "Difficulty"];

        private var collections:Object;

        override public function load(fileData:ByteArray, fileName:String = null):Boolean
        {
            try
            {
                fileData.position = 0;

                var buff:String = fileData.readUTFBytes(fileData.length).replace(/\r\n|\r/gm, "\n");

                var bufflines:Array = buff.split("\n");

                collections = {};

                // Read File Basic
                var line:String;
                var collection_key:String;
                var collection_current:Object;
                var collection_array:Array;

                var isKeyPair:Boolean = false;

                for (var l:int = 0; l < bufflines.length; l++)
                {
                    line = bufflines[l];

                    // Comment Lines
                    if (line.substr(0, 2) == "//")
                        continue;

                    // New Group
                    if (line.charAt(0) == "[")
                    {
                        collection_key = line.substr(1, line.length - 2);
                        if (COLLECT_KEY_TYPES.indexOf(collection_key) != -1)
                        {
                            isKeyPair = true;
                            collection_current = {};
                            collections[collection_key] = collection_current;
                        }
                        else if (COLLECT_ARRAY_TYPES.indexOf(collection_key) != -1)
                        {
                            isKeyPair = false;
                            collection_array = [];
                            collections[collection_key] = collection_array;
                        }
                        else
                        {
                            collection_key = null;
                        }
                        continue;
                    }

                    if (!collection_key || line.length <= 0)
                        continue;

                    // Get Values
                    if (isKeyPair)
                    {
                        var sep:Number = line.indexOf(":");
                        if (sep != -1)
                        {
                            var key:String = line.substr(0, sep);
                            var value:String = StringUtil.trim(line.substr(sep + 1));
                            collection_current[key] = value;
                        }
                    }
                    else
                    {
                        collection_array[collection_array.length] = line.split(",");
                    }
                }

                // Check for osu!mania
                var gameMode:int = parseInt(collections["General"]["Mode"]);
                var columnCount:int = parseInt(collections["Difficulty"]["CircleSize"]);
                var audioExt:String = collections["General"]["AudioFilename"].substr(-3).toLowerCase();
                if (!ignoreValidation && (gameMode != 3 || validColumnCounts.indexOf(columnCount) == -1 || audioExt != "mp3"))
                {
                    trace("OSU: Invalid: [", gameMode, columnCount, audioExt, "]");
                    return false;
                }

                data['music'] = collections["General"]["AudioFilename"];
                data['title'] = collections["Metadata"]["Title"] || fileName;
                data['artist'] = collections["Metadata"]["Artist"];
                data['stepauthor'] = collections["Metadata"]["Creator"];
                data['difficulty'] = parseInt(collections["Difficulty"]["OverallDifficulty"]) * 16;

                if (collections["Events"].length > 0)
                {
                    for each (var event:Object in collections["Events"])
                    {
                        if (event[0] == "0")
                        {
                            var filename:String = event[2];

                            if (filename.charAt(0) == "\"")
                                filename = filename.substr(1, filename.length - 2);

                            data['banner'] = filename;
                            data['background'] = filename;
                            break;
                        }
                    }
                }

                // Build NoteMap Object
                var columnWidth:Number = 512 / columnCount;
                var noteCollection:Array = collections["HitObjects"];
                var noteArray:Array = [];
                var collectionEntry:Array;
                for (l = 0; l < noteCollection.length; l++)
                {
                    collectionEntry = noteCollection[l];

                    var noteTime:Number = parseFloat(collectionEntry[2]) / 1000;
                    var noteType:int = parseInt(collectionEntry[3]);
                    var column:int = (Math.max(0, Math.min(columnCount, Math.floor(parseInt(collectionEntry[0]) / columnWidth))));

                    var noteHeldTime:Number = 0;

                    // Held Note
                    if ((noteType & 128) != 0)
                    {
                        var noteExtra:Array = (collectionEntry[5] as String).split(":");
                        noteHeldTime = (parseFloat(noteExtra[0]) / 1000) - noteTime;
                    }

                    noteArray[noteArray.length] = [noteTime, COLUMNS[columnCount][column], COLORS[columnCount][column], noteHeldTime];
                }

                // No Notes in the file.
                if (noteArray.length <= 0)
                {
                    trace("OSU: Invalid: [No Notes]");
                    return false;
                }

                // Determine File Time
                var maxChartTime:Number = 1;
                for (var i:int = noteArray.length - 1; i >= 0; i--)
                {
                    maxChartTime = Math.max(maxChartTime, noteArray[i][0] + noteArray[i][3]);
                    if (isNaN(maxChartTime))
                    {
                        maxChartTime = 1;
                        break;
                    }
                }

                // Determine Hold Count
                var maxHoldCount:int = 0;
                for (var h:int = noteArray.length - 1; h >= 0; h--)
                    if (noteArray[h][3] > 0)
                        maxHoldCount++;

                data['nps'] = (noteArray.length / maxChartTime);

                var noteArrayObject:Object = {"class": collections["Metadata"]["Version"],
                        "class_color": getDifficultyClass(parseFloat(collections["Difficulty"]["OverallDifficulty"])),
                        "desc": "",
                        "difficulty": collections["Difficulty"]["OverallDifficulty"],
                        "arrows": noteArray.length,
                        "holds": maxHoldCount,
                        "mines": 0,
                        "radar_values": "0,0,0,0,0",
                        "type": columnCount,
                        "time_sec": maxChartTime,
                        "nps": data['nps'],
                        "stepauthor": collections["Metadata"]["Creator"]};

                var chartArrayObject:Object = {"columns": columnCount,
                        "data": noteArrayObject,
                        "notes": noteArray,
                        "mines": []};

                data["notes"].push(noteArrayObject);
                charts.push(chartArrayObject);
            }
            catch (e:Error)
            {
                trace("OSU: Error Catch: " + e);
                return false;
            }

            this.loaded = true;
            this.parsed = true;
            return true;
        }

        private function getDifficultyClass(val:Number):String
        {
            if (val >= 9)
                return "Edit";
            if (val >= 7)
                return "Challenge";
            if (val >= 5)
                return "Hard";
            if (val >= 4)
                return "Medium";
            if (val >= 3)
                return "Easy";

            return "Beginner";
        }
    }
}
