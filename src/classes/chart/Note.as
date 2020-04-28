package classes.chart
{

    public class Note
    {
        public var direction:String;
        public var time:Number;
        public var colour:String;
        public var frame:Number;

        /**
         * Defines a new Note object.
         * @param	direction
         * @param	time
         * @param	colour
         * @param	frame
         */
        public function Note(direction:String, time:Number, colour:String, frame:Number = -1):void
        {
            this.direction = direction;
            this.time = time;
            this.colour = colour;
            this.frame = frame;
        }
    }
}
