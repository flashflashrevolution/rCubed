package game
{

    import classes.chart.Song;
    import flash.utils.ByteArray;
    import classes.User;
    import classes.replay.ReplayNote;
    import classes.replay.ReplayPack;
    import classes.replay.Base64Encoder;

    public class GameScoreResult
    {
        public var game_index:int;
        public var level:int;
        public var song:Song;
        public var song_entry:Object;
        public var note_count:int;

        public var legacyLastRank:Object;

        public var user:User;
        public var options:GameOptions;

        public var amazing:int = 0;
        public var perfect:int = 0;
        public var good:int = 0;
        public var average:int = 0;
        public var boo:int = 0;
        public var miss:int = 0;
        public var combo:int = 0;
        public var max_combo:int = 0;
        public var score:int = 0;

        public function get raw_goods():Number
        {
            return good + (average * 1.8) + (miss * 2.4) + (boo * 0.2);
        }
        public var restarts:int;
        public var restart_stats:Object;
        public var last_note:int;

        public var accuracy:Number;
        public var accuracy_deviation:Number;

        public function get accuracy_frames():Number
        {
            return 30 * accuracy / 1000;
        }

        public function get accuracy_deviation_frames():Number
        {
            return 30 * accuracy_deviation / 1000;
        }

        // Replay v3
        public var replay:Array;
        public var replay_hit:Array;

        // Binary Replays (aka Replay v4)
        public var replay_bin_notes:Array;
        public var replay_bin_boos:Array;
        private var _replay_bin:ByteArray;

        public function get replay_bin():ByteArray
        {
            if (_replay_bin == null)
            {
                var judgementsEncode:String = JSON.stringify({"amazing": amazing, "perfect": perfect, "good": good, "average": average, "boo": boo, "miss": miss, "maxcombo": max_combo});
                _replay_bin = ReplayPack.writeReplay(user, options, judgementsEncode, replay_bin_notes, replay_bin_boos);
            }

            return _replay_bin;
        }

        public function get replay_bin_encoded():String
        {
            var enc:Base64Encoder = new Base64Encoder();
            enc.encodeBytes(replay_bin);
            return ReplayPack.MAGIC + "|" + enc.toString();
        }

        public var start_time:String;
        public var start_hash:String;
        public var endtime:String;
        public var songprogress:Number;
        public var playtime_secs:Number;

        // Judge Settings
        public var MIN_TIME:int = 0;
        public var MAX_TIME:int = 0;
        public var GAP_TIME:int = 0;
        public var judge:Array;

        public function updateJudge():void
        {
            // Get Judge Window
            judge = Constant.JUDGE_WINDOW;
            if (options.judgeWindow)
                judge = options.judgeWindow;

            // Get Judge Window Size
            for (var jn:int = 0; jn < judge.length; jn++)
            {
                var jni:Object = judge[jn];
                if (jni.t < MIN_TIME)
                    MIN_TIME = jni.t;

                if (jni.t > MAX_TIME)
                    MAX_TIME = jni.t;
            }

            GAP_TIME = MAX_TIME - MIN_TIME;
        }

        public function getJudgeRegion(time:int):Object
        {
            var lastJudge:Object;

            for each (var j:Object in judge)
                if ((time * -1) > j.t)
                    lastJudge = j;

            return lastJudge;
        }

        public function get total():Number
        {
            return ((amazing + perfect) * 500) + (good * 250) + (average * 50) + (max_combo * 1000) - (miss * 300) - (boo * 15) + score;
        }

        public function get pa_string():String
        {
            return (amazing + perfect) + "-" + good + "-" + average + "-" + miss + "-" + boo;
        }

        public function get screenshot_path():String
        {
            var rateString:String = options.songRate != 1 ? " (" + options.songRate + "x Rate)" : "";

            return "R^3 - " + song_entry.name + rateString + " - " + score + " - " + pa_string;
        }
    }
}
