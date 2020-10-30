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
    import flash.text.AntiAliasType;
    import flash.text.StyleSheet;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import menu.MenuPanel;

    public class PopupHelp extends MenuPanel
    {
        private var _lang:Language = Language.instance;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var titleDisplay:Text;
        private var messageDisplay:TextField;

        private var closeOptions:BoxButton;

        public function PopupHelp(myParent:MenuPanel)
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

            var bgbox:Box = new Box(this, 20, 20, false, false);
            bgbox.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;

            box = new Box(this, 20, 20, false, false);
            box.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            box.activeAlpha = 0.4;
            box.mouseChildren = true;
            box.mouseEnabled = true;

            titleDisplay = new Text(box, 5, 5, _lang.string("popup_help_title"), 20);
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;

            //- Message
            var style:StyleSheet = new StyleSheet();
            style.setStyle("BODY", {color: "#FFFFFF", fontSize: 14});
            style.setStyle("A", {textDecoration: "underline", fontWeight: "bold"});
            messageDisplay = new TextField();
            messageDisplay.styleSheet = style;
            messageDisplay.x = 5;
            messageDisplay.y = 30;
            messageDisplay.selectable = false;
            messageDisplay.embedFonts = true;
            messageDisplay.antiAliasType = AntiAliasType.ADVANCED;
            messageDisplay.multiline = true;
            messageDisplay.width = box.width - 10;
            messageDisplay.wordWrap = true;
            messageDisplay.autoSize = TextFieldAutoSize.LEFT;
            messageDisplay.htmlText = "<BODY>" + _lang.string("popup_help_text") + "</BODY>";

            box.addChild(messageDisplay);

            //- Close
            closeOptions = new BoxButton(box, box.width - 94.5, box.height - 42, 79.5, 27, _lang.string("menu_close"), 12, clickHandler);
        }

        override public function stageRemove():void
        {
            closeOptions.dispose();

            box.dispose();
            titleDisplay.dispose();
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
