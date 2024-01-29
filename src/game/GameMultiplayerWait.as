package game
{
    import classes.Language;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCFFRResultsWait;
    import classes.mp.commands.MPCFFRScoreUpdate;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.room.MPRoomFFR;
    import classes.ui.Text;
    import menu.MenuPanel;

    public class GameMultiplayerWait extends MenuPanel
    {
        private static const _gvars:GlobalVariables = GlobalVariables.instance;
        private static const _lang:Language = Language.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;

        private var textWaiting:Text;

        public function GameMultiplayerWait(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function stageAdd():void
        {
            _mp.addEventListener(MPEvent.SOCKET_DISCONNECT, e_onMPDestroy);
            _mp.addEventListener(MPEvent.SOCKET_ERROR, e_onMPDestroy);
            _mp.addEventListener(MPEvent.ROOM_LEAVE_OK, e_onMPDestroy);
            _mp.addEventListener(MPEvent.ROOM_DELETE_OK, e_onMPDestroy);

            if (_mp.GAME_ROOM is MPRoomFFR)
            {
                const ffrRoom:MPRoomFFR = _mp.GAME_ROOM as MPRoomFFR;
                const lastResult:GameScoreResult = _gvars.songResults[_gvars.songResults.length - 1];

                _mp.addEventListener(MPEvent.FFR_MATCH_END, e_onFFRResults);

                // Final Score
                _mp.sendCommand(new MPCFFRScoreUpdate(ffrRoom, lastResult.score, lastResult.amazing, lastResult.perfect, lastResult.good, lastResult.average, lastResult.miss, lastResult.boo, lastResult.combo, lastResult.max_combo));

                // Set to Waiting
                _mp.sendCommand(new MPCFFRResultsWait(ffrRoom));

                textWaiting = new Text(this, 5, 5, "Waiting for match to end...", 28);
                textWaiting.setAreaParams(Main.GAME_WIDTH - 10, Main.GAME_HEIGHT - 10, "center");
            }
        }

        override public function stageRemove():void
        {
            _mp.removeEventListener(MPEvent.SOCKET_DISCONNECT, e_onMPDestroy);
            _mp.removeEventListener(MPEvent.SOCKET_ERROR, e_onMPDestroy);
            _mp.removeEventListener(MPEvent.ROOM_LEAVE_OK, e_onMPDestroy);
            _mp.removeEventListener(MPEvent.ROOM_DELETE_OK, e_onMPDestroy);

            if (_mp.GAME_ROOM is MPRoomFFR)
            {
                _mp.removeEventListener(MPEvent.FFR_MATCH_END, e_onFFRResults);
            }
        }

        private function e_onFFRResults(e:MPRoomEvent):void
        {
            switchTo(GameMenu.GAME_MP_RESULTS);
        }

        private function e_onMPDestroy(e:MPEvent):void
        {
            switchTo(Main.GAME_MENU_PANEL);
        }
    }
}
