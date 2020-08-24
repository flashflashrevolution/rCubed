package classes.replay
{

    public class ReplayNote
    {
        public var direction:String;
        public var frame:Number;
        public var time:Number;
        public var score:Number;

        public function ReplayNote(direction:String, frame:Number = -1, time:Number = -1, score:Number = 0):void
        {
            this.direction = direction;
            this.frame = frame;
            this.time = time;
            this.score = score;
        }

        /**
         * Used to sort vector replay notes by frame number in ASC order.
         * Called in GamePlay after a level end to finalize the replay data.
         * @param a ReplayNote A
         * @param b ReplayNote B
         * @return Number
         */
        public static function sortFunction(a:ReplayNote, b:ReplayNote):Number
        {
            return a.frame - b.frame;
        }
    }

}
