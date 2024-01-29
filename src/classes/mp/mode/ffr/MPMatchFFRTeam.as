package classes.mp.mode.ffr
{

    public class MPMatchFFRTeam
    {
        public var users:Vector.<MPMatchFFRUser> = new <MPMatchFFRUser>[];

        public var id:int = 0;
        public var position:int = 1;
        public var raw_score:Number = 0;

        public function update(data:Object):void
        {
            if (data.id != undefined)
                id = data.id;

            if (data.raw_score != undefined)
                position = data.position;

            if (data.raw_score != undefined)
                raw_score = data.raw_score;
        }
    }
}
