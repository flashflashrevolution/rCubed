package classes.chart
{

    public class Stop
    {
        public var time:Number;
        public var length:Number;

        public function Stop(pos:Number, length:Number):void
        {
            this.time = pos;
            this.length = length;
        }

    }
}
