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

        public var type:String;
        public var Notes:Vector.<Note> = new <Note>[];
        public var chartData:Object;
        public var framerate:int = 60;

        public function NoteChart(inData:Object = null, framerate:int = 60):void
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
