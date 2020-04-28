/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.Box;
    import classes.Text;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.text.AntiAliasType;
    import flash.text.StyleSheet;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import classes.Language;

    public class SongItemLocked extends Sprite
    {
        private var _active:Boolean = false;
        private var _song:Array;
        private var _message:String;
        private var _url:String;
        private var _urlRequest:URLRequest;

        //- Song Details
        public var box:Box;

        private var nameText:Text;
        private var messageText:TextField;

        public function SongItemLocked(sO:Array, lM:String, uURL:String = ""):void
        {
            this._song = sO;
            this._message = lM;
            this._url = uURL;

            buildBox();

            //- Set Button Mode
            if (_url != "")
            {
                _urlRequest = new URLRequest(_url);
                this.mouseChildren = false;
                this.useHandCursor = true;
                this.buttonMode = true;
                this.addEventListener(MouseEvent.CLICK, thisClicked, false, 0, true);
                this.addEventListener(MouseEvent.ROLL_OVER, boxOver, false, 0, true);
                this.addEventListener(MouseEvent.ROLL_OUT, boxOut, false, 0, true);
            }
        }

        public function dispose():void
        {
            if (_url != "")
            {
                this.removeEventListener(MouseEvent.CLICK, thisClicked);
                this.removeEventListener(MouseEvent.ROLL_OVER, boxOver);
                this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);
            }

            //- Remove is already existed.
            if (box != null)
            {
                box.removeChild(nameText);
                nameText = null;
                box.dispose();
                this.removeChild(box);
                box = null;
            }
        }

        private function boxOver(e:MouseEvent):void
        {
            box.boxOver();
        }

        private function boxOut(e:MouseEvent):void
        {
            box.boxOut();
        }

        private function thisClicked(e:Event):void
        {
            navigateToURL(_urlRequest, "_blank");
        }

        public function set active(val:Boolean):void
        {
            _active = val;
            buildBox();
        }

        private function buildBox():void
        {
            //- Remove is already existed.
            if (box != null)
            {
                this.removeChild(box);
                box = null;
            }
            //- Message
            var style:StyleSheet = new StyleSheet();
            style.setStyle("A", {textDecoration: "underline", fontWeight: "bold"});
            messageText = new TextField();
            messageText.styleSheet = style;
            messageText.x = 5;
            messageText.y = 20;
            messageText.selectable = false;
            messageText.embedFonts = true;
            messageText.antiAliasType = AntiAliasType.ADVANCED;
            messageText.multiline = true;
            messageText.width = 395;
            messageText.wordWrap = true;
            messageText.autoSize = TextFieldAutoSize.LEFT;
            messageText.htmlText = "<font face=\"" + Language.UNI_FONT_NAME + "\" color=\"#FFFFFF\" size=\"10\"><b>" + _message.split("\r").join("") + "</b></font>";

            //- Make Display
            box = new Box(400, (29 + (messageText.numLines * 13)), false);

            //- Name
            nameText = new Text(_song["name"], 13);
            nameText.x = 5;
            nameText.setAreaParams(390, 27);
            nameText.mouseEnabled = false;
            box.addChild(nameText);

            //- Add Text
            this.addChild(box);
            this.addChild(messageText);
        }
    }
}
