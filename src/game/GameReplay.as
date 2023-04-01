package game
{
    import com.flashfla.utils.TimeUtil;
    import classes.Language;
    import classes.Playlist;
    import flash.text.TextFormat;
    import menu.MenuPanel;

    public class GameReplay extends MenuPanel
    {
        private var _textFormat:TextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 16, 0xFFFFFF, true);

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _playlist:Playlist = Playlist.instance;

        public function GameReplay(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            var replay:Object = _gvars.options.replay;
            _gvars.activeUser = replay.user;
            _gvars.options.fill();
            _gvars.options.fillFromReplay();

            if (_gvars.flashvars.replaySkip)
            {
                _gvars.flashvars.replaySkip = false;
                var songEntry:Object = _gvars.songQueue[0];
                _gvars.songQueue.shift();
                _gvars.songResults.push({game_index: 0,
                        level: replay.level,
                        songFile: null,
                        song: songEntry,
                        amazing: 0,
                        perfect: replay.perfect,
                        good: replay.good,
                        average: replay.average,
                        boo: replay.boo,
                        miss: replay.miss,
                        combo: 0,
                        maxcombo: replay.maxcombo,
                        score: replay.score,
                        lastNote: 0,
                        accuracy: 0,
                        accuracyDeviation: 0,
                        options: _gvars.options,
                        replay: [],
                        replay_hit: [],
                        user: replay.user,
                        restarts: 0,
                        starttime: _gvars.songStartTime,
                        starthash: _gvars.songStartHash,
                        endtime: TimeUtil.getFormattedDate(new Date(replay.timestamp * 1000))});
                switchTo(GameMenu.GAME_RESULTS);
            }
            else
                switchTo(GameMenu.GAME_LOADING);

            return false;
        }

        override public function stageAdd():void
        {

        }
    }
}
