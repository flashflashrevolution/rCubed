package menu
{
    import assets.menu.ScrollBackground;
    import assets.menu.ScrollDragger;
    import assets.menu.SongSelectionBackground;
    import by.blooddy.crypto.MD5;
    import classes.BoxButton;
    import classes.BoxCheck;
    import classes.Language;
    import classes.Playlist;
    import classes.Text;
    import com.flashfla.components.ScrollBar;
    import com.flashfla.components.ScrollPane;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;

    public class MenuTokens extends MenuPanel
    {
        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _playlist:Playlist = Playlist.instanceCanon;

        private var background:SongSelectionBackground;
        private var scrollbar:ScrollBar;
        private var pane:ScrollPane;

        private var normalTokenButton:BoxButton;
        private var skillTokenButton:BoxButton;
        private var hideCompleteCheck:BoxCheck;

        private var _lang:Language = Language.instance;

        public var options:Object;
        public var isLoading:Boolean = false;

        private static var loadedTokenImages:Object = {};
        private static var loadQueue:Array = [];
        private static var ACTIVE_DOWNLOAD:Object = null;

        public function MenuTokens(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            //- Setup Settings
            options = new Object();
            options.active_type = 'ski';
            options.filter_complete = false;

            //- Add Background
            background = new SongSelectionBackground();
            background.x = 145;
            background.y = 52;
            background.pageBackground.alpha = 0;
            this.addChild(background);

            //- Add ScrollPane
            pane = new ScrollPane(578, 358);
            pane.x = 155; // 332
            pane.y = 64;
            var border:Sprite = new Sprite();
            border.graphics.lineStyle(1, 0xFFFFFF, 1, true);
            border.graphics.moveTo(0.3, -0.5);
            border.graphics.lineTo(577, -0.5);
            border.graphics.moveTo(0.3, 358.5);
            border.graphics.lineTo(577, 358.5);
            border.alpha = 0.35;
            pane.addChild(border);
            this.addChild(pane);

            //- Add ScrollBar
            scrollbar = new ScrollBar(21, 325, new ScrollDragger(), new ScrollBackground());
            scrollbar.x = 744;
            scrollbar.y = 81;
            this.addChild(scrollbar);

            // Menu Left
            normalTokenButton = new BoxButton(this, 5, 130, 124, 29, _lang.string("menu_tokens_normal"), 12, onNormalSelect);

            skillTokenButton = new BoxButton(this, 5, 164, 124, 29, _lang.string("menu_tokens_skill"), 12, onSkillSelect);
            skillTokenButton.active = true;

            var hideLabel:Text = new Text(this, 10, 230, _lang.string("menu_tokens_hide_complete"));
            hideCompleteCheck = new BoxCheck(this, 106, 233, hideCompleteClick);

            //- Add Content
            buildTokens();

            return true;
        }

        private function hideCompleteClick(e:Event):void
        {
            options.filter_complete = !options.filter_complete;
            hideCompleteCheck.checked = options.filter_complete;
            buildTokens();
        }

        private function onNormalSelect(e:Event):void
        {
            if (options.active_type != 'has')
            {
                options.active_type = 'has';
                normalTokenButton.active = true;
                skillTokenButton.active = false;
                buildTokens();
            }
        }

        private function onSkillSelect(e:Event):void
        {
            if (options.active_type != 'ski')
            {
                options.active_type = 'ski';
                normalTokenButton.active = false;
                skillTokenButton.active = true;
                buildTokens();
            }
        }

        override public function dispose():void
        {
            if (pane)
            {
                pane.dispose();
                this.removeChild(pane);
                pane = null;
            }

            normalTokenButton.dispose();
            skillTokenButton.dispose();

            super.dispose();
        }

        override public function stageAdd():void
        {
            //- Add Listeners
            if (stage)
            {
                scrollbar.addEventListener(Event.CHANGE, scrollBarMoved, false, 0, false);
                pane.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMoved, false, 0, false);
            }
        }

        override public function stageRemove():void
        {
            //- Remove Listeners
            if (stage)
            {
                scrollbar.removeEventListener(Event.CHANGE, scrollBarMoved, false);
                pane.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMoved, false);
            }
        }

        public function buildTokens():void
        {
            //- Clear out old MC in content pane
            scrollbar.reset();
            pane.clear();
            loadQueue = [];

            var yOffset:int = 0;
            var sX:int = 0;
            var token:TokenItem;
            for each (var item:Object in _gvars.TOKENS_TYPE[options.active_type])
            {
                if (options.filter_complete && item['unlock'])
                    continue;

                token = new TokenItem(item);
                token.y = yOffset;
                token.addEventListener(MouseEvent.CLICK, e_tokenClick);
                pane.content.addChild(token);
                yOffset += token.height + 5;
                sX += 1;

                addTokenImageLoader(item, token);
            }

            downloadTokenImage();

            options.totalItems = sX;
            pane.scrollTo(scrollbar.scroll, false);
            scrollbar.draggerVisibility = (yOffset > pane.height);
        }

        private function e_tokenClick(e:Event):void
        {
            var token_songs:Array = [];
            for each (var level:int in(e.target as TokenItem).token_levels)
            {
                if (level > 0)
                {
                    var songData:Object = _playlist.getSong(level);
                    if (songData.error == null)
                        token_songs.push(songData);
                }
            }

            if (token_songs.length <= 0)
                return;

            _gvars.songQueue = token_songs;
            MenuSongSelection.options.queuePlaylist = _gvars.songQueue;

            switchTo(MainMenu.MENU_SONGSELECTION);
            MenuSongSelection.options.infoTab = MenuSongSelection.TAB_QUEUE;
            var panel:MenuSongSelection = ((_gvars.gameMain.activePanel as MainMenu).panel as MenuSongSelection);
            panel.swapToQueue();
        }

        private function addTokenImageLoader(token_info:Object, token_ui:TokenItem):void
        {
            var imageHash:String = MD5.hash(token_info['picture']);
            if (loadedTokenImages[imageHash] != null)
            {
                token_ui.addTokenImage(loadedTokenImages[imageHash] as Bitmap, false);
                return;
            }

            // Load Image
            loadQueue.push({"hash": imageHash, "url": token_info['picture'], "ui": token_ui});
        }

        private function downloadTokenImage():void
        {
            if (loadQueue.length <= 0 || ACTIVE_DOWNLOAD != null)
                return;

            ACTIVE_DOWNLOAD = loadQueue.shift();

            // Load Avatar
            var loader:Loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, downloadTokenImageComplete);
            loader.load(new URLRequest(ACTIVE_DOWNLOAD['url']));
        }

        private function downloadTokenImageComplete(e:Event):void
        {
            loadedTokenImages[ACTIVE_DOWNLOAD['hash']] = e.target.content as Bitmap;

            if ((ACTIVE_DOWNLOAD['ui'] as TokenItem).parent != null)
                (ACTIVE_DOWNLOAD['ui'] as TokenItem).addTokenImage(e.target.content as Bitmap);

            ACTIVE_DOWNLOAD = null;

            downloadTokenImage();
        }

        private function mouseWheelMoved(e:MouseEvent):void
        {

            var dist:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(dist);
            scrollbar.scrollTo(dist);
        }

        private function scrollBarMoved(e:Event):void
        {
            pane.scrollTo(e.target.scroll, false);
        }
    }
}
