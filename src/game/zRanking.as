package game
{

    public class zRanking
    {

        public static const ALPHA:Number = 9.9750396740034;
        public static const BETA:Number = 0.0193296437339205;
        public static const LAMBDA:Number = 18206628.7286425;

        public static const D1:Number = 17678803623.9633;
        public static const D2:Number = 733763392.922176;
        public static const D3:Number = 28163834.4879901;
        public static const D4:Number = -434698.513947563;
        public static const D5:Number = 3060.24243867853;

        static public function getSongWeight(song:Object, result:GameScoreResult):Number
        {
            var rawgoods:Number = getRawGoods(result);
            var songweight:Number = 0;
            var delta:Number = D1 + D2 * song.difficulty + D3 * Math.pow(song.difficulty, 2) + D4 * Math.pow(song.difficulty, 3) + D5 * Math.pow(song.difficulty, 4);
            if (delta - rawgoods * LAMBDA > 0)
            {
                songweight = Math.pow((delta - rawgoods * LAMBDA) / delta * Math.pow(song.difficulty + ALPHA, BETA), 1 / BETA) - ALPHA;
            }
            if (songweight < 0 || result.score <= 0 || result.options.songRate != 1 || song.engine != null)
                songweight = 0;
            return songweight;
        }

        static public function getRawGoods(result:GameScoreResult):Number
        {
            return (result.good) + (result.average * 1.8) + (result.miss * 2.4) + (result.boo * 0.2);
        }

    }
}
