package popups
{
    import classes.Box;
    import classes.BoxButton;
    import com.flashdynamix.utils.SWFProfiler;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.profiler.showRedrawRegions;

    import menu.MenuPanel;

    public class PopupContextMenu extends MenuPanel
    {
        private static var redrawBoolean:Boolean = false;

        public var _gvars:GlobalVariables = GlobalVariables.instance;

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

            box = new Box(230, Main.GAME_HEIGHT - 40, false, false);
            box.x = (Main.GAME_WIDTH / 2) - box.width / 2;
            box.y = 20;
            box.activeAlpha = 0.4;
            this.addChild(box);

            var cButton:BoxButton;
            var cButtonHeight:Number = 39;
            var yOff:Number = 5;

            // Debug Options
            CONFIG::debug
            {
                //- Profiler
                cButton = new BoxButton(box.width - 10, cButtonHeight, "Toggle Profiler");
                cButton.x = 5;
                cButton.y = yOff;
                cButton.action = "debug_profiler";
                cButton.boxColor = 0x222222;
                cButton.addEventListener(MouseEvent.CLICK, clickHandler);
                this.addChild(cButton);
                yOff += cButtonHeight + 5;

                //- Redraw
                cButton = new BoxButton(box.width - 10, cButtonHeight, "Toggle ReDraw Regions");
                cButton.x = 5;
                cButton.y = yOff;
                cButton.action = "redraw_regions";
                cButton.boxColor = 0x222222;
                cButton.addEventListener(MouseEvent.CLICK, clickHandler);
                this.addChild(cButton);
                yOff = 5;
            }

            //- Reload Engine
            cButton = new BoxButton(box.width - 10, cButtonHeight, "Reload Engine / User");
            cButton.x = 5;
            cButton.y = yOff;
            cButton.action = "reload_engine";
            cButton.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(cButton);
            yOff += cButtonHeight + 5;

            //- Screenshot - Local
            cButton = new BoxButton(box.width - 10, cButtonHeight, "Save ScreenShot - Local");
            cButton.x = 5;
            cButton.y = yOff;
            cButton.action = "screenshot_local";
            cButton.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(cButton);
            yOff += cButtonHeight + 5;

            //- Fullscreen
            cButton = new BoxButton(box.width - 10, cButtonHeight, "Full Screen");
            cButton.x = 5;
            cButton.y = yOff;
            cButton.action = "fullscreen";
            cButton.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(cButton);
            yOff += cButtonHeight + 5;

            //- Switch Profile
            cButton = new BoxButton(box.width - 10, cButtonHeight, "Switch Profile");
            cButton.x = 5;
            cButton.y = yOff;
            cButton.action = "switch_profile";
            cButton.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(cButton);
            yOff += cButtonHeight + 5;

            //- Close
            cButton = new BoxButton(box.width - 10, 27, "CLOSE");
            cButton.x = 5;
            cButton.y = box.height - cButton.height - 5;
            cButton.action = "close";
            cButton.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(cButton);
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
                _gvars.takeScreenShot({o: false, s: 1});
            }
            else if (e.target.action == "reload_engine")
            {
                _gvars.tempFlags = {};
                _gvars.gameMain.switchTo("none");
            }
            else if (e.target.action == "switch_profile")
            {
                _gvars.tempFlags = {};
                _gvars.gameMain.switchTo("GameLoginPanel");
            }
        }
    }

}
