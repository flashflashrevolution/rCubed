package game
{

    import classes.SongInfo;

    public class SkillRating
    {

        public static const ALPHA:Number = 9.9750396740034;
        public static const BETA:Number = 0.0193296437339205;
        public static const LAMBDA:Number = 18206628.7286425;

        public static const D1:Number = 17678803623.9633;
        public static const D2:Number = 733763392.922176;
        public static const D3:Number = 28163834.4879901;
        public static const D4:Number = -434698.513947563;
        public static const D5:Number = 3060.24243867853;

        static public function getSongWeight(result:GameScoreResult):Number
        {
            if (result == null || result.songInfo == null)
                return 0;
            var rawgoods:Number = result.raw_goods;
            var songweight:Number = 0;
            var difficulty:Number = result.songInfo.difficulty;
            var delta:Number = D1 + D2 * difficulty + D3 * Math.pow(difficulty, 2) + D4 * Math.pow(difficulty, 3) + D5 * Math.pow(difficulty, 4);
            if (delta - rawgoods * LAMBDA > 0)
            {
                songweight = Math.pow((delta - rawgoods * LAMBDA) / delta * Math.pow(difficulty + ALPHA, BETA), 1 / BETA) - ALPHA;
            }
            if (songweight < 0 || result.score <= 0 || result.options.songRate != 1 || result.songInfo.engine != null)
                songweight = 0;
            return songweight;
        }

        static public function calcSongWeightFromScore(rawScore:Number, song:SongInfo):Number
        {
            var rawGoods:Number = calcRawGoods(rawScore, song);
            
            return calcSongWeightFromRawGoods(rawGoods, song);
        }

        static public function calcSongWeightFromRawGoods(rawGoods:Number, song:SongInfo):Number
        {
            if (song == null)
                return 0;
            var songweight:Number = 0;
            var difficulty:Number = song.difficulty;
            var delta:Number = D1 + D2 * difficulty + D3 * Math.pow(difficulty, 2) + D4 * Math.pow(difficulty, 3) + D5 * Math.pow(difficulty, 4);
            if (delta - rawGoods * LAMBDA > 0)
            {
                songweight = Math.pow((delta - rawGoods * LAMBDA) / delta * Math.pow(difficulty + ALPHA, BETA), 1 / BETA) - ALPHA;
            }
            if (songweight < 0)
                songweight = 0;
            return songweight;
        }

        static public function getRawGoodsFromEquiv(song:SongInfo, targetEquiv:Number):Number
        {
            if (song == null || targetEquiv == 0)
                return 0;
            
            var rawgoods:Number = 0;
            var songweight:Number = targetEquiv;
            var difficulty:Number = song.difficulty;
            var delta:Number = D1 + D2 * difficulty + D3 * Math.pow(difficulty, 2) + D4 * Math.pow(difficulty, 3) + D5 * Math.pow(difficulty, 4);
            
            rawgoods = (delta - delta * Math.pow(songweight + ALPHA, BETA) / Math.pow(difficulty + ALPHA, BETA)) / LAMBDA;
            
            return Math.round(rawgoods * 5) / 5;
        }

        static public function getRawGoods(result:Object):Number
        {
            return (result.good) + (result.average * 1.8) + (result.miss * 2.4) + (result.boo * 0.2);
        }

        static public function calcRawGoods(rawScore:Number, song:SongInfo):Number
        {
            return Math.round(((song.score_raw - rawScore) / 25) * 5) / 5;
        }

    }
}
