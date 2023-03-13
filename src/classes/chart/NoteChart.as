package classes.chart
{
    import classes.chart.parse.*;
    import classes.SongInfo;

    public class NoteChart
    {
        /** Legacy Mode */
        public static const FFR_LEGACY:String = "ChartFFRSWF";

        /** SWF MP3 + Beatbox Extraction */
        public static const FFR_MP3:String = "ChartFFRMP3";

        public static const SM:String = "ChartSM";

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
                case SM:
                    return new ChartStepmania(songInfo.level, String(inData), framerate);

                case FFR_LEGACY:
                    return new ChartFFRLegacy(songInfo, inData, 30);
            }

            return null;
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

            // Build Output
            for (var i:int = 0; i < Notes.length; i++)
            {
                note = Notes[i];
                returnVal += ((i + 1) + "\t\tF: " + (note.frame) + "\t\tD: " + note.direction + "\t\tC: " + note.color + "\r");
            }
            return returnVal;
        }
    }
}
