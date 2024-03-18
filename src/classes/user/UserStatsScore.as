package classes.user
{

    public class UserStatsScore
    {
        public var level_id:Number;

        public var perfect:Number;
        public var good:Number;
        public var average:Number;
        public var miss:Number;
        public var boo:Number;
        public var combo:Number;

        public var weight:Number;

        public function UserStatsScore(data:Object)
        {
            level_id = data.song;

            perfect = data.pa[0];
            good = data.pa[1];
            average = data.pa[2];
            miss = data.pa[3];
            boo = data.pa[4];
            combo = data.pa[5];

            weight = data.weight;
        }

        /**
         * Gets the PA string displayed in several places.
         * Example: 1653-1-0-0-0
         */
        public function get pa_string():String
        {
            return perfect + "-" + good + "-" + average + "-" + miss + "-" + boo;
        }

        public function get score():Number
        {
            return (((perfect) * 50) + (good * 25) + (average * 5) - (miss * 10) - (boo * 5));
        }
    }
}
