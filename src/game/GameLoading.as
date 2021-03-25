package game
{
    import classes.Language;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.chart.Song;
    import classes.ui.BoxButton;
    import classes.ui.ProgressBar;
    import com.flashfla.utils.NumberUtil;
    import com.greensock.TweenLite;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import menu.MenuPanel;

    public class GameLoading extends MenuPanel
    {
        private var _textFormat:TextFormat = new TextFormat(Language.UNI_FONT_NAME, 16, 0xFFFFFF, true);

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _playlist:Playlist = Playlist.instance;

        private var preloader:ProgressBar;
        private var namedisplay:TextField;
        private var blackOverlay:Sprite;
        private var loadTimer:int = 0;
        private var cancelLoadButton:BoxButton;

        private var song:Song;
        private var songName:String = "";

        public function GameLoading(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            _gvars.songRestarts = 0;
            //- Set Active Song
            if (_gvars.songQueue.length > 0)
            {
                var songInfo:SongInfo = _gvars.songQueue[0];
                _gvars.songQueue.shift();

                song = _gvars.getSongFile(songInfo, _gvars.options.loadPreview);
                _gvars.options.song = song;
            }
            else if (_gvars.options.song)
                song = _gvars.options.song;
            else
            { // No songs in queue? Something went wrong...
                switchTo(Main.GAME_MENU_PANEL);
                return false;
            }
            if (song && song.isLoaded)
            {
                switchTo(GameMenu.GAME_PLAY);
                return false;
            }
            return true;
        }

        override public function stageAdd():void
        {
            songName = _lang.wrapFont(song.songInfo.name ? song.songInfo.name : "Invalid Song / Replay");

            //- Preloader Display
            preloader = new ProgressBar(this, 10, Main.GAME_HEIGHT - 30, Main.GAME_WIDTH - 20, 20);

            //- Song Name Display
            namedisplay = new TextField();
            namedisplay.x = 10;
            namedisplay.y = Main.GAME_HEIGHT - 58;
            namedisplay.selectable = false;
            namedisplay.embedFonts = true;
            namedisplay.antiAliasType = AntiAliasType.ADVANCED;
            namedisplay.autoSize = "left";
            namedisplay.defaultTextFormat = _textFormat;
            namedisplay.htmlText = songName;
            this.addChild(namedisplay);

            //- Frame Listener
            this.addEventListener(Event.ENTER_FRAME, updatePreloader);
        }

        override public function stageRemove():void
        {
            this.removeEventListener(Event.ENTER_FRAME, updatePreloader);

            if (cancelLoadButton)
                cancelLoadButton.dispose();

            if (preloader)
                preloader.removeEventListener(Event.REMOVED_FROM_STAGE, preloaderRemoved);
        }

        ///- PreloaderHandlers
        private function updatePreloader(e:Event):void
        {
            loadTimer++;

            // TODO: use localized strings here
            namedisplay.htmlText = "";
            if (song.songInfo.name)
            {
                namedisplay.htmlText += songName + " - " + song.progress + "%  --- ";

                if (song.bytesTotal > 0)
                    namedisplay.htmlText += "(" + NumberUtil.bytesToString(song.bytesLoaded) + " / " + NumberUtil.bytesToString(song.bytesTotal) + ")";
                else
                    namedisplay.htmlText += "Connecting..."

                if (song.loadFail)
                    namedisplay.htmlText += " --- <font color=\"#FFC4C4\">[Loading Failed]</font>";
            }
            else
                namedisplay.htmlText += songName;

            preloader.update(song.progress);

            if ((loadTimer >= 60 || song.loadFail) && !cancelLoadButton && !_gvars.flashvars.replay)
            {
                cancelLoadButton = new BoxButton(this, Main.GAME_WIDTH - 85, preloader.y - 35, 75, 25, "Cancel", 12, e_cancelClick);
            }

            if (song.loadFail)
            {
                // Loading Failed :/
                _gvars.removeSongFile(song);
                if (cancelLoadButton)
                    cancelLoadButton.text = "Return";
                removeEventListener(Event.ENTER_FRAME, updatePreloader);
            }

            if (preloader.isComplete && song.isLoaded)
            {
                removePopup();
                this.removeEventListener(Event.ENTER_FRAME, updatePreloader);
                preloader.addEventListener(Event.REMOVED_FROM_STAGE, preloaderRemoved);
                preloader.remove();

                blackOverlay = new Sprite();
                blackOverlay.alpha = 0;
                blackOverlay.graphics.beginFill(0x000000);
                blackOverlay.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
                this.addChild(blackOverlay);
                TweenLite.to(blackOverlay, 0.5, {alpha: 1});
            }
        }

        private function e_cancelClick(e:Event):void
        {
            _gvars.removeSongFile(song);

            removeEventListener(Event.ENTER_FRAME, updatePreloader);
            switchTo(Main.GAME_MENU_PANEL);
        }

        private function preloaderRemoved(e:Event = null):void
        {
            preloader.removeEventListener(Event.REMOVED_FROM_STAGE, preloaderRemoved);
            switchTo(GameMenu.GAME_PLAY);
        }
    }
}
