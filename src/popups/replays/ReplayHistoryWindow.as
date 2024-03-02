package popups.replays
{
    import assets.GameBackgroundColor;
    import assets.menu.icons.fa.iconSearch;
    import classes.Alert;
    import classes.Language;
    import classes.replay.Replay;
    import classes.ui.BoxButton;
    import classes.ui.BoxText;
    import classes.ui.ScrollBar;
    import classes.ui.SimpleBoxButton;
    import classes.ui.Text;
    import com.flashfla.utils.SpriteUtil;
    import com.flashfla.utils.SystemUtil;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import game.GameOptions;
    import menu.FileLoader;
    import menu.MenuPanel;

    public class ReplayHistoryWindow extends MenuPanel
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        private var box:Sprite;
        private var bmp:Bitmap;

        public var scrollbar:ScrollBar;
        public var pane:ReplayHistoryScrollpane;

        private var TABS:Vector.<ReplayHistoryTabBase>;

        private var CURRENT_TAB:ReplayHistoryTabBase;
        private var CURRENT_INDEX:int = -1;
        private static var LAST_INDEX:int = 0;

        private var TAB_BUTTONS:Vector.<TabButton>;

        private var txt_title:Text;

        private var search_field:BoxText;
        private var search_field_placeholder:Text;
        private var _search_text:String = "";

        // buttons
        private var btn_close:BoxButton;

        public function ReplayHistoryWindow(myParent:MenuPanel):void
        {
            // build menus
            TABS = new <ReplayHistoryTabBase>[new ReplayHistoryTabSession(this),
                new ReplayHistoryTabLocal(this)];

            if (!_gvars.activeUser.isGuest)
                TABS.push(new ReplayHistoryTabOnline(this));

            TAB_BUTTONS = new <TabButton>[];

            super(myParent);
        }

        override public function stageAdd():void
        {
            stage.focus = this.stage;

            bmp = SpriteUtil.getBitmapSprite(stage);
            this.addChild(bmp);

            // background
            box = new Sprite();
            box.graphics.lineStyle(0, 0, 0);

            box.graphics.beginFill(0, 0.2);
            box.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            box.graphics.endFill();

            box.graphics.beginFill(GameBackgroundColor.BG_POPUP, 0.6);
            box.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            box.graphics.endFill();

            box.graphics.beginFill(0xFFFFFF, 0.07);
            box.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            box.graphics.endFill();

            box.graphics.beginFill(0x000000, 0.1);
            box.graphics.drawRect(0, 61, 173, Main.GAME_HEIGHT - 60);
            box.graphics.endFill();

            // dividers
            box.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            box.graphics.moveTo(670, 0);
            box.graphics.lineTo(670, 60);
            box.graphics.moveTo(0, 60);
            box.graphics.lineTo(Main.GAME_WIDTH, 60);
            box.graphics.moveTo(174, 61);
            box.graphics.lineTo(174, Main.GAME_HEIGHT);
            box.graphics.moveTo(Main.GAME_WIDTH - 16, 61);
            box.graphics.lineTo(Main.GAME_WIDTH - 16, Main.GAME_HEIGHT);

            this.addChild(box);

            // scroll pane
            pane = new ReplayHistoryScrollpane(this, 180, 61, 584, Main.GAME_HEIGHT - 61);
            pane.addEventListener(MouseEvent.MOUSE_WHEEL, e_mouseWheelMoved, false, 0, false);
            pane.addEventListener(MouseEvent.CLICK, e_replayEntryClick);
            scrollbar = new ScrollBar(this, Main.GAME_WIDTH - 16, 61, 16, Main.GAME_HEIGHT - 61, null, new Sprite());
            scrollbar.addEventListener(Event.CHANGE, e_scrollBarMoved, false, 0, false);

            // ui
            buildTabs();

            txt_title = new Text(box, 15, 5, _lang.string("replay_history_title"), 32);

            // Search
            search_field_placeholder = new Text(box, 405, 17, _lang.string("replay_search"));
            search_field_placeholder.setAreaParams(210, 27, "left");
            search_field_placeholder.alpha = 0.6;

            search_field = new BoxText(box, 400, 15, 220, 29);
            search_field.addEventListener(Event.CHANGE, e_searchChange, false, 0, true);

            var searchSprite:Sprite = new iconSearch();
            searchSprite.x = 644;
            searchSprite.y = 31;
            searchSprite.scaleX = searchSprite.scaleY = 0.25;
            searchSprite.alpha = 0.8;
            box.addChild(searchSprite);

            btn_close = new BoxButton(box, 685, 15, 80, 29, _lang.string("menu_close"), 12, e_clickHandler);

            changeTab(LAST_INDEX);
        }

        override public function stageRemove():void
        {
            CURRENT_TAB.closeTab();
            scrollbar.removeEventListener(Event.CHANGE, e_scrollBarMoved, false);
            pane.removeEventListener(MouseEvent.MOUSE_WHEEL, e_mouseWheelMoved, false);
        }

        public function buildTabs():void
        {
            var tabBox:TabButton;

            for (var idx:int = 0; idx < TABS.length; idx++)
            {
                tabBox = new TabButton(box, -1, 60 + 33 * idx, idx, _lang.string("replay_tab_" + TABS[idx].name));
                tabBox.tabIndex = idx;
                tabBox.addEventListener(MouseEvent.CLICK, e_tabHandler);

                TAB_BUTTONS.push(tabBox);
            }
        }

        public function changeTab(idx:int):void
        {
            if (CURRENT_INDEX == idx)
                return;

            if (CURRENT_TAB != null)
            {
                CURRENT_TAB.closeTab();
                pane.clear();
            }

            CURRENT_INDEX = idx;
            CURRENT_TAB = TABS[idx];
            CURRENT_TAB.openTab();
            CURRENT_TAB.setValues();
            LAST_INDEX = idx;

            // update buttons
            for each (var tabButton:TabButton in TAB_BUTTONS)
                tabButton.setActive(tabButton.index == idx);
        }

        private function e_tabHandler(e:MouseEvent):void
        {
            changeTab((e.currentTarget as TabButton).index);
        }

        private function e_clickHandler(e:MouseEvent):void
        {
            if (e.target == btn_close)
            {
                removePopup();
                return;
            }
        }

        private function e_mouseWheelMoved(e:MouseEvent):void
        {
            if (!scrollbar.visible)
                return;

            var dist:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(dist);
            scrollbar.scrollTo(dist);
        }

        private function e_scrollBarMoved(e:Event):void
        {
            pane.scrollTo(e.target.scroll);
        }

        public function updateScrollPane():void
        {
            pane.scrollTo(0);
            scrollbar.scrollTo(0);

            scrollbar.visible = pane.doScroll;
        }

        public function e_replayEntryClick(e:MouseEvent):void
        {
            var te:* = e.target;
            if (te is SimpleBoxButton)
            {
                var target:SimpleBoxButton = te as SimpleBoxButton;
                var entry:ReplayHistoryEntry = target.parent as ReplayHistoryEntry;
                var replay:Replay = CURRENT_TAB.prepareReplay(entry.replay);

                if (replay == null)
                    return;

                if (target == entry.btn_play)
                {
                    if (replay.song == null)
                    {
                        Alert.add(_lang.string("popup_replay_missing_song_data"), 120, Alert.RED);
                        return;
                    }

                    if (replay.isFileLoader)
                    {
                        var chartLoaded:Boolean = true;
                        if (_gvars.externalSongInfo == null || _gvars.externalSongInfo.engine == null || _gvars.externalSongInfo.engine.cache_id != replay.cacheID)
                            chartLoaded = FileLoader.setupLocalFile(replay.chartPath, replay.settings.arc_engine.chartID);

                        replay.song = _gvars.externalSongInfo;

                        if (!chartLoaded)
                        {
                            Alert.add(_lang.string("popup_replay_file_browser_replays"), 120, Alert.RED);
                            return;
                        }
                    }

                    if (!replay.user.isLoaded())
                        replay.user.loadUser(replay.user.siteId);

                    _gvars.options = new GameOptions();
                    _gvars.options.isolation = false;
                    _gvars.options.replay = replay;
                    _gvars.options.fillFromReplay();
                    _gvars.options.fillFromArcGlobals();

                    _gvars.songResults.length = 0;
                    _gvars.songQueue = [replay.song];

                    _gvars.gameMain.removePopup();

                    _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
                }

                if (target == entry.btn_copy)
                {
                    var replayString:String = replay.getEncode();
                    var success:Boolean = SystemUtil.setClipboard(replayString);
                    if (success)
                    {
                        Alert.add(_lang.string("clipboard_success"), 120, Alert.GREEN);
                    }
                    else
                    {
                        Alert.add(_lang.string("clipboard_failure"), 120, Alert.RED);
                    }
                }
            }
        }

        private function e_searchChange(e:Event):void
        {
            _search_text = search_field.text.toLowerCase();
            search_field_placeholder.visible = (_search_text.length <= 0);
            CURRENT_TAB.setValues();
        }

        public function get searchText():String
        {
            return _search_text;
        }
    }
}


import assets.menu.icons.fa.iconRight;
import classes.ui.SimpleBoxButton;
import classes.ui.Text;
import com.greensock.TweenLite;
import flash.display.Sprite;

internal class TabButton extends Sprite
{
    public var index:int;

    private var text:Text;
    private var button:SimpleBoxButton;
    private var chevron:iconRight;

    private var active:Boolean = false;

    private var hasTopBorder:Boolean = false;

    public function TabButton(parent:Sprite, xpos:Number, ypos:Number, index:int, btnText:String, hasTopBorder:Boolean = false)
    {
        this.index = index;
        this.hasTopBorder = hasTopBorder;

        this.text = new Text(this, 15, 5, btnText);
        this.text.setAreaParams(146, 22);

        this.button = new SimpleBoxButton(175, 32);
        this.addChild(button);

        this.x = xpos;
        this.y = ypos;
        parent.addChild(this);

        this.chevron = new iconRight();
        this.chevron.x = 16;
        this.chevron.y = 16.5;
        this.chevron.scaleX = this.chevron.scaleY = 0.2;
        this.chevron.visible = false;
        this.addChild(chevron);

        draw();
    }

    public function draw():void
    {
        this.graphics.clear();
        this.graphics.lineStyle(0, 0, 0);
        this.graphics.beginFill(0xFFFFFF, (active ? 0.2 : 0.08));
        this.graphics.drawRect(0, 0, 175, 32);
        this.graphics.endFill();

        this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
        this.graphics.moveTo(0, 32);
        this.graphics.lineTo(175, 32);

        if (hasTopBorder)
        {
            this.graphics.moveTo(0, 0);
            this.graphics.lineTo(175, 0);
        }
    }

    public function setActive(newState:Boolean):void
    {
        if (this.active != newState)
        {
            TweenLite.to(this.text, 0.25, {"x": (newState ? 25 : 15)});
            this.active = newState;
            this.button.visible = !newState;
            this.chevron.visible = newState;
            draw();
        }
    }
}
