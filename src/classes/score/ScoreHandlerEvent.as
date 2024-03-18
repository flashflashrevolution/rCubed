package classes.score
{
    import flash.events.Event;
    import game.GameScoreResult;

    public class ScoreHandlerEvent extends Event
    {
        public static const SUCCESS:String = "success";
        public static const FAILURE:String = "failure";

        public var result:GameScoreResult;
        public var rank:String;
        public var last_best:String;
        public var hash:String;

        public function ScoreHandlerEvent(type:String, result:GameScoreResult, rank:String, best:String, hash:String = ""):void
        {
            super(type, false, false);
            this.result = result;
            this.rank = rank;
            this.last_best = best;
            this.hash = hash;
        }
    }
}
