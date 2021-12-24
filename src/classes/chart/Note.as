package classes.chart
{

    public class Note
    {
        public var direction:String;
        public var time:Number;
        public var color:String;
        public var frame:Number;

        /**
         * Defines a new Note object.
         * @param	direction
         * @param	time
         * @param	color
         * @param	frame
         */
        public function Note(direction:String, time:Number, color:String, frame:Number = -1):void
        {
            this.direction = direction;
            this.time = time;
            this.color = color;
            this.frame = frame;
        }
    }
}
