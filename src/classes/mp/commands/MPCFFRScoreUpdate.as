package classes.mp.commands
{
    import classes.mp.room.MPRoom;

    public class MPCFFRScoreUpdate implements IMPCommand
    {
        public var room:MPRoom;

        public var raw_score:int;
        public var amazing:int;
        public var perfect:int;
        public var good:int;
        public var average:int;
        public var miss:int;
        public var boo:int;
        public var combo:int;
        public var max_combo:int;

        public function MPCFFRScoreUpdate(room:MPRoom, raw_score:int, amazing:int, perfect:int, good:int, average:int, miss:int, boo:int, combo:int, max_combo:int):void
        {
            this.room = room;

            this.raw_score = raw_score;
            this.amazing = amazing;
            this.perfect = perfect;
            this.good = good;
            this.average = average;
            this.miss = miss;
            this.boo = boo;
            this.combo = combo;
            this.max_combo = max_combo;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "score_update",
                    "d": {
                        "uid": room.uid,
                        "raw_score": raw_score,
                        "amazing": amazing,
                        "perfect": perfect,
                        "good": good,
                        "average": average,
                        "miss": miss,
                        "boo": boo,
                        "combo": combo,
                        "max_combo": max_combo
                    }});
        }
    }
}
