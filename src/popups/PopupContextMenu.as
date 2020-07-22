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
    import menu.MenuPanel;

    public class PopupContextMenu extends MenuPanel
    {
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

            CONFIG::debug
            {
                //- Profiler
                cButton = new BoxButton(box.width - 10, cButtonHeight, "Toggle Profiler");
                cButton.x = 5;
                cButton.y = yOff;
                cButton.action = "debugProfiler";
                cButton.addEventListener(MouseEvent.CLICK, clickHandler);
                this.addChild(cButton);
                yOff += cButtonHeight + 5;

                //- Redraw
                cButton = new BoxButton(box.width - 10, cButtonHeight, "Toggle ReDraw Regions");
                cButton.x = 5;
                cButton.y = yOff;
                cButton.action = "redrawRegions";
                cButton.addEventListener(MouseEvent.CLICK, clickHandler);
                this.addChild(cButton);
                yOff = 5;
            }

            //- Fullscreen
            cButton = new BoxButton(box.width - 10, cButtonHeight, "Save ScreenShot - Local");
            cButton.x = 5;
            cButton.y = yOff;
            cButton.action = "screenshotLocal";
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
                if (e.target.action == "debugProfiler")
                {
                    SWFProfiler.onSelect();
                }
                else if (e.target.action == "redrawRegions")
                {

                }
            }

            //- Close
            if (e.target.action == "fullscreen")
            {
                try
                {
                    _gvars.toggleFullScreen();
                }
                catch (e:Error)
                {
                }
            }
            else if (e.target.action == "screenshotLocal")
            {
                _gvars.takeScreenShot();
            }
            else if (e.target.action == "options")
            {
                addPopup(Main.POPUP_OPTIONS);
            }
        }
    }

}
