package game
{
    import classes.*;
    import com.flashfla.utils.SystemUtil;
    import flash.display.*;
    import flash.events.*;
    import menu.*;

    public class GameMenu extends MenuPanel
    {
        public static const GAME_LOADING:String = "GameLoading";
        public static const GAME_PLAY:String = "GamePlay";
        public static const GAME_REPLAY:String = "GameReplay";
        public static const GAME_RESULTS:String = "GameResults";

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _playlist:Playlist = Playlist.instance;

        public var panel:MenuPanel;

        public function GameMenu(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            if (_gvars.options.isEditor)
            {
                switchTo(GAME_PLAY);
            }
            else
            {
                // Clone Song queue
                _gvars.totalSongQueue = _gvars.songQueue.concat();
                switchTo(_gvars.flashvars.replay || _gvars.flashvars.preview_file ? GAME_REPLAY : GAME_LOADING);
            }
            return false;
        }

        override public function dispose():void
        {
            if (panel)
            {
                panel.stageRemove();
                panel.dispose();
                if (this.contains(panel))
                    this.removeChild(panel);
                panel = null;
            }
            super.stageRemove();
        }

        override public function switchTo(_panel:String, useNew:Boolean = false):Boolean
        {
            //- Check Parent Function first.
            if (super.switchTo(_panel, useNew))
            {
                _gvars.gameMain.bg.visible = true;
                _gvars.gameMain.ver.visible = true;
                return true;
            }

            //- Do Current Panel
            var isFound:Boolean = false;
            var initValid:Boolean = false;

            if (panel != null)
            {
                panel.stageRemove();
                this.removeChild(panel);
                panel.dispose();
            }

            switch (_panel)
            {
                case GAME_LOADING:
                    panel = new GameLoading(this);
                    _gvars.gameMain.bg.visible = true;
                    _gvars.gameMain.ver.visible = true;
                    isFound = true;
                    break;

                case GAME_PLAY:
                    _gvars.gameMain.bg.visible = false;
                    _gvars.gameMain.ver.visible = false;
                    panel = new GameplayDisplay(this);
                    isFound = true;
                    break;

                case GAME_REPLAY:
                    _gvars.gameMain.bg.visible = false;
                    _gvars.gameMain.ver.visible = false;
                    panel = new GameReplay(this);
                    isFound = true;
                    break;

                case GAME_RESULTS:
                    panel = new GameResults(this);
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
