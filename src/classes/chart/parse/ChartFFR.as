package classes.chart.parse
{
    import classes.chart.BPMSegment;
    import classes.chart.Note;
    import classes.chart.NoteChart;
    import classes.chart.Stop;

    public class ChartFFR extends NoteChart
    {
        //- Input:
        // 2A,L,re|2A,D,re|.........

        public function ChartFFR(id:Number, inData:String, framerate:int = 30):void
        {
            type = NoteChart.FFR;

            super(id, inData.split("|"), framerate);

            // Extract Notes
            for (var i:int = 0; i < this.chartData.length; i++)
            {
                var note:Object = this.chartData[i].split(",");
                this.Notes.push(new Note(note[1], parseInt(note[0], 16) / 30, colorComplete(note[2]), parseInt(note[0], 16) + oldOffsets(id)));
            }
        }

        override public function noteToTime(n:Note):int
        {
            return Math.floor(n.time * 30);
        }

        private function colorComplete(color:String):String
        {
            switch (color)
            {
                case "re":
                    return "red";
                case "bl":
                    return "blue";
                case "pu":
                    return "purple";
                case "ye":
                    return "yellow";
                case "pi":
                    return "pink";
                case "or":
                    return "orange";
                case "cy":
                    return "cyan";
                case "gr":
                    return "green";
                case "wh":
                    return "white";
                default:
                    return "blue";
            }
        }

        /**
         * This method is to patch the sync data for old Charts, where
         * the sync data is embedded directly into the engines instead of
         * fixing the beatBox data.
         * @param	lvlid
         * @return  Frame Offset (int)
         */
        private function oldOffsets(lvlid:Number):int
        {
            switch (lvlid)
            {
                case 87:
                case 88:
                    return -10;
                case 68:
                case 28:
                case 25:
                case 24:
                case 21:
                case 20:
                    return 0;
                case 37:
                    return 6;
                case 23:
                    return -2;
                case 22:
                    return 3;
                case 19:
                    return -4;
                case 17:
                    return 1;
                default:
                    return lvlid <= 29 ? -6 : 0;
            }
        }

    }
}
