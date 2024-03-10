package game.results
{
    import assets.results.MPResultsBackground;
    import classes.Language;
    import classes.SongInfo;
    import classes.mp.mode.ffr.MPMatchResultsFFR;
    import classes.mp.room.MPRoomFFR;
    import classes.score.ScoreHandler;
    import classes.ui.Text;
    import com.flashfla.utils.TimeUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.Sprite;

    public class GameResultFFRView extends Sprite
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _score:ScoreHandler = ScoreHandler.instance;

        private var resultsDisplay:MPResultsBackground;

        private var room:MPRoomFFR;
        private var matchDetails:MPMatchResultsFFR;
        private var scoreSelect:Function;

        // Title Bar
        private var resultsTime:String = TimeUtil.getCurrentDate();
        private var header:Text;
        private var time:Text;

        // Game Result
        private var songName:Text;
        private var songDecription:Text;
        private var gameMode:Text;
        private var textScore:Text;
        private var textAmazing:Text;
        private var textPerfect:Text;
        private var textGood:Text;
        private var textAverage:Text;
        private var textMiss:Text;
        private var textBoo:Text;
        private var textMaxCombo:Text;

        private var list:GameResultFFRScoreList;

        public function GameResultFFRView(room:MPRoomFFR, matchDetails:MPMatchResultsFFR, scoreSelect:Function):void
        {
            this.room = room;
            this.matchDetails = matchDetails;
            this.scoreSelect = scoreSelect;

            resultsDisplay = new MPResultsBackground();
            addChild(resultsDisplay);

            // Text
            header = new Text(this, 20, 10, sprintf(_lang.string("mp_room_ffr_match_end_results"), {"winner": matchDetails.winnerText}), 16, "#E2FEFF");
            header.setAreaParams(420, 26);

            time = new Text(this, 576, 10, resultsTime, 16, "#E2FEFF");
            time.setAreaParams(196, 26, "center");

            const songInfo:SongInfo = matchDetails.songInfo;

            // Song Title
            var seconds:Number = songInfo.time_secs;
            var songLength:String = (Math.floor(seconds / 60)) + ":" + (seconds % 60 >= 10 ? "" : "0") + (seconds % 60);

            var songTitle:String = songInfo.engine ? songInfo.name : "<a href=\"" + URLs.resolve(URLs.LEVEL_STATS_URL) + songInfo.level + "\">" + songInfo.name + "</a>";
            var songSubTitle:String = sprintf(_lang.string("game_results_subtitle_difficulty"), {"value": songInfo.difficulty}) + " - " + sprintf(_lang.string("game_results_subtitle_length"), {"value": songLength});
            if (songInfo.author != "")
                songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_author"), {"value": songInfo.author_html}));
            if (songInfo.stepauthor != "")
                songSubTitle += " - " + _lang.wrapFont(sprintf(_lang.stringSimple("game_results_subtitle_stepauthor"), {"value": songInfo.stepauthor_html}));

            songName = new Text(this, 115, 56, songTitle, 16, "#E2FEFF");
            songName.setAreaParams(545, 30, "center");
            songName.mouseEnabled = true;
            songName.buttonMode = true;

            songDecription = new Text(this, 115, 83, songSubTitle, 12, "#E2FEFF");
            songDecription.textfield.styleSheet = Constant.STYLESHEET;
            songDecription.setAreaParams(545, 20, "center");
            songDecription.mouseChildren = true;
            songDecription.mouseEnabled = true;

            var isTeamMode:Boolean = matchDetails.teams.length > 1;

            // Table
            gameMode = new Text(this, 30, 150, _lang.string(isTeamMode ? "mp_room_ffr_table_mode_team" : "mp_room_ffr_table_mode_ffa"), 12, "#E2FEFF");
            gameMode.setAreaParams(230, 22);

            textScore = new Text(this, 260, 150, _lang.string("mp_room_ffr_table_score"), 12, "#E2FEFF");
            textScore.setAreaParams(100, 22, "center");

            textPerfect = new Text(this, 360, 150, _lang.string("mp_room_ffr_table_perfect"), 12, "#DCFFCB");
            textPerfect.setAreaParams(64, 22, "center");

            textGood = new Text(this, 424, 150, _lang.string("mp_room_ffr_table_good"), 12, "#C1FFBD");
            textGood.setAreaParams(64, 22, "center");

            textAverage = new Text(this, 488, 150, _lang.string("mp_room_ffr_table_average"), 12, "#BCE9C1");
            textAverage.setAreaParams(64, 22, "center");

            textMiss = new Text(this, 552, 150, _lang.string("mp_room_ffr_table_miss"), 12, "#FFE0E0");
            textMiss.setAreaParams(64, 22, "center");

            textBoo = new Text(this, 616, 150, _lang.string("mp_room_ffr_table_boo"), 12, "#E7D0B8");
            textBoo.setAreaParams(64, 22, "center");

            textMaxCombo = new Text(this, 680, 150, _lang.string("mp_room_ffr_table_combo"), 12, "#E2FEFF");
            textMaxCombo.setAreaParams(64, 22, "center");

            list = new GameResultFFRScoreList(this, 30, 180);
            list.setHandler(scoreSelect);
            list.setRoom(matchDetails);
        }
    }
}
