package classes.mp.mode.ffr
{
    import classes.mp.MPUser;
    import classes.mp.room.MPRoomFFR;

    public class MPMatchFFRUser
    {
        public var user:MPUser;
        public var room:MPRoomFFR;

        public var raw_score:Number = 0;
        public var position:Number = 1;

        public var amazing:Number = 0;
        public var perfect:Number = 0;
        public var good:Number = 0;
        public var average:Number = 0;
        public var miss:Number = 0;
        public var boo:Number = 0;
        public var max_combo:Number = 0;

        public function MPMatchFFRUser(room:MPRoomFFR, user:MPUser):void
        {
            this.room = room;
            this.user = user;
        }

        public function update(data:Object):void
        {
            if (data.raw_score != null)
                this.raw_score = data.raw_score;

            if (data.position != null)
                this.position = data.position;

            if (data.amazing != null)
                this.amazing = data.amazing;

            if (data.perfect != null)
                this.perfect = data.perfect;

            if (data.good != null)
                this.good = data.good;

            if (data.average != null)
                this.average = data.average;

            if (data.miss != null)
                this.miss = data.miss;

            if (data.boo != null)
                this.boo = data.boo;

            if (data.max_combo != null)
                this.max_combo = data.max_combo;
        }

        public function get getNoteIndex():int
        {
            return amazing + perfect + good + average + miss;
        }
    }
}
