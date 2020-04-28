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
    }

}
