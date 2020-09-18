/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.Box;
    import classes.Language;
    import classes.Playlist;
    import classes.Text;
    import com.greensock.TweenLite;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.filters.ColorMatrixFilter;
    import flash.geom.Point;
    import flash.text.AntiAliasType;
    import flash.text.StyleSheet;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;

    public class TokenItem extends Sprite
    {
        public var index:Number;
        public var token_info:Object;
        public var token_image:Sprite;
        public var token_levels:Array;

        private var _lang:Language = Language.instance;

        public function TokenItem(token_data:Object):void
        {
            this.token_info = token_data;
            this.buttonMode = true;
            this.mouseChildren = false;
            this.useHandCursor = true;

            //- Message
            var messageString:String = token_info['info'].replace(/\r\n/gi, "\n");

            // Token Levels
            token_levels = (token_info['sources'] as String).split(",");

            if (!(token_levels is Array) || token_levels.length == 0)
                token_levels = [0];

            //
            if (token_levels.length > 1)
            {
                if (token_levels[0] == 0)
                    messageString += "\r" + _lang.string("menu_tokens_unknown_unlock_condition");
                else
                {
                    messageString += "\r\r" + _lang.string("menu_tokens_unlock_by_playing");
                    for each (var item:int in token_levels)
                    {
                        messageString += "\r&gt; " + Playlist.instanceCanon.playList[item]['name'];
                    }
                }
            }

            var style:StyleSheet = new StyleSheet();
            style.setStyle("A", {textDecoration: "underline", fontWeight: "bold"});
            var messageText:TextField = new TextField();
            messageText.styleSheet = style;
            messageText.x = 5;
            messageText.y = 20;
            messageText.selectable = false;
            messageText.embedFonts = true;
            messageText.antiAliasType = AntiAliasType.ADVANCED;
            messageText.multiline = true;
            messageText.width = 510;
            messageText.wordWrap = true;
            messageText.autoSize = TextFieldAutoSize.LEFT;
            //messageText.border = true;
            //messageText.borderColor = 0xffffff;
            messageText.htmlText = "<font face=\"" + Language.UNI_FONT_NAME + "\" color=\"#FFFFFF\" size=\"12\"><b>" + messageString + "</b></font>";

            //- Make Display
            var box:Box = new Box(577, Math.max(54, (32 + (messageText.numLines * 17))), false);

            //- Name
            var nameText:Text = new Text(token_info["name"], 14);
            nameText.x = 5;
            nameText.setAreaParams(350, 27);
            box.addChild(nameText);
            box.addChild(messageText);

            this.addChild(box);
        }

        public function addTokenImage(image:Bitmap, doFade:Boolean = true):void
        {
            var bmd:BitmapData = token_info['unlock'] ? image.bitmapData : image.bitmapData.clone();

            token_image = new Sprite();
            if (token_info['unlock'] == 0)
            {
                const rc:Number = 0.1, gc:Number = 0.1, bc:Number = 0.1;
                bmd.applyFilter(bmd, bmd.rect, new Point(), new ColorMatrixFilter([rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, rc, gc, bc, 0, 0, 0, 0, 0, 1, 0]));
            }

            token_image.graphics.beginBitmapFill(bmd, null, false);
            token_image.graphics.drawRect(0, 0, bmd.width, bmd.height);
            token_image.graphics.endFill();
            token_image.x = 532;
            token_image.y = 5;
            addChild(token_image);

            if (doFade)
            {
                token_image.alpha = 0;
                TweenLite.to(token_image, 1.25, {"alpha": token_info['unlock'] ? 1 : 0.7});
            }
            else
                token_image.alpha = token_info['unlock'] ? 1 : 0.7;
        }
    }
}
