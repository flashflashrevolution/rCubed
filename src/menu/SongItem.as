package menu
{
    import classes.Text;
    import flash.display.Sprite;
    import flash.display.GradientType;
    import flash.geom.Matrix;
    import flash.text.StyleSheet;
    import flash.events.MouseEvent;
    import com.flashfla.utils.sprintf;
    import com.flashfla.utils.NumberUtil;
    import classes.Language;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.AntiAliasType;
    import flash.text.TextFieldAutoSize;
    import flash.ui.ContextMenu;
    import flash.events.Event;

    public class SongItem extends Sprite
    {
        /** Marks the Button as in-use to avoid removal in song selector. */
        //public var garbageSweep:Boolean = false;

        /** Calculated y position in the scroll pane. */
        //public var fixed_y:Number = 0;

        public var index:int = 0;

        // Text
        private var _lblSongDifficulty:Text;
        private var _lblSongName:Text;
        private var _lblSongFlag:Text;

        private var _lblMessageText:TextField;

        // Display
        private var _width:Number = 400;
        private var _height:Number = 27;
        private var _highlight:Boolean = false;
        private var _active:Boolean = false;

        // Song Data
        private var _songData:Object;
        private var _level:int = 0;
        public var isLocked:Boolean = false;

        public function SongItem()
        {
            //- Set Button Mode
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            //- Events
            this.addEventListener(MouseEvent.ROLL_OVER, e_onHover);
        }

        public function draw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(1, 0xFFFFFF, (highlight ? 0.8 : 0.55));
            this.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], (highlight ? [0.35, 0.1225] : [0.2, 0.04]), [0, 255], Constant.GRADIENT_MATRIX);
            this.graphics.drawRect(0, 0, width - 1, height - 1);
            this.graphics.endFill();

            // Difficulty Divider
            if (!isLocked)
            {
                this.graphics.moveTo(32, 0);
                this.graphics.lineTo(32, height);
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Events
        private function e_onHover(e:MouseEvent):void
        {
            _highlight = true;
            draw();
            this.addEventListener(MouseEvent.ROLL_OUT, e_onHoverOut);
        }

        private function e_onHoverOut(e:MouseEvent):void
        {
            _highlight = false;
            draw();
            this.removeEventListener(MouseEvent.ROLL_OUT, e_onHoverOut);
        }

        /**
         * This is called by MenuSongSelection
         * @param e
         * @return Boolean | If the mouse event was captured and used to open the shop.
         */
        public function e_onClick(e:Event = null):Boolean
        {
            if (isLocked)
            {
                if (songData["access"] == GlobalVariables.SONG_ACCESS_PURCHASED)
                {
                    navigateToURL(new URLRequest(Constant.SHOP_URL), "_blank");
                }
                return true;
            }
            return false;
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        public function setData(song:Object, rank:Object):void
        {
            _songData = song;
            _level = song.level;
            isLocked = !(!song["access"] || song["access"] == GlobalVariables.SONG_ACCESS_PLAYABLE);

            // Song Name
            var songname:String = song["name"];
            if (!song["engine"] && song["genre"] == Constant.LEGACY_GENRE)
                songname = '<font color="#004587">[L]</font> ' + songname;
            _lblSongName = new Text(songname, 14);
            this.addChild(_lblSongName);

            // Locked Song Item, basically anything but playable songs.
            if (isLocked)
            {
                this.mouseChildren = true;

                var _message:String = getSongLockText();

                _lblMessageText = new TextField();
                _lblMessageText.styleSheet = Constant.STYLESHEET;
                _lblMessageText.x = 5;
                _lblMessageText.y = 20;
                _lblMessageText.selectable = false;
                _lblMessageText.embedFonts = true;
                _lblMessageText.antiAliasType = AntiAliasType.ADVANCED;
                _lblMessageText.multiline = true;
                _lblMessageText.width = 395;
                _lblMessageText.wordWrap = true;
                _lblMessageText.autoSize = TextFieldAutoSize.LEFT;
                _lblMessageText.htmlText = "<font face=\"" + Language.UNI_FONT_NAME + "\" color=\"#FFFFFF\" size=\"10\"><b>" + _message.split("\r").join("") + "</b></font>";
                this.addChild(_lblMessageText);

                _lblSongName.x = 5;
                _lblSongName.setAreaParams(390, 27);

                // Set SongItem Height
                _height = (29 + (_lblMessageText.numLines * 13));
            }

            // Playable Song
            else
            {
                this.mouseChildren = false;

                // Song Name
                _lblSongName.x = 36;

                // Song Difficulty
                _lblSongDifficulty = new Text(song["difficulty"], 14);
                _lblSongDifficulty.x = 1;
                _lblSongDifficulty.setAreaParams(30, 27, Text.CENTER);
                this.addChild(_lblSongDifficulty);

                // Song Flag
                var FLAG_TEXT:String = GlobalVariables.getSongIcon(_songData, rank);
                if (FLAG_TEXT != "")
                {
                    _lblSongFlag = new Text(GlobalVariables.getSongIcon(_songData, rank), 14);
                    _lblSongFlag.x = 296;
                    _lblSongFlag.setAreaParams(100, 27, Text.RIGHT);
                    this.addChild(_lblSongFlag);

                    // Adjust Song Name to not overlap song flag.
                    _lblSongName.setAreaParams(347 - _lblSongFlag.textfield.textWidth, 27);
                }
                else
                {
                    _lblSongName.setAreaParams(353, 27);
                }
                _height = 27;
            }

            draw();
        }

        public function setContextMenu(val:ContextMenu):void
        {
            if (!isLocked)
            {
                this.contextMenu = val;
            }
        }

        public function getSongLockText():String
        {
            // Get them here to reduce instance loading, as only locked songs call this.
            var _gvars:GlobalVariables = GlobalVariables.instance;
            var _lang:Language = Language.instance;

            switch (songData["access"])
            {
                case GlobalVariables.SONG_ACCESS_CREDITS:
                    return sprintf(_lang.string("song_selection_banned_credits"), {more_needed: NumberUtil.numberFormat(songData.credits - _gvars.activeUser.credits), user_credits: NumberUtil.numberFormat(_gvars.activeUser.credits), song_price: NumberUtil.numberFormat(songData.credits)});
                case GlobalVariables.SONG_ACCESS_PURCHASED:
                    return sprintf(_lang.string("song_selection_banned_purchased"), {song_price: NumberUtil.numberFormat(songData.price)});
                case GlobalVariables.SONG_ACCESS_VETERAN:
                    return _lang.string("song_selection_banned_veteran");
                case GlobalVariables.SONG_ACCESS_TOKEN:
                    return _gvars.TOKENS[songData.level].info;
                case GlobalVariables.SONG_ACCESS_BANNED:
                    return _lang.string("song_selection_banned_invalid");
            }
            return "Unknown Lock Reason (" + songData["access"] + ") - This shouldn't appear, message Velocity";
        }

        public function get songData():Object
        {
            return _songData;
        }

        public function get level():int
        {
            return _level;
        }

        public function get highlight():Boolean
        {
            return _highlight || _active;
        }

        public function set active(val:Boolean):void
        {
            _active = val;
            draw();
        }

        public function get active():Boolean
        {
            return _active;
        }

        override public function get width():Number
        {
            return _width;
        }

        override public function get height():Number
        {
            return _height;
        }
    }
}
