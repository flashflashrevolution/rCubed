package classes.mp.mode.ffr
{

    import classes.ImageCache;
    import classes.User;
    import classes.mp.MPUser;
    import game.GameOptions;
    import game.GameScoreResult;

    public class MPMatchResultsUser extends MPUser
    {
        public var index:Number;

        public var team:MPMatchResultsTeam;
        public var user:User;

        public var alive:Boolean;
        public var position:int;
        public var score:GameScoreResult;

        override public function update(data:Object):void
        {
            super.update(data.user);

            this.alive = data.alive;
            this.position = data.position;

            user = new User(false, false, sid);
            user.name = name;
            user.skillLevel = skillRating;
            user.skillRating = skillRating;
            user.avatar = ImageCache.getImage(avatarURL, 0, 99, 99);

            score = new GameScoreResult();
            score.game_index = -2;
            score.amazing = data.amazing;
            score.score = data.raw_score;
            score.perfect = data.perfect;
            score.good = data.good;
            score.boo = data.boo;
            score.average = data.average;
            score.miss = data.miss;
            score.combo = data.combo;
            score.max_combo = data.max_combo;

            score.user = user;
            score.options = new GameOptions();
            score.options.settingsDecode(data.settings);
        }

        override public function toString():String
        {
            return name;
        }
    }
}
