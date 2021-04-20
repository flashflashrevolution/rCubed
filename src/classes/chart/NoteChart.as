package classes.chart
{
    import classes.chart.parse.*;
    import classes.SongInfo;

    public class NoteChart
    {
        public static const FFR:String = "ChartFFR";
        public static const FFR_RAW:String = "ChartFFRR";
        public static const FFR_BEATBOX:String = "ChartFFRBeatBox";
        public static const FFR_LEGACY:String = "ChartFFRL";
        public static const FFR_MP3:String = "ChartFFRMP3";
        public static const KBO:String = "ChartKBO";
        public static const SM:String = "ChartSM";
        public static const SSC:String = "ChartSSC";
        public static const DWI:String = "ChartDWI";
        public static const THIRDSTYLE:String = "ChartTS";

        public var type:String;
        public var id:Number = 0;
        public var gap:Number = 0;
        public var BPMs:Array = [];
        public var Stops:Array = [];
        public var Notes:Array = [];
        public var chartData:Object;
        public var framerate:int = 60;
        protected var frameOffset:int = 0;

        public function NoteChart(id:Number, inData:Object, framerate:int = 60):void
        {
            this.chartData = inData;
            this.framerate = framerate;
        }

        /**
         * Provides a static interface to access the correct parsing engine needed for the chart.
         *
         * @param	type		Chart Type
         * @param	inData		Chart Data
         * @param	framerate	(Optional) Frame rate to use.
         *
         * @return	NoteChart of the type expected.
         */

        public static function parseChart(type:String, songInfo:SongInfo, inData:Object, framerate:int = 60):NoteChart
        {
            switch (type)
            {
                case THIRDSTYLE:
                    return new ChartThirdstyle(songInfo.level, String(inData), framerate);

                case SM:
                    return new ChartStepmania(songInfo.level, String(inData), framerate);

                case FFR_LEGACY:
                    return new ChartFFRLegacy(songInfo, inData, 30);

                case FFR_BEATBOX:
                    return new ChartFFRBeatbox(songInfo.level, String(inData), 30);

                default:
                    return new ChartFFR(songInfo.level, String(inData), 30);
            }
        }

        /**
         * Provides a static interface to access the correct parsing engine needed for the chart.
         *
         * @param	type		Chart Type
         * @param	inData		Chart Data
         * @param	framerate	(Optional) Frame rate to use.
         *
         * @return	NoteChart of the type expected.
         */

        public static function smartParseChart(id:int, inData:Object, framerate:int = 60):NoteChart
        {
            if (inData is String)
            {
                var dataNoLines:String = String(inData).replace(/\r\n|\r|\n/gi, "");

                // Check for R3 (_root.beatBox)
                if (dataNoLines.indexOf("_root.beatBox") !== -1)
                {
                    trace("Looks like a R3 beatBox.");
                    return new ChartFFRBeatbox(id, String(inData), 30);
                }

                // Check for SM
                if (dataNoLines.indexOf("#TITLE:") !== -1 && dataNoLines.indexOf("#BPMS:") !== -1 && dataNoLines.indexOf("#STOPS:") && dataNoLines.indexOf("#OFFSET:") !== -1)
                {
                    trace("Looks like a SM file.");
                    return new ChartStepmania(id, String(inData), framerate);
                }

                // Check for DWI
                if (dataNoLines.indexOf("#TITLE:") !== -1 && dataNoLines.indexOf("#BPM:") !== -1 && dataNoLines.indexOf("#GAP:") !== -1)
                {
                    trace("Looks like a DWI");
                    trace("I can't handle it yet though...");
                }

                // Check for DWI
                if (dataNoLines.indexOf("timingData") !== -1 && dataNoLines.indexOf("bpmsStr") !== -1 && dataNoLines.indexOf("offsetStr") !== -1 && dataNoLines.indexOf("noteData") !== -1)
                {
                    trace("Looks like a TSC");
                    return new ChartThirdstyle(id, String(inData), framerate);
                }
            }

            return new ChartFFR(id, String(inData), 30);
        }

        /**
         * Calculates the frame for all loaded notes.
         */

        protected function notesToFrame():void
        {
            for (var n:String in this.Notes)
            {
                this.Notes[n].setFrame(noteToTime(this.Notes[n]));
            }
        }

        /**
         * Calculates the time this note spawns on.
         *
         * @param	n	Note to get the time for.
         *
         * @return Second timing of the note provided.
         */
        public function noteToTime(n:Note):int
        {
            var i:int = 0;
            var totalOff:Number = gap;

            while (BPMs[i].getEnd() != -1 && n.time >= BPMs[i].getEnd())
            {
                totalOff += BPMs[i].totalTime();
                i++;
            }

            totalOff += 240 * (n.time - (BPMs[i].getStart())) / (BPMs[i].getBPM());

            for (var j:int = 0; j < Stops.length; j++)
            {
                var f:Stop = Stops[j];
                if (f.time < n.time)
                {
                    totalOff += f.length;
                }
            }

            return Math.round(totalOff * framerate) + frameOffset;
        }

        /**
         * Offset the chart by a given amount of frames
         */
        public function offsetFrames(frames:int):void
        {
            gap += (frames / framerate);
            notesToFrame();
        }

        /**
         * Offset the chart by a given amount of seconds
         */
        public function offsetSeconds(seconds:Number):void
        {
            gap += seconds;
            notesToFrame();
        }

        /**
         * Basic toString method.
         *
         * @return String representation of the notechart.
         */
        public function toString(type:String = null):String
        {
            if (Notes.length == 0)
                return "No Notes...";

            var returnVal:String = "";
            var note:Note = Notes[0];

            // Auto Pad to 60 frame mark
            var frameBuffer:int = note.frame;
            //if(frameBuffer >= 60) {
            frameBuffer = 0;
            //}
            //else {
            //	frameBuffer = 60 - frameBuffer;
            //}

            // Build Output
            if (type == FFR_BEATBOX)
            {
                returnVal = "_root.beatBox = [";
            }
            for (var i:int = 0; i < Notes.length; i++)
            {
                note = Notes[i];
                if (type == FFR_BEATBOX)
                {
                    // [40, "L", "red"],
                    returnVal += (i > 0 ? ", " : "") + ("[" + (note.frame + frameBuffer) + ", \"" + note.direction + "\", \"" + note.colour + "\"]");
                }
                else
                {
                    returnVal += ((i + 1) + "\t\tF: " + (note.frame + frameBuffer) + "\t\tD: " + note.direction + "\t\tC: " + note.colour + "\r");
                }
            }
            if (type == FFR_BEATBOX)
            {
                returnVal += "];";
            }
            return returnVal;
        }
    }
}
