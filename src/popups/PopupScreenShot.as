/**
 * @author Jonathan (Velocity)
 */

package popups
{
    import classes.Box;
    import classes.BoxButton;
    import classes.Text;
    import com.flashfla.utils.SystemUtil;
    import com.flashfla.utils.TimeUtil;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.system.System;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import menu.MenuPanel;
    import classes.Language;

    public class PopupScreenShot extends MenuPanel
    {
        private var box:Box;
        private var directCopyBox:BoxButton;
        private var deleteCopyBox:BoxButton;
        private var closeBox:Box;
        private var results:Object;
        private var textFormat:TextFormat = new TextFormat(Language.BASE_FONT_CJK, 14, 0xFFFFFF, true);

        public function PopupScreenShot(myParent:MenuPanel, results:Object)
        {
            super(myParent);
            this.results = results;
        }

        override public function stageAdd():void
        {
            box = new Box(Main.GAME_WIDTH - 20, 50, false, false);
            box.x = 9;
            box.y = Main.GAME_HEIGHT - 49;
            box.color = 0x1187AB;
            box.activeAlpha = 1;
            box.normalAlpha = 0.8;
            this.addChild(box);

            if (results.error == null)
            {
                trace(results.upload.links.delete_page);
                trace(results.upload.links.original);

                var directLink:Text = new Text("Direct Link");
                directLink.x = 4;
                directLink.y = 2;
                box.addChild(directLink);

                var directLinkBox:Box = new Box(210, 20, false, false);
                directLinkBox.x = 7;
                directLinkBox.y = 20;
                box.addChild(directLinkBox);

                var directLinkText:TextField = new TextField();
                directLinkText.y = -1;
                directLinkText.width = directLinkBox.width;
                directLinkText.embedFonts = true;
                directLinkText.antiAliasType = AntiAliasType.ADVANCED;
                directLinkText.defaultTextFormat = textFormat;
                directLinkText.text = results.upload.links.original;
                directLinkBox.addChild(directLinkText);

                directCopyBox = new BoxButton(41, 20, "COPY");
                directCopyBox.x = directLinkBox.x + directLinkBox.width + 5;
                directCopyBox.y = directLinkBox.y;
                directCopyBox.buttonMode = true;
                directCopyBox.mouseChildren = false;
                directCopyBox.addEventListener(MouseEvent.CLICK, clickHandler);
                box.addChild(directCopyBox);

                var deleteLink:Text = new Text("Deletion Link");
                deleteLink.x = 295;
                deleteLink.y = 2;
                box.addChild(deleteLink);

                var deleteLinkBox:Box = new Box(320, 20, false, false);
                deleteLinkBox.x = 298;
                deleteLinkBox.y = 20;
                box.addChild(deleteLinkBox);

                var deleteLinkText:TextField = new TextField();
                deleteLinkText.y = -1;
                deleteLinkText.width = deleteLinkBox.width;
                deleteLinkText.embedFonts = true;
                deleteLinkText.antiAliasType = AntiAliasType.ADVANCED;
                deleteLinkText.defaultTextFormat = textFormat;
                deleteLinkText.text = results.upload.links.delete_page;
                deleteLinkBox.addChild(deleteLinkText);

                deleteCopyBox = new BoxButton(41, 20, "COPY");
                deleteCopyBox.x = deleteLinkBox.x + deleteLinkBox.width + 5;
                deleteCopyBox.y = deleteLinkBox.y;
                deleteCopyBox.addEventListener(MouseEvent.CLICK, clickHandler);
                box.addChild(deleteCopyBox);
            }

            closeBox = new Box(72, 35, true, false);
            closeBox.x = 682;
            closeBox.y = 7;
            closeBox.buttonMode = true;
            closeBox.mouseChildren = false;
            closeBox.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(closeBox);

            var closeText:Text = new Text("CLOSE");
            closeText.y = 7;
            closeText.width = closeBox.width;
            closeText.align = Text.CENTER;
            closeBox.addChild(closeText);
        }

        override public function stageRemove():void
        {
            if (results.error == null)
            {
                directCopyBox.removeEventListener(MouseEvent.CLICK, clickHandler);
                deleteCopyBox.removeEventListener(MouseEvent.CLICK, clickHandler);
                directCopyBox.dispose();
                deleteCopyBox.dispose();
                box.removeChild(directCopyBox);
                box.removeChild(deleteCopyBox);
            }

            closeBox.removeEventListener(MouseEvent.CLICK, clickHandler);
            closeBox.dispose();
            box.dispose();
            box.removeChild(closeBox);
            this.removeChild(box);
            box = null;
        }

        private function clickHandler(e:Event):void
        {
            if (e.target == directCopyBox)
            {
                SystemUtil.setClipboard(results.upload.links.original);
                (my_Parent as Main).addAlert("Copied to Clipboard", 75);
            }
            else if (e.target == deleteCopyBox)
            {
                SystemUtil.setClipboard(results.upload.links.delete_page);
                (my_Parent as Main).addAlert("Copied to Clipboard", 75);
            }
            else if (e.target == closeBox)
            {
                if (this.parent.contains(this))
                {
                    //removePopup();
                    this.parent.removeChild(this);
                }
            }
        }

    }
}
