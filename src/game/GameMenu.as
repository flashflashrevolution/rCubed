package game
{
    import classes.Language;
    import com.flashfla.utils.SystemUtil;
    import menu.MenuPanel;

    public class GameMenu extends MenuPanel
    {
        public static const GAME_LOADING:String = "GameLoading";
        public static const GAME_PLAY:String = "GamePlay";
        public static const GAME_RESULTS:String = "GameResults";
        public static const GAME_MP_WAIT:String = "GameMPWait";
        public static const GAME_MP_RESULTS:String = "GameMPResults";

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        public var panel:MenuPanel;

        public function GameMenu(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            if (Flags.VALUES[Flags.MP_MENU_RESULTS])
            {
                Flags.VALUES[Flags.MP_MENU_RESULTS] = false;
                switchTo(GAME_MP_RESULTS);
            }
            else if (_gvars.options.isEditor)
            {
                switchTo(GAME_PLAY);
            }
            else
            {
                // Clone Song queue
                _gvars.totalSongQueue = _gvars.songQueue.concat();
                switchTo(GAME_LOADING);
            }
            return false;
        }

        override public function stageRemove():void
        {
            if (panel && panel.stage)
                panel.stageRemove();

            super.stageRemove();
        }

        override public function dispose():void
        {
            if (panel)
            {
                panel.dispose();
                if (this.contains(panel))
                    this.removeChild(panel);
                panel = null;
            }
            super.dispose();
        }

        override public function switchTo(_panel:String):Boolean
        {
            //- Check Parent Function first.
            if (super.switchTo(_panel))
            {
                _gvars.gameMain.bg.updateDisplay();
                _gvars.gameMain.ver.visible = true;

                if (panel != null)
                {
                    panel.stageRemove();
                    panel.parent.removeChild(panel);
                    panel.dispose();
                }

                return true;
            }

            //- Do Current Panel
            var isFound:Boolean = false;
            var initValid:Boolean = false;

            if (panel != null)
            {
                panel.stageRemove();
                panel.parent.removeChild(panel);
                panel.dispose();
            }

            switch (_panel)
            {
                case GAME_LOADING:
                    panel = new GameLoading(this);
                    _gvars.gameMain.bg.updateDisplay();
                    _gvars.gameMain.ver.visible = true;
                    isFound = true;
                    break;

                case GAME_PLAY:
                    panel = new GameplayDisplay(this);
                    _gvars.gameMain.bg.updateDisplay(true);
                    _gvars.gameMain.ver.visible = false;
                    isFound = true;
                    break;

                case GAME_RESULTS:
                    panel = new GameResults(this);
                    _gvars.gameMain.ver.visible = true;
                    isFound = true;
                    break;

                case GAME_MP_WAIT:
                    panel = new GameMultiplayerWait(this);
                    _gvars.gameMain.bg.updateDisplay(true);
                    _gvars.gameMain.ver.visible = true;
                    isFound = true;
                    break;

                case GAME_MP_RESULTS:
                    panel = new GameResultsMP(this);
                    _gvars.gameMain.ver.visible = true;
                    isFound = true;
                    break;
            }
            this.addChild(panel);
            if (!panel.hasInit)
            {
                initValid = panel.init();
                panel.hasInit = true;
            }

            if (initValid)
                panel.stageAdd();

            SystemUtil.gc();
            return isFound;
        }
    }
}
