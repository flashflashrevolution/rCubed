/**
 * @author Jonathan (Velocity)
 */

package popups
{
    import classes.Box;
    import classes.BoxButton;
    import classes.Language;
    import com.greensock.TweenLite;
    import com.greensock.easing.BackIn;
    import com.greensock.easing.BackOut;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import menu.MenuPanel;

    public class PopupSkillRankUpdate extends MenuPanel
    {
        private var _lang:Language = Language.instance;

        private var box:Box;
        private var closeBox:BoxButton;
        private var results:Object;

        public function PopupSkillRankUpdate(myParent:MenuPanel, results:Object)
        {
            super(myParent);
            this.results = results;
        }

        override public function stageAdd():void
        {
            var renderPlane:Sprite = new Sprite();
            var yOffset:Number = 5;
            yOffset += renderMessages(renderPlane, yOffset, results["positive"], 0x00ff00);
            yOffset += renderMessages(renderPlane, yOffset, results["negative"], 0xff0000);
            yOffset += renderMessages(renderPlane, yOffset, results["neutral"], 0x0000ff);

            box = new Box(this, 9, Main.GAME_HEIGHT + 2, false, false);
            box.setSize(Main.GAME_WIDTH - 20, renderPlane.height + 50);
            box.color = 0x1187AB;
            box.activeAlpha = 1;
            box.normalAlpha = 0.8;
            box.addChild(renderPlane);

            closeBox = new BoxButton(box, 682, 7, 72, 35, _lang.string("menu_close"), 12, clickHandler);
            closeBox.buttonMode = true;
            closeBox.mouseChildren = false;

            TweenLite.to(box, 0.5, {"y": Main.GAME_HEIGHT - (box.height - 40), "ease": BackOut.ease});
        }

        override public function stageRemove():void
        {
            closeBox.dispose();

            box.dispose();
            box = null;
        }

        private function clickHandler(e:Event):void
        {
            if (e.target == closeBox)
            {
                if (this.parent.contains(this))
                {
                    TweenLite.to(box, 0.5, {"y": Main.GAME_HEIGHT + 2, "ease": BackIn.ease, "onCompleteParams": [this], "onComplete": function(trg:DisplayObjectContainer):void
                    {
                        trg.parent.removeChild(trg);
                    }});
                }
            }
        }

        private function renderMessages(target:Sprite, offetY:Number, messages:Array, color:uint = 0xFFFFFF):Number
        {
            if (messages.length <= 0)
                return 0;

            var tf:TextField = new TextField();
            tf = new TextField();
            tf.x = 10;
            tf.y = offetY + 5;
            tf.height = 30;
            tf.width = Main.GAME_WIDTH - 40;
            tf.wordWrap = true;
            tf.multiline = true;
            tf.embedFonts = true;
            tf.selectable = false;
            tf.autoSize = "left";
            tf.antiAliasType = AntiAliasType.ADVANCED;
            tf.defaultTextFormat = Constant.TEXT_FORMAT_12;
            tf.htmlText = messages.join("\n");
            target.addChild(tf);

            target.graphics.lineStyle(1, 0xffffff, 0);
            target.graphics.beginFill(color, 0.25);
            target.graphics.drawRoundRect(5, offetY, tf.width + 10, tf.height + 10, 15, 15);
            target.graphics.endFill();

            return tf.height + 15;
        }
    }
}
