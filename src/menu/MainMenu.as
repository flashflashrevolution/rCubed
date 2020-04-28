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
    import classes.Alert;
    import classes.Box;
    import classes.Language;
    import classes.MouseTooltip;
    import classes.Text;
    import classes.SimpleBoxButton;
    import com.flashfla.components.Throbber;
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
    import game.GamePlay;

    public class MainMenu extends MenuPanel
    {
        public static const MENU_SONGSELECTION:String = "MenuSongSelection";
        public static const MENU_MULTIPLAYER:String = "MenuMultiplayer";
        public static const MENU_FRIENDS:String = "MenuFriends";
        public static const MENU_STATS:String = "MenuStats";
        public static const MENU_FILTERS:String = "MenuFilter";
        public static const MENU_TOKENS:String = "MenuTokens";
        public static const MENU_OPTIONS:String = "MenuOptions";

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        public var _MenuSingleplayer:MenuPanel;
        private var _MenuMultiplayer:MenuPanel;
        private var _MenuFriends:MenuPanel;
        private var _MenuStats:MenuPanel;
        private var _MenuTokens:MenuPanel;

        private var hover_message:MouseTooltip;
        private var user_text:Text;
        private var menuItemBox:Sprite;
        private var logo:Logo;
        public var menuMusicControls:Box;

        private var statUpdaterBtn:SimpleBoxButton;
        private var rankUpdateThrobber:Throbber;

        public var menuItems:Array = [["menu_play", MENU_SONGSELECTION], ["menu_multiplayer", MENU_MULTIPLAYER], ["menu_tokens", MENU_TOKENS], ["menu_filters", MENU_FILTERS], ["menu_options", MENU_OPTIONS]];
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
            options = new Object();
            options.activePanel = -1;

            //- Add Logo
            logo = new Logo();
            logo.x = 18;
            logo.y = 8;
            this.addChild(logo);

            //- Add Menu Background
            var menu_bg:MainMenuBackground = new MainMenuBackground();
            menu_bg.x = 145;
            this.addChild(menu_bg);

            //- Add Menu to Stage
            buildMenuItems();

            //- Add Menu Music to Stage
            if (_gvars.menuMusic)
            {
                drawMenuMusicControls();
                if (!_gvars.menuMusic.isPlaying && !_gvars.menuMusic.userStopped)
                {
                    _gvars.menuMusic.start();
                }
            }

            //- Analytics
            if (!_gvars.tempFlags['analytics_post'])
            {
                _gvars.postAnalytics();
                _gvars.tempFlags['analytics_post'] = true;
            }

            MultiplayerSingleton.getInstance().gameplayReset();

            //- Add Main Panel to Stage
            var targetMenu:String = "";
            // Guests
            if (GlobalVariables.instance.activeUser.isGuest || GlobalVariables.instance.activeUser.id == 2 || (_gvars.options && _gvars.options.singleplayer))
            {
                targetMenu = MENU_SONGSELECTION;
            }
            else
            {
                if (!_gvars.tempFlags['startup_screen'])
                {
                    var playerStartup:int = _gvars.activeUser.startUpScreen;

                    // Auto - Connect MP
                    if (playerStartup == 0 || playerStartup == 1)
                        var pan:MultiplayerPanel = MultiplayerSingleton.getInstance().getPanel(this);

                    if (playerStartup == 0)
                        targetMenu = MENU_MULTIPLAYER;
                    else
                        targetMenu = MENU_SONGSELECTION;

                    _gvars.tempFlags['startup_screen'] = true;
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
            user_text = new Text(sprintf(_lang.string("main_menu_userbar"), {"player_name": _gvars.activeUser.name,
                    "games_played": NumberUtil.numberFormat(_gvars.activeUser.gamesPlayed),
                    "grand_total": NumberUtil.numberFormat(_gvars.activeUser.grandTotal),
                    "rank": NumberUtil.numberFormat(_gvars.activeUser.gameRank),
                    "skill_level": _gvars.activeUser.skillLevel,
                    "skill_rating": NumberUtil.numberFormat(_gvars.activeUser.skillRating, 2),
                    "avg_rank": NumberUtil.numberFormat(_gvars.activeUser.averageRank, 3, true)}));
            user_text.x = 153;
            user_text.y = 452;
            user_text.width = 594;
            user_text.height = 28;
            user_text.align = Text.CENTER;
            this.addChild(user_text);

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
                var menuItem:MenuButton = new MenuButton(_lang.string(menuItems[item][0]), item == options.activePanel);
                menuItem.x = Number(item) * 122;
                menuItem.panel = menuItems[item][1];
                menuItem.mouseChildren = false;
                menuItem.useHandCursor = true;
                menuItem.buttonMode = true;
                menuItem.addEventListener(MouseEvent.CLICK, menuItemClick);
                menuItemBox.addChild(menuItem);
            }

            this.addChild(menuItemBox);
        }

        public function drawMenuMusicControls():void
        {
            if (!menuMusicControls)
            {
                menuMusicControls = new Box(125, 35, false, false);
                menuMusicControls.normalAlpha = 1;
                menuMusicControls.color = GameBackgroundColor.BG_STATIC;
                menuMusicControls.x = 7;
                menuMusicControls.y = -1;

                var spr_play:Box = new Box(25, 25, true, false);
                spr_play.borderAlpha = 0.75;
                spr_play.x = 5;
                spr_play.y = 5;
                with (spr_play.graphics)
                {
                    lineStyle(1, 0xFFFFFF, 0);
                    beginFill(0xFFFFFF, 0.75);
                    moveTo(7, 6);
                    lineTo(21, 13);
                    lineTo(7, 19);
                    lineTo(7, 6);
                    endFill();
                }
                spr_play.addEventListener(MouseEvent.CLICK, function(e:Event):void
                {
                    if (_gvars.menuMusic && !_gvars.menuMusic.isPlaying)
                    {
                        _gvars.menuMusic.userStart();
                    }
                });
                menuMusicControls.addChild(spr_play);

                var spr_pause:Box = new Box(25, 25);
                spr_pause.borderAlpha = 0.75;
                spr_pause.x = 35;
                spr_pause.y = 5;
                with (spr_pause.graphics)
                {
                    lineStyle(1, 0xFFFFFF, 0);
                    beginFill(0xFFFFFF, 0.75);
                    drawRect(6, 6, 5, 15);
                    drawRect(14, 6, 5, 15);
                    endFill();
                }
                spr_pause.addEventListener(MouseEvent.CLICK, function(e:Event):void
                {
                    if (_gvars.menuMusic && _gvars.menuMusic.isPlaying)
                    {
                        _gvars.menuMusic.userPause();
                    }
                });
                menuMusicControls.addChild(spr_pause);

                var spr_stop:Box = new Box(25, 25);
                spr_stop.borderAlpha = 0.75;
                spr_stop.x = 65;
                spr_stop.y = 5;
                with (spr_stop.graphics)
                {
                    lineStyle(1, 0xFFFFFF, 0);
                    beginFill(0xFFFFFF, 0.75);
                    drawRect(6, 6, 13, 15);
                    endFill();
                }
                spr_stop.addEventListener(MouseEvent.CLICK, function(e:Event):void
                {
                    if (_gvars.menuMusic && _gvars.menuMusic.isPlaying)
                    {
                        _gvars.menuMusic.userStop();
                    }
                });
                menuMusicControls.addChild(spr_stop);

                var spr_delete:Box = new Box(25, 25);
                spr_delete.borderAlpha = 0.75;
                spr_delete.x = 95;
                spr_delete.y = 5;
                with (spr_delete.graphics)
                {
                    lineStyle(1, 0xFFFFFF, 0);
                    beginFill(0xFFFFFF, 0.75);
                    moveTo(11, 5);
                    lineTo(14, 5);
                    lineTo(15, 7);
                    lineTo(20, 9);
                    lineTo(18, 10);
                    lineTo(17, 20);
                    lineTo(8, 20);
                    lineTo(7, 10);
                    lineTo(5, 9);
                    lineTo(9, 7);
                    lineTo(11, 5);
                    endFill();
                }
                menuMusicControls.addChild(spr_delete);
                spr_delete.addEventListener(MouseEvent.CLICK, function(e:Event):void
                {
                    if (_gvars.menuMusic)
                    {
                        _gvars.menuMusic.userStop();
                        _gvars.menuMusic = null;
                        menuMusicControls.parent.removeChild(menuMusicControls);

                        CONFIG::air
                        {
                            AirContext.deleteFile(AirContext.getAppPath(Constant.MENU_MUSIC_PATH));
                        }
                        CONFIG::not_air
                        {
                            LocalStore.setVariable("menu_music_bytes", null);
                        }
                    }
                });
                this.addChild(menuMusicControls);

                // Context Menu Display song Playing
                var musicContextMenu:ContextMenu = new ContextMenu();
                var musicContextMenuPlaying:ContextMenuItem = new ContextMenuItem("Now Playing: " + LocalStore.getVariable("menu_music", "Unknown"), false, false);
                musicContextMenu.customItems.push(musicContextMenuPlaying);
                menuMusicControls.contextMenu = musicContextMenu;

            }
            if (!contains(menuMusicControls))
                addChild(menuMusicControls);
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

                case MENU_TOKENS:
                    if (_MenuTokens == null || useNew)
                        _MenuTokens = new MenuTokens(this);
                    panel = _MenuTokens;
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
                _gvars.gameMain.addAlert(_lang.string("skill_rank_update_fail"), 90, Alert.RED);
                if (_gvars.gameMain.activePanel is MainMenu)
                {
                    rankUpdateThrobber.stop();
                    rankUpdateThrobber.visible = false;
                }
            }
        }
    }
}
