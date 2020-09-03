package popups
{
    import assets.GameBackgroundColor;
    import classes.Box;
    import classes.BoxButton;
    import classes.Language;
    import com.greensock.TweenLite;
    import com.greensock.easing.Back;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import menu.MenuPanel;

    public class PopupTokenUnlock extends MenuPanel
    {
        private var _lang:Language = Language.instance;
        private var _gvars:GlobalVariables = GlobalVariables.instance;

        //- Background
        private var box:Box;
        private var bmp:Bitmap;

        private var tType:String;
        private var tID:String;
        private var uText:String;
        private var tObject:Object;

        private var closeOptions:BoxButton;

        public function PopupTokenUnlock(myParent:MenuPanel, tokenType:String, tokenID:String, unlockText:String, tokenName:String = null, tokenMessage:String = null)
        {
            super(myParent);
            tType = tokenType;
            tID = tokenID;
            uText = unlockText;
            tObject = _gvars.TOKENS_TYPE[tType][tID];
            if (!tObject)
                tObject = {};
            if (tokenName)
                tObject["name"] = tokenName;
            if (tokenMessage)
                tObject["info"] = tokenMessage;
        }

        override public function stageAdd():void
        {
            var bmd:BitmapData = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);
            bmd = null;
            bmp.alpha = 0;
            this.addChild(bmp);

            var bh:Sprite = new Sprite();
            bh.x = Main.GAME_WIDTH / 2;
            bh.y = Main.GAME_HEIGHT / 2;
            bh.scaleX = 0.5;
            bh.scaleY = 0.5;
            bh.alpha = 0;
            this.addChild(bh);

            var bgbox:Box = new Box(Main.GAME_WIDTH / 2, Main.GAME_HEIGHT - 40, false, false);
            bgbox.x = -((Main.GAME_WIDTH / 2) / 2);
            bgbox.y = -((Main.GAME_HEIGHT - 40) / 2);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;
            bh.addChild(bgbox);

            box = new Box(Main.GAME_WIDTH / 2, Main.GAME_HEIGHT - 40, false, false);
            box.x = -((Main.GAME_WIDTH / 2) / 2);
            box.y = -((Main.GAME_HEIGHT - 40) / 2);
            box.activeAlpha = 0.4;
            bh.addChild(box);

            var th:Sprite = new Sprite();
            var textbmd:BitmapData = new BitmapData(box.width, box.height, true, 0x000000);

            var messageDisplay:TextField;
            var yOff:Number = 0;

            if (tObject)
            {
                //- Token Name
                messageDisplay = new TextField();
                messageDisplay.x = 10;
                messageDisplay.y = 0;
                messageDisplay.width = box.width - 20;
                messageDisplay.selectable = false;
                messageDisplay.embedFonts = true;
                messageDisplay.antiAliasType = AntiAliasType.ADVANCED;
                messageDisplay.width = box.width - 20;
                messageDisplay.autoSize = TextFieldAutoSize.CENTER;
                messageDisplay.defaultTextFormat = Constant.TEXT_FORMAT_CENTER;
                messageDisplay.htmlText = "<FONT SIZE=\"20\">" + _lang.string("popup_token_unlock") + "\n" + tObject.name + "</FONT>";
                th.addChild(messageDisplay);
                yOff = messageDisplay.y + messageDisplay.height;

                //- Token Message
                messageDisplay = new TextField();
                messageDisplay.x = 10;
                messageDisplay.y = yOff + 5;
                messageDisplay.width = box.width - 20;
                messageDisplay.selectable = false;
                messageDisplay.embedFonts = true;
                messageDisplay.antiAliasType = AntiAliasType.ADVANCED;
                messageDisplay.width = box.width - 20;
                messageDisplay.wordWrap = true;
                messageDisplay.defaultTextFormat = Constant.TEXT_FORMAT_CENTER;
                messageDisplay.autoSize = TextFieldAutoSize.CENTER;
                messageDisplay.htmlText = tObject.info.replace(/\r\n/gi, "\n");
                th.addChild(messageDisplay);
                yOff = messageDisplay.y + messageDisplay.height + 15;
            }

            // Divider
            th.graphics.lineStyle(1, 0xffffff);
            th.graphics.moveTo(10, yOff);
            th.graphics.lineTo(box.width - 20, yOff);

            yOff += 15;

            //- Avatar
            var userAvatar:DisplayObject = _gvars.activeUser.avatar;
            if (userAvatar.height > 0 && userAvatar.width > 0)
            {
                var avatarbmd:BitmapData = new BitmapData(userAvatar.width, userAvatar.height, true, 0x000000);
                avatarbmd.draw(userAvatar);
                var avatarbmp:Bitmap = new Bitmap(avatarbmd);
                avatarbmp.x = (box.width / 2) - (userAvatar.width / 2);
                avatarbmp.y = yOff + 15;
                yOff += userAvatar.height + 15;
                th.addChild(avatarbmp);
            }

            //- Username
            messageDisplay = new TextField();
            messageDisplay.x = 10;
            messageDisplay.y = yOff;
            messageDisplay.width = box.width - 20;
            messageDisplay.selectable = false;
            messageDisplay.embedFonts = true;
            messageDisplay.antiAliasType = AntiAliasType.ADVANCED;
            messageDisplay.width = box.width - 20;
            messageDisplay.wordWrap = true;
            messageDisplay.defaultTextFormat = Constant.TEXT_FORMAT_CENTER;
            messageDisplay.autoSize = TextFieldAutoSize.CENTER;
            messageDisplay.text = _gvars.activeUser.name;
            th.addChild(messageDisplay);

            yOff += messageDisplay.height + 15;

            // Divider
            th.graphics.lineStyle(1, 0xffffff);
            th.graphics.moveTo(10, yOff);
            th.graphics.lineTo(box.width - 20, yOff);

            yOff += 15;

            //- Unlock Message
            messageDisplay = new TextField();
            messageDisplay.x = 10;
            messageDisplay.y = yOff + 5;
            messageDisplay.width = box.width - 20;
            messageDisplay.selectable = false;
            messageDisplay.embedFonts = true;
            messageDisplay.antiAliasType = AntiAliasType.ADVANCED;
            messageDisplay.width = box.width - 20;
            messageDisplay.wordWrap = true;
            messageDisplay.defaultTextFormat = Constant.TEXT_FORMAT_CENTER;
            messageDisplay.autoSize = TextFieldAutoSize.CENTER;
            messageDisplay.text = uText;
            th.addChild(messageDisplay);

            // Draw Text
            textbmd.draw(th);
            box.addChild(new Bitmap(textbmd));

            //- Close
            closeOptions = new BoxButton(box.width - 30, 27, _lang.string("popup_token_close"));
            closeOptions.x = 15;
            closeOptions.y = box.height - 42;
            closeOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(closeOptions);

            TweenLite.to(bmp, 1, {alpha: 1});
            TweenLite.to(bh, 1, {alpha: 1, scaleX: 1, scaleY: 1, ease: Back.easeOut});
        }

        override public function stageRemove():void
        {
            box.dispose();
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
