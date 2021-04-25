package game.graph
{

    public class GraphCrossPoint
    {
        public var index:int;
        public var x:Number;
        public var y:Number;
        public var timing:Number;
        public var color:uint;
        public var score:int;
        public var column:String;

        public function GraphCrossPoint(index:int, pos_x:Number, pos_y:Number, timing:Number, color:uint, score:int, column:String):void
        {
            this.index = index;
            this.x = pos_x;
            this.y = pos_y;
            this.timing = timing;
            this.color = color;
            this.score = score;
            this.column = column
        }
    }
}
