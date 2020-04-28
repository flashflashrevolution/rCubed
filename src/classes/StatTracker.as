package classes
{

    public class StatTracker
    {
        public var raw_score:Number = 0;
        public var grandtotal:Number = 0;
        public var restarts:Number = 0;
        public var amazing:Number = 0;
        public var perfect:Number = 0;
        public var good:Number = 0;
        public var average:Number = 0;
        public var miss:Number = 0;
        public var boo:Number = 0;
        public var credits:Number = 0;

        public function get data():Object
        {
            return {"raw_score": raw_score,
                    "grandtotal": grandtotal,
                    "restarts": restarts,
                    "amazing": amazing,
                    "perfect": perfect,
                    "good": good,
                    "average": average,
                    "miss": miss,
                    "boo": boo,
                    "credits": credits}
        }

        public function reset():void
        {
            raw_score = 0;
            grandtotal = 0;
            restarts = 0;
            amazing = 0;
            perfect = 0;
            good = 0;
            average = 0;
            miss = 0;
            boo = 0;
            credits = 0;
        }

        public function addFromStats(stats:StatTracker):void
        {
            raw_score += stats.raw_score;
            grandtotal += stats.grandtotal;
            restarts += stats.restarts;
            amazing += stats.amazing;
            perfect += stats.perfect;
            good += stats.good;
            average += stats.average;
            miss += stats.miss;
            boo += stats.boo;
            credits += stats.credits;
        }

    }

}
