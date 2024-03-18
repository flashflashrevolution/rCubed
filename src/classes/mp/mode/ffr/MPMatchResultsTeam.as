package classes.mp.mode.ffr
{

    public class MPMatchResultsTeam
    {
        public var uid:int;
        public var name:String;
        public var raw_score:Number;
        public var position:int;
        public var users:Vector.<MPMatchResultsUser> = new <MPMatchResultsUser>[];

        public function update(data:Object):void
        {
            if (data.id != undefined)
                this.uid = data.id;

            if (data.name != undefined)
                this.name = data.name;

            if (data.raw_score != undefined)
                this.raw_score = data.raw_score;

            if (data.position != undefined)
                this.position = data.position;
        }
    }
}
