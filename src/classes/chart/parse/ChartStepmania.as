package classes.chart.parse
{
    import com.flashfla.utils.StringUtil;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;

    public class ChartStepmania extends ChartBase
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

        private var fields_array:Array = ['title',
            'subtitle',
            'artist',
            'titletranslit',
            'subtitletranslit',
            'artisttranslit',
            'credit',
            'banner',
            'background',
            'cdtitle',
            'music',
            'offset',
            'samplestart',
            'samplelength',
            'bpms',
            'stops',
            'freezes',
            'notes'];

        private var fields_number:Array = ['offset',
            'samplestart',
            'samplelength'];

        private var bpms:Array = [];
        private var stops:Array = [];

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

                // Build Data Structure
                var notes:Object;
                for each (var match:Array in matches)
                {
                    if (fields_array.indexOf(match[0]) <= -1)
                        continue;

                    switch (match[0])
                    {
                        case 'bpms':
                        case 'stops':
                        case 'freezes':
                            data[match[0]] = getListValues(match[1], true);
                            break;

                        case 'notes':
                            notes = {};

                            var notesValues:Array = match[1].split(":");
                            for (var i:int = 0; i < notesValues.length; i++)
                                notesValues[i] = StringUtil.trim(notesValues[i]);

                            notes['type'] = standardType(notesValues[0]); // dance-single, dance-double, dance-couple, dance-solo
                            notes['desc'] = notesValues[1]; // ???
                            notes['class'] = notesValues[2]; // Beginner, Easy, Medium, Hard, Challenge, ...Edit?
                            notes['class_color'] = notesValues[2]; // Beginner, Easy, Medium, Hard, Challenge, ...Edit?
                            notes['difficulty'] = notesValues[3]; // [0-9]+
                            notes['radar_values'] = notesValues[4]; // 0.000,0.000,0.000,0.000,0.000

                            // check type for valid
                            if (!ignoreValidation && (validColumnCounts.indexOf(notes['type']) == -1))
                            {
                                trace("SM: Invalid: [", notesValues[0], notes['type'], "]");
                                continue;
                            }

                            // filter out anything except notes and commas
                            var notesData:Array = notesValues[5].split("\n");
                            for (i = 0; i < notesData.length; i++)
                            {
                                var pos:int = notesData[i].indexOf('//');

                                if (pos !== -1)
                                    notesData[i] = notesData[i].substr(0, pos);

                                notesData[i] = StringUtil.trim(notesData[i]);
                            }
                            notes['data'] = notesData.join('');

                            // count arrows, holds, mines
                            notes['arrows'] = getCharacterCount(notes['data'], "1");
                            notes['holds'] = getCharacterCount(notes['data'], "2");
                            notes['mines'] = getCharacterCount(notes['data'], "M");

                            data['notes'].push(notes);
                            break;

                        default:
                            if (fields_number.indexOf(match[0]) != -1)
                                data[match[0]] = parseFloat(match[1]);
                            else
                                data[match[0]] = match[1];
                            break;
                    }
                }

                // Setup BPMS
                this.bpms = this.data['bpms'] || [];
                this.bpms.sort(keyPairSort);
                if (this.bpms.length <= 0)
                    this.bpms[0] = [0, 60]; // No BPM, default to 60.
                this.bpms[0][0] = 0; // First BPM starts at beat 0.

                // Setup Stops
                this.stops = this.data['stops'] || this.data['freezes'] || [];
                this.stops.sort(keyPairSort);

                // Finalize Charts
                for (var chart:int = 0; chart < data["notes"].length; chart++)
                {
                    notes = data["notes"][chart];
                    notes['time_sec'] = getChartTimeFast(chart);
                    notes['nps'] = ((notes['arrows'] + notes['holds']) / (notes['time_sec']));
                }

                data['stepauthor'] = data['credit'];

                // Validation
                if (data['music'] == null || data['music'] == "")
                    data['music'] = fileName.substr(0, fileName.lastIndexOf(".")) + ".mp3";

                if (data['title'] == null || data['title'] == "")
                    data['title'] = fileName;

                var audioExt:String = (data['music'] || "").substr(-3).toLowerCase();
                if (!ignoreValidation && (audioExt != "mp3"))
                {
                    trace("SM: Invalid: [", audioExt, "]");
                    return false;
                }

                // No valid charts found.
                if (data['notes'].length <= 0)
                {
                    trace("SM: No Charts");
                    return false;
                }
            }
            catch (e:Error)
            {
                trace("SM: Error Catch: " + e);
                return false;
            }

            this.loaded = true;

            var t:Number = getTimer();
            parse();
            trace("parsed in", (getTimer() - t));

            return true;
        }

        /**
         * Fully parse the chart data if applicable.
         */
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
            var mines:Array = [];

            var pre_notes:Vector.<ChartObject> = new <ChartObject>[];
            var pre_mines:Vector.<ChartObject> = new <ChartObject>[];
            var pre_holds:Object = {};

            var currentRow:int = 0;
            var currentTime:Number = 0;

            var measureArray:Array = chartData['data'].split(",");
            var measureCount:int = measureArray.length;
            var notebarOffset:int = 0;

            var msBeatIncrement:Number;
            var lastBPMIndex:int = 0;
            var lastStopIndex:int = 0;
            var lastStop:Array;

            var warpStart:Number = -1;
            var isWarping:Boolean = false;

            for (var currentMeasure:int = 0; currentMeasure < measureCount; currentMeasure++)
            {
                currentRow = currentMeasure * ROWS_PER_MEASURE;

                var measure:String = measureArray[currentMeasure];
                notebarOffset = 0;

                var barsPerMeasure:int = measure.length / columnCount;
                var measureBeat:int = currentMeasure * 4;

                for (var currentNoteBar:int = 0; currentNoteBar < barsPerMeasure; currentNoteBar++)
                {
                    lastBPMIndex = bpm_at_row_index(currentRow, lastBPMIndex);
                    var currentBPM:Number = bpms[lastBPMIndex][1];

                    // Stops
                    if (stops.length > 0 && lastStopIndex < stops.length)
                    {
                        if (lastStop == null)
                            lastStop = stops[0];

                        while (lastStop[0] < currentRow)
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
                    var rowUpdates:int = ROWS_PER_MEASURE / barsPerMeasure;
                    for (var row:int = 0; row < rowUpdates; row++)
                    {
                        lastBPMIndex = bpm_at_row_index(currentRow, lastBPMIndex);
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

                        currentRow++;
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

                notes[notes.length] = [elm.time, elm.dir, elm.color, (!isNaN(elm.tail) ? (int(elm.tail) / 1000) : 0)];
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

            var currentTime:Number = 0;
            var currentBPM:Number;

            var measureCount:int = getCharacterCount(data['notes'][chart_index]['data'], ",") + 1;
            var maxRows:int = ROWS_PER_MEASURE * measureCount;

            var msBeatIncrement:Number;
            var lastBPMIndex:int = 0;
            var currentRow:int = 0;

            const timeSeq:Number = (4 / ROWS_PER_MEASURE);

            // BPMs need to be handled on every 192nd, skipping any row will result in
            // off-sync if a BPM change lands on a row not handled by the measure.
            while (currentRow < maxRows)
            {
                lastBPMIndex = bpm_at_row_index(currentRow, lastBPMIndex);
                currentBPM = bpms[lastBPMIndex][1];

                // Increase Time
                msBeatIncrement = 1000 / (currentBPM / 60);
                currentTime += (timeSeq * msBeatIncrement);

                currentRow++;
            }

            // Stops
            if (stops.length > 0)
                for (var i:int = stops.length - 1; i >= 0; i--)
                    currentTime += stops[i][1] * 1000;

            // Offset
            currentTime += (data['offset'] * -1000);

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
        private function bpm_at_row_index(currentRow:Number, startIndex:int = 0):int
        {
            var bpm:int = startIndex;
            var len:int = bpms.length;

            for (var i:int = startIndex; i < len; i++)
            {
                if (bpms[i][0] > currentRow)
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
                        tmp_array[tmp_array.length] = [Math.round(48 * parseFloat(arrayList.substr(0, splitIndex))), parseFloat(arrayList.substr(splitIndex + 1))];
                    else
                        tmp_array[tmp_array.length] = [Math.round(48 * parseFloat(arrayList.substr(0, splitIndex))), arrayList.substr(splitIndex + 1)];
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
