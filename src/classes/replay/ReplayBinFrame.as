package classes.replay
{

    public class ReplayBinFrame
    {
        public var time:int;
        public var direction:String;
        public var index:int;

        public function ReplayBinFrame(time:int, dir:String = "", index:int = 0):void
        {
            this.time = time;
            this.direction = dir;
            this.index = index;
        }
    }

}
