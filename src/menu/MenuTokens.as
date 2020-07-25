package menu
{
    import assets.menu.ScrollBackground;
    import assets.menu.ScrollDragger;
    import assets.menu.SongSelectionBackground;
    import by.blooddy.crypto.MD5;
    import classes.BoxButton;
    import classes.BoxCheck;
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
            border.graphics.lineTo(578, 0);
            border.graphics.moveTo(0, 357);
            border.graphics.lineTo(578, 357);
            border.alpha = 0.35;
            pane.addChild(border);
            this.addChild(pane);

            //- Add ScrollBar
            scrollbar = new ScrollBar(21, 325, new ScrollDragger(), new ScrollBackground());
            scrollbar.x = 744;
            scrollbar.y = 81;
            this.addChild(scrollbar);

            // Menu Left
            normalTokenButton = new BoxButton(124, 29, "Normal Tokens");
            normalTokenButton.x = 5;
            normalTokenButton.y = 130;
            normalTokenButton.addEventListener(MouseEvent.CLICK, onNormalSelect);
            this.addChild(normalTokenButton);

            skillTokenButton = new BoxButton(124, 29, "Skill Tokens");
            skillTokenButton.x = 5;
            skillTokenButton.y = 164;
            skillTokenButton.addEventListener(MouseEvent.CLICK, onSkillSelect);
            this.addChild(skillTokenButton);

            var hideLabel:Text = new Text("Hide Complete:");
            hideLabel.x = 10;
            hideLabel.y = 230;
            addChild(hideLabel);

            hideCompleteCheck = new BoxCheck();
            hideCompleteCheck.x = 106;
            hideCompleteCheck.y = 233;
            hideCompleteCheck.addEventListener(MouseEvent.CLICK, hideCompleteClick);
            addChild(hideCompleteCheck);

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
                buildTokens();
            }
        }

        private function onSkillSelect(e:Event):void
        {
            if (options.active_type != 'ski')
            {
                options.active_type = 'ski';
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
            _gvars.songQueue = [];

            for each (var level:int in(e.target as TokenItem).token_levels)
            {
                if (level > 0)
                {
                    var songData:Object = _playlist.getSong(level);
                    if (songData.error == null)
                        _gvars.songQueue.push(songData);
                }
            }

            if (_gvars.songQueue.length <= 0)
                return;

            switchTo(MainMenu.MENU_SONGSELECTION);
            var panel:MenuSongSelection = ((_gvars.gameMain.activePanel as MainMenu).panel as MenuSongSelection);
            panel.options.infoTab = MenuSongSelection.TAB_QUEUE;
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
