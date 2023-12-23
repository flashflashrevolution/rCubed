package classes.user
{
    import com.flashfla.net.WebRequest;
    import flash.events.EventDispatcher;

    public class UserStats extends EventDispatcher
    {
        private static var cache:Object = {};

        public var userid:Number;
        public var aaa:Number;
        public var fc:Number;
        public var tier_points:Number;
        public var tier_bonus:Number;
        public var tier_total:Number;
        public var equiv_cutoff:Number;
        public var equiv_scores:Vector.<UserStatsScore>;

        public var tier_tiers:Array;
        public var total_songs:Number;
        public var total_tier_points:Number;

        public function UserStats(data:Object):void
        {
            if (data.userid != undefined)
                this.userid = data.userid;

            if (data.aaa != undefined)
                this.aaa = data.aaa;

            if (data.fc != undefined)
                this.fc = data.fc;

            if (data.tier_points != undefined)
                this.tier_points = data.tier_points;

            if (data.tier_bonus != undefined)
                this.tier_bonus = data.tier_bonus;

            if (data.tier_total != undefined)
                this.tier_total = data.tier_total;

            if (data.equiv_cutoff != undefined)
                this.equiv_cutoff = data.equiv_cutoff;

            if (data.equiv_scores != undefined)
            {
                this.equiv_scores = new <UserStatsScore>[];
                for each (var score:Object in data.equiv_scores)
                {
                    this.equiv_scores.push(new UserStatsScore(score));
                }
            }

            if (data.tier_tiers != undefined)
                this.tier_tiers = data.tier_tiers;

            if (data.total_songs != undefined)
                this.total_songs = data.total_songs;

            if (data.total_tier_points != undefined)
                this.total_tier_points = data.total_tier_points;
        }

        public static function load(userid:Number, callback:Function):void
        {
            if (cache[userid])
            {
                callback(cache[userid]);
                return;
            }

            var wr:WebRequest = new WebRequest(URLs.resolve(URLs.USER_STATS_URL), c_loadComplete, c_loadError);
            wr.load({"userid": userid});

            function c_loadComplete(e:* = null):void
            {
                try
                {
                    cache[userid] = new UserStats(JSON.parse(e.target.data));
                    callback(cache[userid]);
                }
                catch (e:Error)
                {
                    c_loadError();
                }
            }

            function c_loadError(e:* = null):void
            {
                callback(null);
            }
        }
    }
}
