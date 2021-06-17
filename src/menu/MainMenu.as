/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerPanel;
    import arc.mp.MultiplayerSingleton;
    import assets.GameBackgroundColor;
    import assets.menu.Logo;
    import assets.menu.MainMenuBackground;
    import assets.menu.icons.fa.iconDelete;
    import assets.menu.icons.fa.iconPause;
    import assets.menu.icons.fa.iconPlay;
    import assets.menu.icons.fa.iconStop;
    import classes.Alert;
    import classes.Language;
    import classes.ui.Box;
    import classes.ui.BoxIcon;
    import classes.ui.MouseTooltip;
    import classes.ui.SimpleBoxButton;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import com.flashfla.net.WebRequest;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.SystemUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import popups.PopupFilterManager;
    import popups.PopupSkillRankUpdate;

    public class MainMenu extends MenuPanel
    {
        public static const MENU_SONGSELECTION:String = "MenuSongSelection";
        public static const MENU_MULTIPLAYER:String = "MenuMultiplayer";
        public static const MENU_FRIENDS:String = "MenuFriends";
        public static const MENU_STATS:String = "MenuStats";
        public static const MENU_FILTERS:String = "MenuFilter";
        public static const MENU_SEASONS:String = "MenuSeasons";
        public static const MENU_OPTIONS:String = "MenuOptions";

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        public var _MenuSingleplayer:MenuPanel;
        private var _MenuMultiplayer:MenuPanel;
        private var _MenuFriends:MenuPanel;
        private var _MenuStats:MenuPanel;
        private var _MenuSeasons:MenuPanel;

        private var hover_message:MouseTooltip;
        private var user_text:Text;
        private var menuItemBox:Sprite;
        private var logo:Logo;

        public var menuMusicControls:Box;
        private const mmc_icons:Array = new Array(new iconPlay(), new iconPause(), new iconStop(), new iconDelete());
        private const mmc_functions:Array = new Array(playMusic, pauseMusic, stopMusic, deleteMusic);
        private var mmc_buttons:Array = new Array(4);
        private const mmc_strings:Array = ["play", "pause", "stop", "remove"];

        private var statUpdaterBtn:SimpleBoxButton;
        private var rankUpdateThrobber:Throbber;

        public var menuItems:Array = [["menu_play", MENU_SONGSELECTION], ["menu_multiplayer", MENU_MULTIPLAYER], ["menu_seasons", MENU_SEASONS], ["menu_filters", MENU_FILTERS], ["menu_options", MENU_OPTIONS]];
        public var panel:MenuPanel;
        public var options:Object;

        ///- Constructor
        public function MainMenu(myParent:MenuPanel)
        {
            super(myParent);

            ArcGlobals.instance.resetConfig();
        }

        override public function init():Boolean
        {
            //- Setup Options
            options = {};
            options.activePanel = -1;

            //- Add Logo
            logo = new Logo();
            logo.x = 18 + logo.width * 0.5;
            logo.y = 8 + logo.height * 0.5;
            this.addChild(logo);

            //- Add Menu Background
            var menu_bg:MainMenuBackground = new MainMenuBackground();
            menu_bg.x = 145;
            this.addChild(menu_bg);

            //- Add Menu to Stage
            buildMenuItems();

            for (var i:int = 0; i < mmc_strings.length; ++i)
            {
                var menu_music_button:BoxIcon = new BoxIcon(null, 5 + 30 * i, 5, 25, 25, mmc_icons[i], mmc_functions[i]);
                mmc_buttons[i] = menu_music_button;
            }

            //- Add Menu Music to Stage
            if (_gvars.menuMusic)
            {
                drawMenuMusicControls();
                if (!_gvars.menuMusic.isPlaying && !_gvars.menuMusic.userStopped)
                {
                    _gvars.menuMusic.start();
                }
            }

            MultiplayerSingleton.getInstance().gameplayCleanup();

            //- Add Main Panel to Stage
            var targetMenu:String = "";
            // Guests
            if (GlobalVariables.instance.activeUser.isGuest || (_gvars.options && _gvars.options.singleplayer))
            {
                targetMenu = MENU_SONGSELECTION;
            }
            else
            {
                if (!Flags.VALUES[Flags.STARTUP_SCREEN])
                {
                    var playerStartup:int = _gvars.activeUser.startUpScreen;

                    // Auto - Connect MP
                    if (playerStartup == 0 || playerStartup == 1)
                        var pan:MultiplayerPanel = MultiplayerSingleton.getInstance().getPanel(this);

                    if (playerStartup == 0)
                        targetMenu = MENU_MULTIPLAYER;
                    else
                        targetMenu = MENU_SONGSELECTION;

                    Flags.VALUES[Flags.STARTUP_SCREEN] = true;
                }
                else
                {
                    targetMenu = MENU_MULTIPLAYER;
                }
            }
            switchTo(targetMenu);
            return false;
        }

        override public function dispose():void
        {
            if (_MenuSingleplayer)
            {
                _MenuSingleplayer.stageRemove();
                _MenuSingleplayer.dispose();
                if (this.contains(_MenuSingleplayer))
                    this.removeChild(_MenuSingleplayer);
                _MenuSingleplayer = null;
            }
            if (_MenuMultiplayer)
            {
                _MenuMultiplayer.stageRemove();
                _MenuMultiplayer.dispose();
                if (this.contains(_MenuMultiplayer))
                    this.removeChild(_MenuMultiplayer);
                _MenuMultiplayer = null;
            }
            if (_MenuFriends)
            {
                _MenuFriends.stageRemove();
                _MenuFriends.dispose();
                if (this.contains(_MenuFriends))
                    this.removeChild(_MenuFriends);
                _MenuFriends = null;
            }
            if (_MenuStats)
            {
                _MenuStats.stageRemove();
                _MenuStats.dispose();
                if (this.contains(_MenuStats))
                    this.removeChild(_MenuStats);
                _MenuStats = null;
            }
            super.stageRemove();
        }

        override public function draw():void
        {
            buildMenuItems();
            panel.draw();
        }

        public function buildMenuItems():void
        {
            if (menuItemBox != null)
            {
                this.removeChild(menuItemBox);
                menuItemBox = null;

                this.removeChild(user_text);
                user_text = null;
            }

            //- User Info Display
            _gvars.activeUser.calculateAverageRank();
            user_text = new Text(this, 153, 452, sprintf(_lang.string("main_menu_userbar"), {"player_name": _gvars.activeUser.name,
                    "games_played": NumberUtil.numberFormat(_gvars.activeUser.gamesPlayed),
                    "grand_total": NumberUtil.numberFormat(_gvars.activeUser.grandTotal),
                    "rank": NumberUtil.numberFormat(_gvars.activeUser.gameRank),
                    "skill_level": _gvars.activeUser.skillLevel,
                    "skill_rating": NumberUtil.numberFormat(_gvars.activeUser.skillRating, 2),
                    "avg_rank": NumberUtil.numberFormat(_gvars.activeUser.averageRank, 3, true)}));
            user_text.width = 594;
            user_text.height = 28;
            user_text.align = Text.CENTER;

            if (!_gvars.activeUser.isGuest)
            {
                statUpdaterBtn = new SimpleBoxButton(609, 28);
                statUpdaterBtn.x = 147;
                statUpdaterBtn.y = Main.GAME_HEIGHT - 28;
                statUpdaterBtn.addEventListener(MouseEvent.MOUSE_OVER, e_statUpdaterMouseOver);
                statUpdaterBtn.addEventListener(MouseEvent.CLICK, e_statUpdaterClick);
                this.addChild(statUpdaterBtn);
            }

            menuItemBox = new Sprite();
            menuItemBox.x = 145;
            menuItemBox.y = 8;

            //- Add Menu Buttons
            for (var item:String in menuItems)
            {
                var menuItem:MenuButton = new MenuButton(menuItemBox, Number(item) * 122, 0, _lang.string(menuItems[item][0]), item == options.activePanel, menuItemClick);
                menuItem.panel = menuItems[item][1];
                menuItem.mouseChildren = false;
                menuItem.useHandCursor = true;
                menuItem.buttonMode = true;

                if (menuItems[item][0] == "menu_seasons")
                {
                   menuItem.enabled = false;
                   menuItem.setHoverText("Coming Soon!");
                   menuItem.mouseEnabled = true;
                   menuItem.removeEventListener(MouseEvent.CLICK, menuItemClick)
                }
            }

            this.addChild(menuItemBox);
        }

        public function drawMenuMusicControls():void
        {
            if (!menuMusicControls)
            {
                menuMusicControls = new Box(null, 7, -1, false, false);
                menuMusicControls.setSize(125, 35);
                menuMusicControls.normalAlpha = 1;
                menuMusicControls.color = GameBackgroundColor.BG_STATIC;

                for (var i:int = 0; i < mmc_strings.length; ++i)
                {
                    menuMusicControls.addChildAt(mmc_buttons[i], i);
                }

                updateMenuMusicControls();
            }

            if (!contains(menuMusicControls))
                addChild(menuMusicControls);
        }

        public function updateMenuMusicControls():void
        {
            if (menuMusicControls)
            {
                for (var i:int = 0; i < mmc_strings.length; ++i)
                {
                    (menuMusicControls.getChildAt(i) as BoxIcon).setHoverText(_lang.string("main_menu_music_" + mmc_strings[i]), "bottom");
                }

                buildMenuMusicControlsContextMenu();
            }
        }

        private function buildMenuMusicControlsContextMenu():void
        {
            // Context Menu Display song Playing
            var musicContextMenu:ContextMenu = new ContextMenu();
            var musicContextMenuPlaying:ContextMenuItem = new ContextMenuItem(sprintf(_lang.stringSimple("main_menu_now_playing"), {"music_name": LocalStore.getVariable("menu_music", "Unknown")}), false, false);
            musicContextMenu.customItems.push(musicContextMenuPlaying);
            menuMusicControls.contextMenu = musicContextMenu;
        }

        private function playMusic(e:Event):void
        {
            if (_gvars.menuMusic && !_gvars.menuMusic.isPlaying)
            {
                _gvars.menuMusic.userStart();
            }
        }

        private function pauseMusic(e:Event):void
        {
            if (_gvars.menuMusic && _gvars.menuMusic.isPlaying)
            {
                _gvars.menuMusic.userPause();
            }
        }

        private function stopMusic(e:Event):void
        {
            if (_gvars.menuMusic && _gvars.menuMusic.isPlaying)
            {
                _gvars.menuMusic.userStop();
            }
        }

        private function deleteMusic(e:Event):void
        {
            if (_gvars.menuMusic)
            {
                _gvars.menuMusic.userStop();
                _gvars.menuMusic = null;
                menuMusicControls.parent.removeChild(menuMusicControls);

                AirContext.deleteFile(AirContext.getAppPath(Constant.MENU_MUSIC_PATH));
            }
        }

        override public function switchTo(_panel:String, useNew:Boolean = false):Boolean
        {
            //- Check Parent Function first.
            if (super.switchTo(_panel, useNew))
                return true;

            //- Do current panel.
            var isFound:Boolean = false;
            var initValid:Boolean = false;
            var doStageAddAnyway:Boolean = false;

            if (_panel == MENU_OPTIONS)
            {
                addPopup(Main.POPUP_OPTIONS);
                return true;
            }
            else if (_panel == MENU_FILTERS)
            {
                addPopup(new PopupFilterManager(this));
                return true;
            }

            if (panel != null)
            {
                panel.stageRemove();
                this.removeChild(panel);
            }

            switch (_panel)
            {
                case MENU_SONGSELECTION:
                    if (_MenuSingleplayer == null || useNew)
                        _MenuSingleplayer = new MenuSongSelection(this);
                    panel = _MenuSingleplayer;
                    options.activePanel = 0;
                    isFound = true;
                    break;

                case MENU_MULTIPLAYER:
                    if (_MenuMultiplayer == null || useNew)
                        _MenuMultiplayer = MultiplayerSingleton.getInstance().getPanel(this); //_MenuMultiplayer = new MenuMultiplayer(this);
                    panel = _MenuMultiplayer;
                    options.activePanel = 1;
                    isFound = true;
                    break;
                /*
                   case MENU_FRIENDS:
                   if (_MenuFriends == null || useNew)
                   _MenuFriends = new MenuFriends(this);
                   panel = _MenuFriends;
                   options.activePanel = 2;
                   isFound = true;
                   break;
                   case MENU_STATS:
                   if (_MenuStats == null || useNew)
                   _MenuStats = new MenuStats(this);
                   panel = _MenuStats;
                   options.activePanel = 2;
                   isFound = true;
                   break;
                 */

                case MENU_SEASONS:
                    if (_MenuSeasons == null || useNew)
                        _MenuSeasons = new MenuSeasons(this);
                    panel = _MenuSeasons;
                    options.activePanel = 2;
                    isFound = true;
                    break;
            }
            this.addChild(panel);

            if (panel.hasInit)
                doStageAddAnyway = true;

            if (!panel.hasInit)
            {
                initValid = panel.init();
                panel.hasInit = true;
            }

            if (initValid || doStageAddAnyway)
                panel.stageAdd();

            buildMenuItems();
            SystemUtil.gc();
            return isFound;
        }

        private function menuItemClick(e:MouseEvent = null):void
        {
            switchTo(e.target.panel);
        }

        private function e_statUpdaterMouseOver(e:Event):void
        {
            statUpdaterBtn.addEventListener(MouseEvent.MOUSE_OUT, e_statUpdaterMouseOut);
            displayToolTip(statUpdaterBtn.x + (statUpdaterBtn.width / 2), statUpdaterBtn.y - 25, _lang.string("menu_update_stat_over"));
        }

        private function e_statUpdaterMouseOut(e:Event):void
        {
            statUpdaterBtn.removeEventListener(MouseEvent.MOUSE_OUT, e_statUpdaterMouseOut);
            removeChild(hover_message);
        }

        private function displayToolTip(tx:Number, ty:Number, text:String, align:String = "center"):void
        {
            if (!hover_message)
                hover_message = new MouseTooltip("", 500)
            hover_message.message = text;

            switch (align)
            {
                default:
                case "left":
                    hover_message.x = tx;
                    hover_message.y = ty;
                    break;
                case "right":
                    hover_message.x = tx - hover_message.width;
                    hover_message.y = ty;
                    break;
                case "center":
                    hover_message.x = tx - (hover_message.width / 2);
                    hover_message.y = ty;
                    break;
            }

            addChild(hover_message);
        }

        private function e_statUpdaterClick(e:MouseEvent):void
        {
            if (!rankUpdateThrobber)
            {
                rankUpdateThrobber = new Throbber(16, 16, 2);
                rankUpdateThrobber.x = Main.GAME_WIDTH - 48;
                rankUpdateThrobber.y = Main.GAME_HEIGHT - 22;
                rankUpdateThrobber.visible = false;
                this.addChild(rankUpdateThrobber);
            }
            if (rankUpdateThrobber.running)
                return;

            var wr:WebRequest = new WebRequest(Constant.USER_RANKS_UPDATE_URL, c_rankComplete, c_rankFail);
            wr.load({"session": _gvars.userSession});
            rankUpdateThrobber.visible = true;
            rankUpdateThrobber.start();

            function c_rankComplete(e:* = null):void
            {
                var resp:Object = JSON.parse(e.target.data);
                if (_gvars.gameMain.activePanel is MainMenu)
                {
                    _gvars.gameMain.addPopup(new PopupSkillRankUpdate(_gvars.gameMain, resp), true);
                    rankUpdateThrobber.stop();
                    rankUpdateThrobber.visible = false;
                }
            }

            function c_rankFail(e:*):void
            {
                Alert.add(_lang.string("skill_rank_update_fail"), 90, Alert.RED);
                if (_gvars.gameMain.activePanel is MainMenu)
                {
                    rankUpdateThrobber.stop();
                    rankUpdateThrobber.visible = false;
                }
            }
        }
    }
}
