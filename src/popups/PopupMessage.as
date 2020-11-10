package popups
{
    import assets.GameBackgroundColor;
    import classes.Language;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.Text;
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

            var bgbox:Box = new Box(this, 20, 20, false, false);
            bgbox.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;

            box = new Box(this, 20, 20, false, false);
            box.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            box.activeAlpha = 0.4;

            titleDisplay = new Text(box, 5, 5, displayTitle, 20);
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;

            messageDisplay = new Text(box, 5, 0, dislayText, 14);
            messageDisplay.height = box.height;
            messageDisplay.width = box.width - 10;
            messageDisplay.align = Text.CENTER;

            //- Close
            closeOptions = new BoxButton(box, box.width - 94.5, box.height - 42, 79.5, 27, _lang.string("menu_close"), 12, clickHandler);
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
