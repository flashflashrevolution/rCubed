package classes.mp.components.chatlog
{
    import classes.Language;
    import classes.mp.Multiplayer;
    import classes.mp.mode.ffr.MPMatchResultsFFR;
    import classes.mp.room.MPRoomFFR;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import com.flashfla.utils.sprintf;
    import flash.events.Event;

    public class MPChatLogEntryMatchResults extends MPChatLogEntry
    {
        private static const _lang:Language = Language.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;

        private var room:MPRoomFFR;
        private var results:MPMatchResultsFFR;
        private var index:int;

        private var btn:BoxButton;

        public function MPChatLogEntryMatchResults(room:MPRoomFFR, results:MPMatchResultsFFR):void
        {
            this.room = room;
            this.results = results;
        }

        override public function build(width:Number):void
        {
            if (built)
                return;

            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(5, 5, width - 11, 45);
            this.graphics.endFill();

            new Text(this, 10, 7, _lang.string("mp_room_ffr_match_end"), 10, "#c3c3c3").setAreaParams(width - 120, 22);
            new Text(this, 9, 25, sprintf(_lang.string("mp_room_ffr_match_end_results"), {"winner": results.winnerText}), 12).setAreaParams(width - 110, 22);

            btn = new BoxButton(this, width - 96, 14, 85, 26, _lang.string("mp_room_ffr_match_end_view"), 11, e_viewResults);

            _height = 52;
            built = true;
        }

        private function e_viewResults(e:Event):void
        {
            room.lastMatchIndex = results.index;

            Flags.VALUES[Flags.MP_MENU_RESULTS] = true;
            GlobalVariables.instance.gameMain.switchTo(Main.GAME_PLAY_PANEL);
        }
    }
}
