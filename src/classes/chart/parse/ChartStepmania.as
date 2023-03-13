package classes.chart.parse
{
    import classes.chart.BPMSegment;
    import classes.chart.Note;
    import classes.chart.NoteChart;
    import classes.chart.Stop;
    import com.flashfla.utils.ExtraMath;

    public class ChartStepmania extends NoteChart
    {

        public function ChartStepmania(id:Number, inData:String, framerate:int = 60):void
        {
            type = NoteChart.SM;
            frameOffset = -1;
            super(id, inData.split("\r"), framerate);

            var lineNum:int = 0;
            while (chartData[lineNum] != null)
            {
                var lineText:String = String(chartData[lineNum]);
                //- Set Gap
                if (lineText.substr(0, 4) == "#OFF")
                { // #OFFSET
                    this.gap = Number(lineText.substring(8, lineText.length - 1)) * -1;
                }

                //- Set BPM's
                if (lineText.substr(0, 4) == "#BPM")
                { // #BPMS
                    addBPMs(lineText.substring(6, lineText.length - 1));
                }

                //- Set Freeze's
                if (lineText.substr(0, 4) == "#STO")
                { // #STOPS
                    addFreezes(lineText.substring(7, lineText.length - 1));
                }

                //- Set Notes
                if (lineText.substr(0, 4) == "#NOT")
                { // #NOTES
                    var currentMeasure:int = 0;
                    var measureBuffer:String = "";
                    while (chartData[lineNum] != null)
                    {
                        lineText = String(chartData[lineNum]);
                        if (lineText.indexOf(":") != -1)
                        {
                            lineNum++;
                            continue;
                        }
                        else if (lineText.charAt(0) == ",")
                        {
                            extractNotesFromLine(measureBuffer, measureBuffer.length / 4, currentMeasure);
                            currentMeasure++;
                            measureBuffer = "";
                        }
                        else if (lineText.charAt(0) == ";")
                        {
                            extractNotesFromLine(measureBuffer, measureBuffer.length / 4, currentMeasure);
                            break;
                        }
                        else
                        {
                            measureBuffer += lineText;
                        }
                        lineNum++;
                    }
                }
                lineNum++;
            }
        }

        private function extractNotesFromLine(s:String, divisor:int, measure:int):void
        {
            for (var i:int = 0; i < divisor; i++)
            {
                // Set Color

                var col:String;
                if (i == 0 || reduce(i, divisor) == 2 || reduce(i, divisor) == 4)
                {
                    col = "red";
                }
                else if (reduce(i, divisor) == 8)
                {
                    col = "blue";
                }
                else if (reduce(i, divisor) == 3 || reduce(i, divisor) == 6 || reduce(i, divisor) == 12)
                {
                    col = "purple";
                }
                else if (reduce(i, divisor) == 16)
                {
                    col = "yellow";
                }
                else if (reduce(i, divisor) == 24)
                {
                    col = "pink";
                }
                else if (reduce(i, divisor) == 32)
                {
                    col = "orange";
                }
                else if (reduce(i, divisor) == 48)
                {
                    col = "cyan";
                }
                else if (reduce(i, divisor) == 64)
                {
                    col = "green";
                }
                else
                {
                    col = "white";
                }

                // Get 4 Char Chunk
                var chunk:String = s.substr(i * 4, 4);

                // Add Notes
                if (chunk.charAt(0) == "1" || chunk.charAt(0) == "2")
                    Notes.push(new Note("L", measure + i / divisor, col));
                if (chunk.charAt(1) == "1" || chunk.charAt(1) == "2")
                    Notes.push(new Note("D", measure + i / divisor, col));
                if (chunk.charAt(2) == "1" || chunk.charAt(2) == "2")
                    Notes.push(new Note("U", measure + i / divisor, col));
                if (chunk.charAt(3) == "1" || chunk.charAt(3) == "2")
                    Notes.push(new Note("R", measure + i / divisor, col));
            }
        }

        public function reduce(num:int, denom:int):int
        {
            return denom / ExtraMath.getGCD(num, denom);
        }

        public function addBPMs(s:String):void
        {
            if (s == null || s == "")
            {
                return;
            }
            else if (s.indexOf(",") >= 0)
            {
                addBPMs(s.substring(0, s.indexOf(",")));
                addBPMs(s.substring(s.indexOf(",") + 1));
            }
            else
            {
                var start:Number = Number(s.substring(0, s.indexOf("=")));
                var bpm:Number = Number(s.substring(s.indexOf("=") + 1));
                if (BPMs.length != 0)
                {
                    BPMs[BPMs.length - 1].setEnd(start / 16);
                }
                BPMs.push(new BPMSegment(start / 16, bpm));
            }
        }

        public function addFreezes(s:String):void
        {
            if (s == null || s == "")
            {
                return;
            }
            else if (s.indexOf(",") >= 0)
            {
                addFreezes(s.substring(0, s.indexOf(",")));
                addFreezes(s.substring(s.indexOf(",") + 1));
            }
            else
            {
                var pos:Number = Number(s.substring(0, s.indexOf("=")));
                var length:Number = Number(s.substring(s.indexOf("=") + 1));
                Stops.push(new Stop(pos / 16, length / 1000));
            }
        }

    }

}
