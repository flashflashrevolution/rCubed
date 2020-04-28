package classes.chart
{

    public class BPMSegment
    {
        public var start:Number;
        public var end:Number;
        public var bpm:Number;

        public function BPMSegment(start:Number, bpm:Number, end:Number = -1):void
        {
            this.start = start;
            this.end = end;
            this.bpm = bpm;
        }

        public function get totalTime():Number
        {
            return 240.0 * (end - start) / end;
        }

    }
}
