package popups
{
    import assets.GameBackgroundColor;
    import classes.Language;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import com.flashfla.utils.SpriteUtil;
    import flash.display.Bitmap;
    import flash.events.MouseEvent;
    import menu.MenuPanel;

    public class PopupContextMenu extends MenuPanel
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        //- Background
        private var box:Box;
        private var bmp:Bitmap;

        public function PopupContextMenu(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function stageAdd():void
        {
            bmp = SpriteUtil.getBitmapSprite(stage);
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

            //- Reload Engine
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_reload_engine_user"), 12, clickHandler);
            cButton.action = "reload_engine";
            yOff += cButtonHeight + 5;

            //- Screenshot - Local
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_save_screenshot"), 12, clickHandler);
            cButton.action = "screenshot_local";
            yOff += cButtonHeight + 5;

            //- Fullscreen
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_full_screen"), 12, clickHandler);
            cButton.action = "fullscreen";
            yOff += cButtonHeight + 5;

            //- Switch Profile
            cButton = new BoxButton(box, 5, yOff, box.width - 10, cButtonHeight, _lang.string("popup_cm_switch_profile"), 12, clickHandler);
            cButton.action = "switch_profile";
            yOff += cButtonHeight + 5;

            //- Close
            cButton = new BoxButton(box, 5, box.height - 27 - 5, box.width - 10, 27, _lang.string("menu_close"), 12, clickHandler);
            cButton.action = "close";
        }

        override public function stageRemove():void
        {
            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmp = null;
            box = null;
        }

        private function clickHandler(e:MouseEvent):void
        {
            removePopup();

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
                _gvars.reloadEngineData();
            }
            else if (e.target.action == "switch_profile")
            {
                _gvars.switchUserAccount();
            }
        }
    }
}
