package classes.chart.parse
{
    import com.flashfla.utils.StringUtil;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;

    public class ChartSSC extends ChartBase
    {
        private static const NOTE_TYPE_4TH:int = 0;
        private static const NOTE_TYPE_8TH:int = 1;
        private static const NOTE_TYPE_12TH:int = 2;
        private static const NOTE_TYPE_16TH:int = 3;
        private static const NOTE_TYPE_24TH:int = 4;
        private static const NOTE_TYPE_32ND:int = 5;
        private static const NOTE_TYPE_48TH:int = 6;
        private static const NOTE_TYPE_64TH:int = 7;
        private static const NOTE_TYPE_192ND:int = 8;
        private static const NOTE_TYPE_INVALID:int = 9;

        private static const ROWS_PER_MEASURE:int = 192;

        private var fields_number:Array = ['offset',
            'samplestart',
            'samplelength',
            'version',
            'meter'];

        override public function load(fileData:ByteArray, fileName:String = null):Boolean
        {
            try
            {
                fileData.position = 0;

                var buff:String = fileData.readUTFBytes(fileData.length).replace(/\r\n|\r/gm, "\n");

                // Get All Matches
                var matches:Array = [];
                var sI:int = -1;
                var sE:int = -1;
                while (true)
                {
                    sI = buff.indexOf("#", sE);
                    sE = buff.indexOf(";", sI);

                    if (sI >= 0 && sE > sI)
                    {
                        var matchString:String = buff.substring(sI, sE);

                        var split:int = matchString.indexOf(":");
                        var key:String = matchString.substring(1, split).toLowerCase();
                        var value:String = matchString.substr(split + 1);

                        matches[matches.length] = [key, value];
                    }
                    else
                        break;
                }

                var tmp_array:Array;
                var chart:int = -1;

                // Build Data Structure
                for each (var match:Array in matches)
                {
                    if (match[0] == "notedata")
                    {
                        chart++;
                        data["notes"][chart] = {};
                        continue;
                    }

                    if (chart > -1)
                    {
                        switch (match[0])
                        {
                            // time=string
                            case 'labels':
                            case 'speeds':
                            case 'timesignatures':
                                data["notes"][chart][match[0]] = getListValues(match[1], false);
                                break;

                            // time=value
                            case 'bpms':
                            case 'stops':
                            case 'delays':
                            case 'warps':
                            case 'tickcounts':
                            case 'combos':
                            case 'scrolls':
                                data["notes"][chart][match[0]] = getListValues(match[1], true);

                                break;

                            case 'notes':
                                // filter out anything except notes and commas
                                var notesData:Array = StringUtil.trim(match[1]).split("\n");
                                for (var i:int = 0; i < notesData.length; i++)
                                {
                                    var pos:int = notesData[i].indexOf('//');

                                    if (pos !== -1)
                                        notesData[i] = notesData[i].substr(0, pos);

                                    notesData[i] = StringUtil.trim(notesData[i]);
                                }
                                data["notes"][chart]['data'] = notesData.join('');

                                // count arrows, holds, mines
                                data["notes"][chart]['arrows'] = getCharacterCount(data["notes"][chart]['data'], "1");
                                data["notes"][chart]['holds'] = getCharacterCount(data["notes"][chart]['data'], "2");
                                data["notes"][chart]['mines'] = getCharacterCount(data["notes"][chart]['data'], "M");
                                break;

                            default:
                                if (fields_number.indexOf(match[0]) != -1)
                                    data["notes"][chart][match[0]] = parseFloat(StringUtil.trim(match[1]));
                                else
                                    data["notes"][chart][match[0]] = StringUtil.trim(match[1]);
                                break;
                        }
                    }
                    else
                    {
                        switch (match[0])
                        {
                            // time=string
                            case 'labels':
                            case 'speeds':
                            case 'timesignatures':
                                tmp_array = getListValues(match[1], false);

                                if (tmp_array.length > 0)
                                    data[match[0]] = tmp_array;
                                break;

                            // time=value
                            case 'bpms':
                            case 'stops':
                            case 'delays':
                            case 'warps':
                            case 'tickcounts':
                            case 'combos':
                            case 'scrolls':
                                tmp_array = getListValues(match[1], true);

                                if (tmp_array.length > 0)
                                    data[match[0]] = tmp_array;

                                break;

                            default:
                                if (fields_number.indexOf(match[0]) != -1)
                                    data[match[0]] = parseFloat(StringUtil.trim(match[1]));
                                else
                                    data[match[0]] = StringUtil.trim(match[1]);
                                break;
                        }
                    }
                }

                // Finalize Charts
                for (chart = data["notes"].length - 1; chart >= 0; chart--)
                {
                    var notes:Object = data["notes"][chart];

                    notes['type'] = standardType(notes['stepstype']); // dance-single, dance-double, dance-couple, dance-solo, etc.
                    notes['desc'] = ""; // ???
                    notes['class'] = notes['difficulty'] || "Easy"; // Beginner, Easy, Medium, Hard, Challenge, ...Edit?
                    notes['class_color'] = notes['difficulty'] || "Easy"; // Beginner, Easy, Medium, Hard, Challenge, ...Edit?
                    notes['difficulty'] = notes['meter'] || 1; // [0-9]+
                    notes['radar_values'] = notes['radarvalues'] || ""; // 0.000,0.000,0.000,0.000,0.000
                    notes['time_sec'] = getChartTimeFast(chart);
                    notes['nps'] = ((notes['arrows'] + notes['holds']) / (notes['time_sec']));

                    if (notes['credit'] != null)
                    {
                        notes['stepauthor'] = notes['credit'];
                        delete notes['credit'];
                    }

                    if (!ignoreValidation && (validColumnCounts.indexOf(notes['type']) == -1))
                    {
                        trace("SSC: Invalid: [", notes['stepstype'], notes['type'], "]");
                        data["notes"].removeAt(chart);
                        continue;
                    }

                    delete notes['stepstype'];
                    delete notes['meter'];
                }

                // Match Stepmania Variables
                data['stepauthor'] = data['credit'];
            }
            catch (e:Error)
            {
                trace("SSC: Error Catch: " + e);
                return false;
            }

            // Validation
            if (data['music'] == null || data['music'] == "")
                data['music'] = fileName.substr(0, fileName.lastIndexOf(".")) + ".mp3";

            if (data['title'] == null || data['title'] == "")
                data['title'] = fileName;

            var audioExt:String = (data['music'] || "").substr(-3).toLowerCase();
            if (!ignoreValidation && (audioExt != "mp3"))
            {
                trace("SSC: Invalid: [", audioExt, "]");
                return false;
            }

            // No valid charts found.
            if (data['notes'].length <= 0)
            {
                trace("SSC: No Charts");
                return false;
            }

            this.loaded = true;

            return true;
        }

        override public function parse():void
        {
            if (!loaded || this.parsed)
                return;

            // Fully Parse Charts
            for each (var chartData:Object in data['notes'])
                this.charts[this.charts.length] = parseNoteData(chartData);

            this.parsed = true;
        }

        /**
         * Do a full parse of the provided chart data.
         * This also removes the raw chart data string from the passed object.
         * @param chartData
         * @return
         */
        private function parseNoteData(chartData:Object):Object
        {
            //var t:Number = getTimer();

            var columnCount:int = chartData['type'];
            var columnMap:Array = COLUMNS[chartData['type']] || [];

            var offset:Number = data['offset'] * -1000;

            var out:Object = {'data': chartData,
                    'columns': columnCount};

            var notes:Array = [];
            var holds:Array = [];
            var mines:Array = [];

            var pre_notes:Vector.<ChartObject> = new <ChartObject>[];
            var pre_mines:Vector.<ChartObject> = new <ChartObject>[];
            var pre_holds:Object = {};

            var currentBeat:Number = 0;
            var currentTime:Number = 0;

            var measureArray:Array = chartData['data'].split(",");
            var measureCount:int = measureArray.length;
            var notebarOffset:int = 0;
            var rowValue:int = 0;

            var row:int;
            var rowUpdates:int;

            var msBeatIncrement:Number;
            var lastBPMIndex:int = 0;
            var lastStopIndex:int = 0;
            var lastStop:Array;

            var warpStart:Number = -1;
            var isWarping:Boolean = false;

            // Setup BPMs
            var bpms:Array = chartData['bpms'] || this.data['bpms'] || [[0, 60]];
            bpms.sort(keyPairSort);
            bpms[0][0] = 0; // First BPM starts at beat 0.

            // Setup Stops
            var stops:Array = chartData['stops'] || this.data['stops'] || [];
            stops.sort(keyPairSort);

            // Setup Warps
            var warps:Array = chartData['warps'] || this.data['warps'] || [];
            warps.sort(keyPairSort);

            for (var currentMeasure:int = 0; currentMeasure < measureCount; currentMeasure++)
            {
                rowValue = currentMeasure * ROWS_PER_MEASURE;

                var measure:String = measureArray[currentMeasure];
                notebarOffset = 0;

                var barsPerMeasure:int = measure.length / columnCount;
                var measureBeat:int = currentMeasure * 4;

                for (var currentNoteBar:int = 0; currentNoteBar < barsPerMeasure; currentNoteBar++)
                {
                    // calculate the current beat, this can have decimals
                    currentBeat = measureBeat + ((currentNoteBar / barsPerMeasure) * 4);

                    lastBPMIndex = bpm_at_beat_index(bpms, currentBeat, lastBPMIndex);
                    var currentBPM:Number = bpms[lastBPMIndex][1];

                    // Stops
                    if (stops.length > 0 && lastStopIndex < stops.length)
                    {
                        if (lastStop == null)
                            lastStop = stops[0];

                        while (lastStop[0] <= currentBeat)
                        {
                            currentTime += lastStop[1] * 1000;
                            lastStopIndex++;
                            if (lastStopIndex >= stops.length)
                                break;

                            lastStop = stops[lastStopIndex];
                        }
                    }

                    // Start Warp
                    if (currentBPM < 0 && !isWarping)
                    {
                        warpStart = currentTime;
                        isWarping = true;
                    }

                    // No Notes during Warps
                    if (!isWarping)
                    {
                        for (var column:int = 0; column < columnCount; column++)
                        {
                            var noteStr:String = measure.charAt(notebarOffset + column);

                            if (noteStr == "0")
                                continue;

                            if (noteStr == "1" || noteStr == "2" || noteStr == "4")
                            {
                                if (noteStr == "2" || noteStr == "4")
                                    pre_holds[column] = pre_notes.length;

                                var noteColor:String = noteTypeToColor(getNoteType(currentNoteBar * (ROWS_PER_MEASURE / barsPerMeasure)));

                                pre_notes[pre_notes.length] = new ChartObject(int(currentTime), columnMap[column], noteColor);
                            }
                            else if (noteStr == "3")
                            {
                                if (pre_holds[column] != null)
                                {
                                    var holdStart:int = pre_holds[column];
                                    var holdStartData:ChartObject = pre_notes[holdStart];
                                    pre_notes[holdStart].tail = (currentTime - holdStartData.time);
                                    delete pre_holds[column];
                                }
                            }
                            else if (noteStr == 'M')
                            {
                                pre_mines[pre_mines.length] = new ChartObject(int(currentTime), columnMap[column]);
                            }
                        }
                    }

                    // Update String Offset
                    notebarOffset += columnCount;

                    // BPMs need to be handled on every 192nd, skipping any row will result in
                    // off-sync if a BPM change lands on a row not handled by the measure.
                    rowUpdates = ROWS_PER_MEASURE / barsPerMeasure;
                    for (row = 0; row < rowUpdates; row++)
                    {
                        rowValue++;
                        currentBeat = measureBeat + (((currentNoteBar / barsPerMeasure) + (row / ROWS_PER_MEASURE)) * 4);
                        lastBPMIndex = bpm_at_beat_index(bpms, currentBeat, lastBPMIndex);
                        currentBPM = bpms[lastBPMIndex][1];

                        // Start Warp
                        if (currentBPM < 0 && !isWarping)
                        {
                            warpStart = currentTime;
                            isWarping = true;
                        }

                        // Increase Time
                        msBeatIncrement = 1000 / (currentBPM / 60);
                        currentTime += ((4 / ROWS_PER_MEASURE) * msBeatIncrement);
                    }

                    // End Warp
                    if (isWarping)
                    {
                        if (int(currentTime) >= int(warpStart)) // Truncate values because number precision loss can make them not line up.
                        {
                            warpStart = -1;
                            isWarping = false;
                        }
                    }
                }
            }

            // finalize notes
            var i:int;
            var elm:ChartObject;
            for (i = 0; i < pre_notes.length; i++)
            {
                elm = pre_notes[i];

                elm.time = (offset + elm.time) / 1000;

                notes[notes.length] = [elm.time, elm.dir, elm.color];

                if (!isNaN(elm.tail))
                    holds[holds.length] = [elm.time, elm.dir, elm.color, (int(elm.tail) / 1000)];
            }

            // finalize mines
            for (i = 0; i < pre_mines.length; i++)
            {
                elm = pre_mines[i];

                elm.time = (offset + elm.time) / 1000;

                mines[mines.length] = [elm.time, elm.dir];
            }

            // sort data array so time is in order
            notes.sortOn("0", Array.NUMERIC);
            mines.sortOn("0", Array.NUMERIC);

            out['notes'] = notes;
            out['holds'] = holds;
            out['mines'] = mines;

            delete chartData['data'];

            // Clear Vectors for GC
            measureArray = null;
            pre_notes = null;
            pre_holds = null;
            pre_mines = null;

            //trace("parsed in", (getTimer() - t), notes[notes.length - 1][0]);

            return out;
        }

        /**
         * Computes a charts expected length using measure count and BPM.
         * @param chart_index
         * @return
         */
        override public function getChartTimeFast(chart_index:Object = null):Number
        {
            // Cached Time
            if (data['notes'][chart_index]['time_sec'] != null)
                return data['notes'][chart_index]['time_sec'];

            // Calculate
            //var t:Number = getTimer();

            var chartData:Object = data['notes'][chart_index];

            var currentBeat:Number = 0;
            var currentTime:Number = 0;
            var currentBPM:Number;

            var measureCount:int = getCharacterCount(chartData['data'], ",") + 1;
            var maxRows:int = ROWS_PER_MEASURE * measureCount;

            var msBeatIncrement:Number;
            var lastBPMIndex:int = 0;

            const timeSeq:Number = (4 / ROWS_PER_MEASURE);

            // Setup BPMs
            var bpms:Array = chartData['bpms'] || this.data['bpms'] || [[0, 60]];
            bpms.sort(keyPairSort);
            bpms[0][0] = 0; // First BPM starts at beat 0.

            // Setup Stops
            var stops:Array = chartData['stops'] || this.data['stops'] || [];
            stops.sort(keyPairSort);

            // Setup Warps
            var warps:Array = chartData['warps'] || this.data['warps'] || [];
            warps.sort(keyPairSort);

            // BPMs need to be handled on every 192nd, skipping any row will result in
            // off-sync if a BPM change lands on a row not handled by the measure.
            for (var row:int = 0; row < maxRows; row++)
            {
                currentBeat = (row / 48);
                lastBPMIndex = bpm_at_beat_index(bpms, currentBeat, lastBPMIndex);
                currentBPM = bpms[lastBPMIndex][1];

                // Increase Time
                msBeatIncrement = 1000 / (currentBPM / 60);
                currentTime += (timeSeq * msBeatIncrement);
            }

            // Stops
            if (stops.length > 0)
                for (var i:int = stops.length - 1; i >= 0; i--)
                    currentTime += stops[i][1] * 1000;

            // Offset
            currentTime += ((chartData['offset'] || data['offset'] || 0) * -1000);

            // MS -> Seconds
            currentTime /= 1000;

            //trace("time parsed in", (getTimer() - t), currentTime);

            return currentTime;
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////
        /**
         * Converts a given chart type into it's respective column count.
         * @param type
         * @return
         */
        private function standardType(type:String):int
        {
            switch (type)
            {
                case 'dance-single':
                    return 4;

                case 'dance-double':
                case 'dance-couple':
                case 'dance-routine':
                    return 8;

                case 'dance-solo':
                case 'pump-halfdouble':
                    return 6;

                case 'pump-single':
                    return 5;

                case 'pump-double':
                case 'pump-couple':
                    return 10;
            }

            return 0;
        }

        /**
         * Get a note type given it's placement within a measure.
         * @param noteIndex
         * @return
         */
        private function getNoteType(noteIndex:int):int
        {
            if (noteIndex % (ROWS_PER_MEASURE / 4) == 0)
                return NOTE_TYPE_4TH;
            else if (noteIndex % (ROWS_PER_MEASURE / 8) == 0)
                return NOTE_TYPE_8TH;
            else if (noteIndex % (ROWS_PER_MEASURE / 12) == 0)
                return NOTE_TYPE_12TH;
            else if (noteIndex % (ROWS_PER_MEASURE / 16) == 0)
                return NOTE_TYPE_16TH;
            else if (noteIndex % (ROWS_PER_MEASURE / 24) == 0)
                return NOTE_TYPE_24TH;
            else if (noteIndex % (ROWS_PER_MEASURE / 32) == 0)
                return NOTE_TYPE_32ND;
            else if (noteIndex % (ROWS_PER_MEASURE / 48) == 0)
                return NOTE_TYPE_48TH;
            else if (noteIndex % (ROWS_PER_MEASURE / 64) == 0)
                return NOTE_TYPE_64TH;
            else
                return NOTE_TYPE_INVALID;
        }

        /**
         * Converts a note type into a given color.
         */
        private function noteTypeToColor(noteType:int):String
        {
            switch (noteType)
            {
                case NOTE_TYPE_4TH:
                    return 'red';
                case NOTE_TYPE_8TH:
                    return 'blue';
                case NOTE_TYPE_12TH:
                    return 'purple';
                case NOTE_TYPE_16TH:
                    return 'yellow';
                case NOTE_TYPE_24TH:
                    return 'pink';
                case NOTE_TYPE_32ND:
                    return 'orange';
                case NOTE_TYPE_48TH:
                    return 'cyan';
                case NOTE_TYPE_64TH:
                    return 'green';
                case NOTE_TYPE_192ND: // fall through
                case NOTE_TYPE_INVALID:
                    return 'white';
                default:
                    return 'white';
            }
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////

        /**
         * Sorts an array based on the first item.
         */
        private function keyPairSort(a:Array, b:Array):int
        {
            if (a[0] < b[0])
                return -1;
            if (a[0] > b[0])
                return 1;
            return 0;
        }

        /**
         * Find the current BPM index for the current beat.
         * This searches forward starting from the given index until the BPM
         * beat is ahead of the current beat.
         * @param currentBeat
         * @param startIndex
         * @return
         */
        private function bpm_at_beat_index(bpms:Array, currentBeat:Number, startIndex:int = 0):int
        {
            currentBeat = Math.round(currentBeat * 48); // round to nearest row

            var bpm:int = startIndex;
            var len:int = bpms.length;

            for (var i:int = startIndex; i < len; i++)
            {
                if (Math.round(bpms[i][0]) * 48 > currentBeat)
                    break;

                bpm = i;
            }
            return bpm;
        }

        /**
         * Builds an array of key=value pairs.
         * @param input List of pairs.
         * @param isNumber Parse value as a number.
         * @return
         */
        private function getListValues(input:String, isNumber:Boolean = false):Array
        {
            var tmp_array:Array = [];
            input = StringUtil.trim(input);

            if (input.length == 0)
                return tmp_array;

            var arrayValues:Array = input.split(',');

            if (arrayValues.length == 0)
                return tmp_array;

            var splitIndex:int;
            for each (var arrayList:String in arrayValues)
            {
                arrayList = StringUtil.trim(arrayList);
                splitIndex = arrayList.indexOf("=");

                if (splitIndex >= 1)
                    if (isNumber)
                        tmp_array[tmp_array.length] = [parseFloat(arrayList.substr(0, splitIndex)), parseFloat(arrayList.substr(splitIndex + 1))];
                    else
                        tmp_array[tmp_array.length] = [parseFloat(arrayList.substr(0, splitIndex)), arrayList.substr(splitIndex + 1)];
            }
            return tmp_array;
        }

        /**
         * Gets a count of the given pattern in the input.
         * Quickest way to get the note counts without parsing anything.
         * @param input
         * @param pattern
         * @return
         */
        private function getCharacterCount(input:String, pattern:String):Number
        {
            var count:Number = 0;
            var index:int = -1;

            while ((index = input.indexOf(pattern, index + 1)) >= 0)
                count++;

            return count;
        }
    }
}

internal class ChartObject
{
    public var time:Number;
    public var color:String;
    public var dir:String;
    public var tail:Number;

    public function ChartObject(time:Number, dir:String, color:String = null)
    {
        this.time = time;
        this.dir = dir;
        this.color = color;
    }
}
