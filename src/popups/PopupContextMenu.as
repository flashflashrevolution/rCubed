package popups
{
    import arc.mp.MultiplayerSingleton;
    import assets.GameBackgroundColor;
    import classes.Box;
    import classes.BoxButton;
    import classes.Language;
    import classes.Playlist;
    import com.flashdynamix.utils.SWFProfiler;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.profiler.showRedrawRegions;
    import game.GameMenu;
    import menu.MenuPanel;

    public class PopupContextMenu extends MenuPanel
    {
        CONFIG::debug
        {
            private static var redrawBoolean:Boolean = false;
        }

        public var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        public function PopupContextMenu(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function stageAdd():void
        {
            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);

            this.addChild(bmp);

            var bgbox:Box = new Box(this, (Main.GAME_WIDTH - 230) / 2, 20, false, false);
            bgbox.setSize(230, Main.GAME_HEIGHT - 40);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;

            box = new Box(this, (Main.GAME_WIDTH - 230) / 2, 20, false, false);
            box.setSize(230, Main.GAME_HEIGHT - 40);
            box.activeAlpha = 0.4;

            var cButton:BoxButton;
            var cButtonHeight:Number = 39;
            var yOff:Number = 5;

            // Debug Options
            CONFIG::debug
            {
                //- Profiler
                cButton = new BoxButton(this, 5, yOff, box.width - 10, cButtonHeight, "Toggle Profiler", 12, clickHandler);
                cButton.action = "debug_profiler";
                cButton.boxColor = GameBackgroundColor.BG_POPUP;
                yOff += cButtonHeight + 5;

                //- Redraw
                cButton = new BoxButton(this, 5, yOff, box.width - 10, cButtonHeight, "Toggle ReDraw Regions", 12, clickHandler);
                cButton.action = "redraw_regions";
                cButton.boxColor = GameBackgroundColor.BG_POPUP;
                yOff = 5;
            }

            //- Reload Engine
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_reload_engine_user", "Reload Engine / User"), 12, clickHandler);
            cButton.action = "reload_engine";
            yOff += cButtonHeight + 5;

            //- Screenshot - Local
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_save_screenshot", "Save ScreenShot - Local"), 12, clickHandler);
            cButton.action = "screenshot_local";
            yOff += cButtonHeight + 5;

            //- Fullscreen
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_full_screen", "Full Screen"), 12, clickHandler);
            cButton.action = "fullscreen";
            yOff += cButtonHeight + 5;

            //- Switch Profile
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_switch_profile", "Switch Profile"), 12, clickHandler);
            cButton.action = "switch_profile";
            yOff += cButtonHeight + 5;

            //- Close
            cButton = new BoxButton(box, 5, box.height - 27 - 5, box.width - 10, 27, _lang.string("menu_close", "CLOSE"), 12, clickHandler);
            cButton.action = "close";
        }

        override public function stageRemove():void
        {
            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        private function clickHandler(e:MouseEvent):void
        {
            removePopup();

            //- Debug Actions
            CONFIG::debug
            {
                if (e.target.action == "debug_profiler")
                {
                    SWFProfiler.onSelect();
                }
                else if (e.target.action == "redraw_regions")
                {
                    redrawBoolean = !redrawBoolean;
                    showRedrawRegions(redrawBoolean, 0xFF0000);
                }
            }

            //- Close
            if (e.target.action == "fullscreen")
            {
                _gvars.toggleFullScreen();
            }
            else if (e.target.action == "screenshot_local")
            {
                _gvars.takeScreenShot();
            }
            else if (e.target.action == "reload_engine")
            {
                if (_gvars.gameMain.loadComplete && !(_gvars.gameMain.activePanel is GameMenu))
                {
                    MultiplayerSingleton.destroyInstance();
                    Flags.VALUES = {};
                    Playlist.clearCanon();
                    _gvars.gameMain.loadComplete = false;
                    _gvars.gameMain.switchTo("none");
                }
            }
            else if (e.target.action == "switch_profile")
            {
                if (_gvars.gameMain.loadComplete && !(_gvars.gameMain.activePanel is GameMenu))
                {
                    MultiplayerSingleton.destroyInstance();
                    Flags.VALUES = {};
                    _gvars.playerUser.refreshUser();
                    _gvars.gameMain.switchTo(Main.GAME_LOGIN_PANEL);
                }
            }
        }
    }
}
