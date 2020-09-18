package popups
{
    import assets.GameBackgroundColor;
    import classes.Box;
    import classes.BoxButton;
    import classes.Language;
    import classes.Text;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import menu.MenuPanel;

    public class PopupMessage extends MenuPanel
    {
        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var titleDisplay:Text;
        private var messageDisplay:Text;

        private var _lang:Language = Language.instance;

        private var displayTitle:String = "";
        private var dislayText:String = _lang.string("popup_message_missing_error_text");
        private var closeOptions:BoxButton;

        public function PopupMessage(myParent:MenuPanel, dislayText:String, displayTitle:String = "")
        {
            super(myParent);
            this.dislayText = dislayText;
            this.displayTitle = displayTitle;
        }

        override public function stageAdd():void
        {
            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);

            this.addChild(bmp);

            var bgbox:Box = new Box(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40, false, false);
            bgbox.x = 20;
            bgbox.y = 20;
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;
            this.addChild(bgbox);

            box = new Box(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40, false, false);
            box.x = 20;
            box.y = 20;
            box.activeAlpha = 0.4;
            this.addChild(box);

            titleDisplay = new Text(displayTitle, 20);
            titleDisplay.x = 5;
            titleDisplay.y = 5;
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;
            box.addChild(titleDisplay);

            messageDisplay = new Text(dislayText, 14);
            messageDisplay.x = 5;
            messageDisplay.height = box.height;
            messageDisplay.width = box.width - 10;
            messageDisplay.align = Text.CENTER;
            box.addChild(messageDisplay);

            //- Close
            closeOptions = new BoxButton(79.5, 27, _lang.string("menu_close"));
            closeOptions.x = box.width - 94.5;
            closeOptions.y = box.height - 42;
            closeOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(closeOptions);
        }

        override public function stageRemove():void
        {
            closeOptions.dispose();
            box.dispose();
            titleDisplay.dispose();
            messageDisplay.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        private function clickHandler(e:MouseEvent):void
        {
            //- Close
            if (e.target == closeOptions)
            {
                removePopup();
                return;
            }
        }
    }
}
