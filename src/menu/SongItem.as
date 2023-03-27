package menu
{
    import classes.Language;
    import classes.ui.MouseTooltip;
    import classes.ui.Text;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.GradientType;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.Point;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.ui.ContextMenu;
    import flash.utils.Timer;
    import sql.SQLSongUserInfo;
    import classes.SongInfo;

    public class SongItem extends Sprite
    {
        private static var _gvars:GlobalVariables = GlobalVariables.instance;
        private static var _lang:Language = Language.instance;

        private static const HOVER_POINT_GLOBAL:Point = new Point();
        private static const DISABLED_COLORS:Array = [0xFF0000, 0xFF0000];
        private static const GRADIENT_COLORS:Array = [0xFFFFFF, 0xFFFFFF];
        private static const GRADIENT_ALPHA_HIGHLIGHT:Array = [0.35, 0.1225];
        private static const GRADIENT_ALPHA:Array = [0.2, 0.04];
        private static const GRADIENT_RATIO:Array = [0, 255];

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
        private var _songInfo:SongInfo;
        private var _songUserInfo:SQLSongUserInfo;
        private var _level:int = 0;
        public var isLocked:Boolean = false;
        public var isFavorite:Boolean = false;

        // Hover Data
        private var _hoverEnabled:Boolean = true;
        private var _hoverTimer:Timer;
        private var _hoverSprite:MouseTooltip;
        private var _hoverTick:int = 0;
        private var _hoverPoint:Point;

        public function SongItem()
        {
            //- Set Button Mode
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            //- Events
            this.addEventListener(MouseEvent.ROLL_OVER, e_onHover, false, 0, true);
        }

        public function draw():void
        {
            const ALPHAS:Array = (highlight ? GRADIENT_ALPHA_HIGHLIGHT : GRADIENT_ALPHA);
            const COLORS:Array = (songInfo.is_disabled ? DISABLED_COLORS : GRADIENT_COLORS);

            this.graphics.clear();
            this.graphics.lineStyle(1, 0xFFFFFF, (highlight ? 0.8 : 0.55));
            this.graphics.beginGradientFill(GradientType.LINEAR, COLORS, ALPHAS, GRADIENT_RATIO, Constant.GRADIENT_MATRIX);
            this.graphics.drawRect(0, 0, width - 1, height - 1);
            this.graphics.endFill();

            // Difficulty Divider
            if (!isLocked)
            {
                this.graphics.moveTo(32, 0);
                this.graphics.lineTo(32, height - 1);

                if (isFavorite)
                {
                    this.graphics.lineStyle(0, 0, 0);
                    this.graphics.beginFill(0xf7b9e4, 1);
                    this.graphics.moveTo(1, 1);
                    this.graphics.lineTo(8, 1);
                    this.graphics.lineTo(1, 8);
                    this.graphics.lineTo(1, 1);
                    this.graphics.endFill();
                }
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Events
        private function e_onHover(e:MouseEvent):void
        {
            _highlight = true;
            draw();
            showHoverMessage(true);
            this.addEventListener(MouseEvent.ROLL_OUT, e_onHoverOut);
        }

        private function e_onHoverOut(e:MouseEvent):void
        {
            _highlight = false;
            draw();
            showHoverMessage(false);
            this.removeEventListener(MouseEvent.ROLL_OUT, e_onHoverOut);
        }

        /**
         * Displays or hides the note hover for the song item.
         * @param enabled
         */
        public function showHoverMessage(enabled:Boolean):void
        {
            // `enabled` accounts for both `active` and `highlight`.
            if (enabled)
            {
                // Have a song note, show note.
                if (highlight && (_hoverEnabled && (_songUserInfo != null && _songUserInfo.notes.length > 0)))
                {
                    if (!_hoverTimer)
                        _hoverTimer = new Timer(500, 1);

                    if (!_hoverTimer.running && (_hoverSprite == null || _hoverSprite.parent == null))
                    {
                        _hoverTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
                        _hoverTimer.start();
                    }
                }
            }
            else
            {
                if (!highlight)
                {
                    if (_hoverTimer && _hoverTimer.running)
                    {
                        _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
                        _hoverTimer.stop();
                    }
                    if (_hoverSprite && _hoverSprite.parent)
                    {
                        this.removeEventListener(Event.ENTER_FRAME, e_positionHoverSprite);
                        _hoverSprite.parent.removeChild(_hoverSprite);
                    }
                }
            }
        }

        /**
         * TimerEvent.TIMER_COMPLETE For the hover / active timer.
         * Displays the song note sprite when the timer completes.
         * @param e
         */
        private function e_hoverTimerComplete(e:Event = null):void
        {
            _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);

            if (this.parent != null)
            {
                if (_hoverSprite == null)
                    _hoverSprite = new MouseTooltip("", _width - 1);

                update();
                positionHoverSprite();
                this.parent.addChild(_hoverSprite);
                _hoverSprite.visible = true; // Adding a child to the ScrollPane makes it invisible until a scroll update is sent.
                this.addEventListener(Event.ENTER_FRAME, e_positionHoverSprite);
            }
        }

        /**
         * Event.ENTER_FRAME For note position on stage.
         * This updates the note position every 5 frames so the message
         * is supposedly visible when scrolled to high or low.
         * @param e
         */
        private function e_positionHoverSprite(e:Event):void
        {
            // Only check 12 times per second instead of 60.
            if (++_hoverTick > 5)
            {
                if (_hoverSprite != null && _hoverSprite.parent != null)
                {
                    positionHoverSprite();
                    _hoverTick = 0;
                }
                else
                {
                    this.removeEventListener(Event.ENTER_FRAME, e_positionHoverSprite);
                }
            }
        }

        /**
         * Updates the Notes hover sprite to be above or below the item
         * depending on the position on screen.
         */
        private function positionHoverSprite():void
        {
            if (_hoverSprite)
            {
                _hoverPoint = this.localToGlobal(HOVER_POINT_GLOBAL);

                if (_hoverPoint.y > Main.GAME_HEIGHT / 2)
                    _hoverSprite.y = this.y - _hoverSprite.height - 2;
                else
                    _hoverSprite.y = this.y + _height + 2;

                _hoverSprite.x = this.x;
            }
        }

        /**
         * Updates the note text, or displays the new note if previously empty.
         * This is called when closing PopupSongNotes.
         */
        public function updateOrShow():void
        {
            // Check for Changes
            if (_songUserInfo == null)
                _songUserInfo = SQLQueries.getSongUserInfo(songInfo);

            // Update Favorite
            isFavorite = (_songUserInfo != null && _songUserInfo.song_favorite);
            _lblSongDifficulty.text = getDifficultyText();
            draw();

            // Update Note
            if (_hoverSprite != null)
                update();
            else
                showHoverMessage(true);
        }

        /**
         * Update the note sprite message.
         */
        public function update():void
        {
            if (_hoverSprite != null)
            {
                _hoverSprite.message = "<font face=\"" + Fonts.BASE_FONT_CJK + "\" >" + _songUserInfo.notes + "</font>";
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        public function setData(songInfo:SongInfo, rank:Object):void
        {
            _songInfo = songInfo;
            _level = songInfo.level;
            isLocked = !(!songInfo.access || songInfo.access == GlobalVariables.SONG_ACCESS_PLAYABLE);

            // Song Details
            _songUserInfo = SQLQueries.getSongUserInfo(songInfo);
            isFavorite = (_songUserInfo != null && _songUserInfo.song_favorite);

            // Song Name
            var songname:String = songInfo.name;

            if (songInfo.is_explicit)
                songname = '<font color="#e89200">[E]</font> ' + songname;
            if (songInfo.is_legacy)
                songname = '<font color="#004587">[L]</font> ' + songname;

            _lblSongName = new Text(this, 0, 0, songname || "", 14);

            // Locked Song Item, basically anything but playable songs.
            if (isLocked)
            {
                this.mouseChildren = (songInfo.access == GlobalVariables.SONG_ACCESS_TOKEN);

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
                _lblMessageText.htmlText = "<font face=\"" + Fonts.BASE_FONT_CJK + "\" color=\"#FFFFFF\" size=\"10\"><b>" + _message + "</b></font>";
                this.addChild(_lblMessageText);

                _lblSongName.x = 5;
                _lblSongName.setAreaParams(390, 27);

                // Set SongItem Height
                _height = (29 + (_lblMessageText.numLines * 13));
            }

            // Playable Song
            else
            {
                // Song Name
                _lblSongName.x = 36;

                // Song Difficulty
                _lblSongDifficulty = new Text(this, 1, 0, getDifficultyText(), 14);
                _lblSongDifficulty.setAreaParams(30, 27, Text.CENTER);

                // Song Flag
                var FLAG_TEXT:String = GlobalVariables.getSongIcon(_songInfo, rank);
                if (FLAG_TEXT != "" && GlobalVariables.instance.activeUser.DISPLAY_SONG_FLAG)
                {
                    _lblSongFlag = new Text(this, 296, 0, FLAG_TEXT, 14);
                    _lblSongFlag.setAreaParams(100, 27, Text.RIGHT);

                    // Adjust Song Name to not overlap song flag.
                    _lblSongName.setAreaParams(347 - _lblSongFlag.textfield.textWidth, 27);
                }
                else
                {
                    _lblSongName.setAreaParams(353, 27);
                }
                _height = 27;
            }

            showHoverMessage(false);
            draw();
        }

        public function setContextMenu(val:ContextMenu):void
        {
            this.contextMenu = val;
        }

        public function getDifficultyText():String
        {
            if (isFavorite)
                return '<font color="#f7b9e4">' + _songInfo.difficulty + '</font>';

            if (songInfo.is_unranked)
                return '<font color="#9C9C9C">' + _songInfo.difficulty + '</font>';

            return songInfo.difficulty.toString();
        }

        public function getSongLockText():String
        {
            switch (songInfo.access)
            {
                case GlobalVariables.SONG_ACCESS_CREDITS:
                    return sprintf(_lang.string("song_selection_banned_credits"), {"more_needed": NumberUtil.numberFormat(songInfo.credits - _gvars.activeUser.credits),
                            "user_credits": NumberUtil.numberFormat(_gvars.activeUser.credits),
                            "song_price": NumberUtil.numberFormat(songInfo.credits)});

                case GlobalVariables.SONG_ACCESS_PURCHASED:
                    return sprintf(_lang.string("song_selection_banned_purchased"), {"song_price": NumberUtil.numberFormat(songInfo.price)});

                case GlobalVariables.SONG_ACCESS_VETERAN:
                    return _lang.string("song_selection_banned_veteran");

                case GlobalVariables.SONG_ACCESS_TOKEN:
                    return _gvars.TOKENS[songInfo.level].info;

                case GlobalVariables.SONG_ACCESS_BANNED:
                    return _lang.string("song_selection_banned_invalid");
            }
            return sprintf(_lang.string("song_selection_banned_unknown"), {"access": songInfo.access});
        }

        public function get songInfo():SongInfo
        {
            return _songInfo;
        }

        public function get level():int
        {
            return _level;
        }

        public function set highlight(val:Boolean):void
        {
            _highlight = val;
            draw();
            showHoverMessage(val);
        }

        public function get highlight():Boolean
        {
            return _highlight || _active;
        }

        public function set active(val:Boolean):void
        {
            _active = val;
            draw();
            showHoverMessage(val);
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

        public function get noteEnabled():Boolean
        {
            return _hoverEnabled;
        }

        public function set noteEnabled(val:Boolean):void
        {
            _hoverEnabled = val;
        }
    }
}
