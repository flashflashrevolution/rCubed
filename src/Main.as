/**
 * @author Jonathan (Velocity)
 */

package
{
    CONFIG::release
    {
        import flash.system.Security;
    }

    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.BoxButton;
    import classes.Language;
    import classes.Noteskins;
    import classes.Playlist;
    import classes.Site;
    import classes.SongPreview;
    import classes.Text;
    import classes.User;
    import classes.replay.Replay;
    import com.flashdynamix.utils.SWFProfiler;
    import com.flashfla.components.ProgressBar;
    import com.flashfla.utils.ObjectUtil;
    import com.flashfla.utils.SystemUtil;
    import com.greensock.TweenLite;
    import com.greensock.TweenMax;
    import com.greensock.easing.SineInOut;
    import com.greensock.plugins.AutoAlphaPlugin;
    import com.greensock.plugins.TintPlugin;
    import com.greensock.plugins.TweenPlugin;
    import flash.desktop.NativeApplication;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.system.Capabilities;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.Keyboard;
    import game.GameMenu;
    import game.GameOptions;
    import menu.MainMenu;
    import menu.MenuPanel;
    import popups.PopupContextMenu;
    import popups.PopupHelp;
    import popups.PopupOptions;
    import popups.PopupReplayHistory;

    CONFIG::vsync
    {
        import flash.events.VsyncStateChangeAvailabilityEvent;
    }

    public class Main extends MenuPanel
    {
        public static const GAME_WIDTH:int = 780;
        public static const GAME_HEIGHT:int = 480;
        public static const GAME_UPDATE_PANEL:String = "GameAirUpdatePanel";
        public static const GAME_LOGIN_PANEL:String = "GameLoginPanel";
        public static const GAME_MENU_PANEL:String = "GameMenuPanel";
        public static const GAME_PLAY_PANEL:String = "GamePlayPanel";
        public static const POPUP_OPTIONS:String = "PopupOptions";
        public static const POPUP_HELP:String = "PopupHelp";
        public static const POPUP_REPLAY_HISTORY:String = "PopupReplayHistory";
        public static const EVENT_PANEL_SWITCHED:String = "maineventswitched";

        public var _gvars:GlobalVariables = GlobalVariables.instance;
        public var _site:Site = Site.instance;
        public var _playlist:Playlist = Playlist.instance;
        public var _lang:Language = Language.instance;
        //public var _friends:Friends = Friends.instance;
        public var _noteskins:Noteskins = Noteskins.instance;

        public var loadTimer:int = 0;
        public var preloader:ProgressBar;
        public var loadScripts:uint = 0;
        public var loadTotal:uint;
        public var isLoginLoad:Boolean = false;
        public var loadComplete:Boolean = false;
        public var retryLoadButton:BoxButton;
        public var disablePopups:Boolean = false;

        private var activeAlert:Alert;
        private var alertsQueue:Array = [];
        private var popupQueue:Array = [];
        private var lastPanel:MenuPanel;
        public var activePanel:MenuPanel;

        public var activePanelName:String;

        public var loadStatus:TextField;
        public var epilepsyWarning:TextField;

        public var ver:Text;
        public var bg:GameBackgroundColor

        ///- Constructor
        public function Main():void
        {
            super(this);

            //- Set GlobalVariables Stage
            _gvars.gameMain = this;

            SystemUtil.init();

            if (stage)
            {
                //- Set up vSync
                CONFIG::vsync
                {
                    stage.addEventListener(VsyncStateChangeAvailabilityEvent.VSYNC_STATE_CHANGE_AVAILABILITY, onVsyncStateChangeAvailability);
                }

                gameInit();
            }
            else
            {
                this.addEventListener(Event.ADDED_TO_STAGE, gameInit);
            }
        }

        CONFIG::vsync
        public function onVsyncStateChangeAvailability(event:VsyncStateChangeAvailabilityEvent):void
        {
            if (event.available)
            {
                stage.vsyncEnabled = _gvars.air_useVSync;
            }
            else
            {
                stage.vsyncEnabled = true;
            }
        }

        private function gameInit(e:Event = null):void
        {
            //- Remove Stage Listener
            if (e != null)
            {
                this.removeEventListener(Event.ADDED_TO_STAGE, gameInit);
            }

            //- Setup Tween Override mode
            TweenPlugin.activate([TintPlugin, AutoAlphaPlugin]);
            TweenLite.defaultOverwrite = "all";
            stage.stageFocusRect = false;

            //- Load Air Items
            _gvars.loadAirOptions();
            stage.nativeWindow.title = Constant.AIR_WINDOW_TITLE;
            NativeApplication.nativeApplication.addEventListener(Event.EXITING, _gvars.onNativeProcessClose);

            //- Load Menu Music
            _gvars.loadMenuMusic();

            //- Set Vars
            _gvars.flashvars = stage.loaderInfo.parameters;

            //- Background
            this.stage.color = 0x000000;

            bg = new GameBackgroundColor();
            this.addChild(bg);

            epilepsyWarning = new TextField();
            epilepsyWarning.x = 10;
            epilepsyWarning.y = stage.stageHeight * 0.15;
            epilepsyWarning.width = GAME_WIDTH - 20;
            epilepsyWarning.selectable = false;
            epilepsyWarning.embedFonts = true;
            epilepsyWarning.antiAliasType = AntiAliasType.ADVANCED;
            epilepsyWarning.defaultTextFormat = Constant.TEXT_FORMAT_CENTER;
            epilepsyWarning.textColor = 0xFFFFFF;
            epilepsyWarning.alpha = 0.2;
            epilepsyWarning.text = "WARNING: This game may potentially trigger seizures for people with photosensitive epilepsy.\nGamer discretion is advised."
            this.addChild(epilepsyWarning);

            TweenMax.to(epilepsyWarning, 1, {alpha: 0.6, ease: SineInOut, yoyo: true, repeat: -1});

            //- Add Debug Tracking
            ver = new Text(Capabilities.version.replace(/,/g, ".") + " - Build " + CONFIG::timeStamp + " - " + Constant.AIR_VERSION);
            ver.alpha = 0.15;
            ver.x = stage.width - 5;
            ver.y = 2;
            ver.align = Text.RIGHT;
            ver.mouseEnabled = false;
            ver.cacheAsBitmap = true;
            this.addChild(ver);

            // Holidays!
            var d:Date = new Date();
            if (d.getMonth() == 0 && d.getDate() == 1)
                ver.text = "Happy New Year! - " + ver.text;
            if (d.getMonth() == 9 && d.getDate() == 31)
                ver.text = "Happy Halloween! - " + ver.text;
            if (d.getMonth() == 11 && d.getDate() == 25)
                ver.text = "Merry Christmas! - " + ver.text;
            if (d.getMonth() == 10 && d.getDate() == 6)
                ver.text = "Happy Birthday Velocity! - " + ver.text;

            // Backup Menu incase
            var cm:ContextMenu = new ContextMenu();

            //- Toggle Fullscreen
            var fscmi:ContextMenuItem = new ContextMenuItem("Show Menu");
            fscmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, toggleContextPopup);
            cm.customItems.push(fscmi);

            CONFIG::release
            {
                cm.hideBuiltInItems();
            }

            CONFIG::debug
            {
                stage.nativeWindow.x = (Capabilities.screenResolutionX - stage.nativeWindow.width) * 0.5;
                stage.nativeWindow.y = (Capabilities.screenResolutionY - stage.nativeWindow.height) * 0.5;
            }

            // Assign Menu Context
            this.contextMenu = cm;

            //- Profiler
            SWFProfiler.init(stage, this);

            //- Build Preloader
            buildPreloader();

            //- Load Game Data
            loadGameData();

            //- Flashvars
            //CONFIG::debug { _gvars.flashvars = { replay: "366743"};} //, replaySkip: "1"
            //CONFIG::debug { _gvars.flashvars = { preview_file: 2283};} //, replaySkip: "1"
            //CONFIG::debug { _gvars.flashvars = { "__forceLogin": true };} // Login, then on the second go at the login screen, press guest. This should let me test multiple users without dealing with IE. :D

            // Replay
            if (_gvars.flashvars.replay != null)
            {
                _gvars.options = new GameOptions();
                _gvars.options.replay = new Replay(_gvars.flashvars.replay, true);
                _gvars.options.loadPreview = true;
                _gvars.replayHistory.push(_gvars.options.replay);
            }

            // Song Preview
            if (_gvars.flashvars.preview_file != null)
            {
                _gvars.options = new GameOptions();
                _gvars.options.replay = new SongPreview(_gvars.flashvars.preview_file);
                _gvars.options.loadPreview = true;
                _gvars.replayHistory.push(_gvars.options.replay);
            }

            //- Key listener
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardKeyDown, false, 0, true);
            stage.focus = this.stage;

            //- No Reason
            CONFIG::debug
            {
                addAlert("Development Build - " + CONFIG::timeStamp + " - NOT FOR RELEASE", 120, Alert.RED);
            }
        }

        ///- Preloader
        public function buildPreloader():void
        {
            //- Status Display
            loadStatus = new TextField();
            loadStatus.x = 8;
            loadStatus.y = GAME_HEIGHT - ((isLoginLoad) ? 118 : 155);
            loadStatus.width = GAME_WIDTH - 20;
            loadStatus.selectable = false;
            loadStatus.embedFonts = true;
            loadStatus.antiAliasType = AntiAliasType.ADVANCED;
            loadStatus.autoSize = "left";
            loadStatus.defaultTextFormat = Constant.TEXT_FORMAT;
            this.addChild(loadStatus);

            //- Preloader Display
            preloader = new ProgressBar(GAME_WIDTH - 20, 20);
            preloader.x = 10;
            preloader.y = GAME_HEIGHT - 30;
            this.addChild(preloader);

            //- Frame Listener
            this.addEventListener(Event.ENTER_FRAME, updatePreloader);
        }

        ///- Game Data
        public function loadGameData():void
        {
            loadTotal = (!isLoginLoad) ? 5 : 3;

            _gvars.playerUser = new User(true, true);
            _gvars.activeUser = _gvars.playerUser;
            _gvars.activeUser.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            _gvars.activeUser.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);

            _site.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            _site.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
            _playlist.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            _playlist.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
            _site.load();
            _playlist.load();

            if (!isLoginLoad)
            {
                _lang.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _lang.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _noteskins.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _noteskins.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _lang.load();
                _noteskins.load();
            }

            //_friends.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            //_friends.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
            //_friends.load();

            // Update Text
            updateLoaderText();
        }

        private function gameScriptLoad(e:Event = null):void
        {
            trace("0:Loaded: " + e.target);
            e.target.removeEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            e.target.removeEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
            loadScripts++;

            // Update Text
            updateLoaderText();
        }

        private function gameScriptLoadError(e:Event = null):void
        {
            trace("0:Load Error: " + e.target);
            e.target.removeEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            e.target.removeEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);

            // Update Text
            updateLoaderText();
        }

        private function updateLoaderText():void
        {
            if (loadStatus != null)
            {
                loadStatus.htmlText = "Total: " + loadScripts + " / " + loadTotal + "\n" + "Playlist: " + getLoadText(_playlist.isLoaded(), _playlist.isError()) + "\n" + "User Data: " + getLoadText(_gvars.playerUser.isLoaded(), _gvars.playerUser.isError()) + "\n" + "Site Data: " + getLoadText(_site.isLoaded(), _site.isError()) + ((!isLoginLoad) ? ("\n" + "Noteskin Data: " + getLoadText(_noteskins.isLoaded(), _noteskins.isError()) + "\n" + "Language Data: " + getLoadText(_lang.isLoaded(), _lang.isError())) : "");
            }
        }

        private function getLoadText(isLoaded:Boolean, isError:Boolean):String
        {
            if (isError)
                return "<font color=\"#FFC4C4\">Error</font>";
            if (isLoaded)
                return "<font color=\"#C4FFCD\">Complete</font>";
            var cycle:int = 35;
            return "Loading." + ((loadTimer % cycle > cycle / 3) ? "." : "") + ((loadTimer % cycle > cycle / 1.5) ? "." : "");
        }

        ///- PreloaderHandlers
        private function updatePreloader(e:Event):void
        {
            // Update Text
            updateLoaderText();

            loadTimer++;
            preloader.update(Math.round((loadScripts / loadTotal) * 100));
            if (loadTimer >= 300 && !retryLoadButton)
            {
                retryLoadButton = new BoxButton(75, 25, "RELOAD");
                retryLoadButton.x = Main.GAME_WIDTH - 85;
                retryLoadButton.y = preloader.y - 35;
                retryLoadButton.addEventListener(MouseEvent.CLICK, e_retryClick);
                addChild(retryLoadButton);
            }

            if (preloader.isComplete)
            {
                loadComplete = true;
                if (retryLoadButton)
                {
                    removeChild(retryLoadButton);
                    retryLoadButton.removeEventListener(MouseEvent.CLICK, e_retryClick);
                    retryLoadButton = null;
                }

                CONFIG::release
                {
                    // Do Air Update Check
                    if (!Flags.VALUES[Flags.DID_AIR_UPDATE_CHECK])
                    {
                        Flags.VALUES[Flags.DID_AIR_UPDATE_CHECK] = true;
                        var airUpdateCheck:int = AirContext.serverVersionHigher(_site.data["game_r3air_version"]);
                        //addAlert(_site.data["game_r3air_version"] + " " + (airUpdateCheck == -1 ? "&gt;" : (airUpdateCheck == 1 ? "&lt;" : "==")) + " " + Constant.AIR_VERSION, 240);
                        if (airUpdateCheck == -1)
                        {
                            loadScripts = 0;
                            preloader.remove();
                            removeChild(loadStatus);
                            removeChild(epilepsyWarning);
                            this.removeEventListener(Event.ENTER_FRAME, updatePreloader);

                            // Switch to game
                            switchTo(GAME_UPDATE_PANEL);
                            return;
                        }
                        else
                        {
                            LocalStore.deleteVariable("air_update_checks");
                        }
                    }
                }

                if ((_gvars.flashvars.replay != null || _gvars.flashvars.preview_file != null) && _gvars.options && _gvars.options.replay)
                {
                    if (_gvars.options.replay is SongPreview && !_gvars.options.replay.isLoaded)
                    {
                        (_gvars.options.replay as SongPreview).setupSongPreview();
                        return;
                    }
                    if (_gvars.options.replay.isLoaded)
                    {
                        loadScripts = 0;
                        preloader.remove();

                        if (this.contains(loadStatus))
                            removeChild(loadStatus);
                        if (this.contains(epilepsyWarning))
                            removeChild(epilepsyWarning);

                        this.removeEventListener(Event.ENTER_FRAME, updatePreloader);

                        // Setup Vars
                        _gvars.songQueue.push(Playlist.instance.getSong(_gvars.options.replay.level));

                        // Switch to game
                        switchTo(GAME_PLAY_PANEL);
                    }
                    return;
                }
                else
                {
                    loadScripts = 0;
                    preloader.remove();
                    removeChild(loadStatus);
                    this.removeEventListener(Event.ENTER_FRAME, updatePreloader);
                    _playlist.updateSongAccess();
                    _playlist.updatePublicSongsCount();
                    _gvars.loadUserSongData();
                    switchTo(_gvars.activeUser.isGuest || _gvars.flashvars["__forceLogin"] ? GAME_LOGIN_PANEL : GAME_MENU_PANEL);
                }
            }
        }

        private function e_retryClick(e:Event):void
        {
            addAlert("Reloading incomplete scripts...");
            if (!_playlist.isLoaded())
            {
                _playlist.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _playlist.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _playlist.load();
            }
            if (!_site.isLoaded())
            {
                _site.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _site.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _site.load();
            }
            if (!_gvars.activeUser.isLoaded())
            {
                _gvars.activeUser.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _gvars.activeUser.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _gvars.activeUser.load();
            }
            /*
               if (!_friends.isLoaded()) {
               _friends.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
               _friends.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
               _friends.load();
               }
             */
            if (!isLoginLoad)
            {
                if (!_noteskins.isLoaded())
                {
                    _noteskins.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                    _noteskins.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                    _noteskins.load();
                }
                if (!_lang.isLoaded())
                {
                    _lang.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                    _lang.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                    _lang.load();
                }
            }

            // Update Text
            updateLoaderText();
        }

        ///- Panels
        override public function switchTo(_panel:String, useNew:Boolean = false):Boolean
        {
            var isFound:Boolean = false;
            var nextPanel:MenuPanel;

            if (_panel == "none")
            {
                // Make background force displayed.
                bg.visible = true;
                ver.visible = true;

                //- Remove last panel if exist
                if (activePanel != null)
                    TweenLite.to(activePanel, 0.5, {alpha: 0, onComplete: removeLastPanel, onCompleteParams: [activePanel]});

                // Only load data that depend on the global session token after logging in
                this.isLoginLoad = true;

                //- Build Preloader
                buildPreloader();

                //- Load Game Data
                loadGameData();

                return true;
            }

            //- Add Requested Panel
            switch (_panel)
            {
                case GAME_UPDATE_PANEL:
                    nextPanel = new AirUpdater(this);
                    isFound = true;
                    break;

                case GAME_LOGIN_PANEL:
                    nextPanel = new LoginMenu(this);
                    isFound = true;
                    break;

                case GAME_MENU_PANEL:
                    nextPanel = new MainMenu(this);
                    isFound = true;

                    if (this.contains(epilepsyWarning))
                    {
                        removeChild(epilepsyWarning);
                    }

                    break;

                case GAME_PLAY_PANEL:
                    nextPanel = new GameMenu(this);
                    isFound = true;
                    break;
            }

            // Show Background
            if (_panel != GAME_PLAY_PANEL)
            {
                bg.visible = true;
                ver.visible = true;
            }

            if (isFound)
            {
                //- Remove last panel if exist
                if (activePanel != null)
                {
                    TweenLite.to(activePanel, 0.5, {alpha: 0, onComplete: removeLastPanel, onCompleteParams: [activePanel]});
                    activePanel.mouseEnabled = false;
                    activePanel.mouseChildren = false;
                }

                activePanel = nextPanel;
                activePanel.alpha = 0;

                this.addChildAt(activePanel, 2);
                if (!activePanel.hasInit)
                {
                    activePanel.init();
                    activePanel.hasInit = true;
                }
                activePanel.stageAdd();
                TweenLite.to(activePanel, 0.5, {alpha: 1});
            }

            if (isFound)
            {
                this.activePanelName = _panel;
                dispatchEvent(new Event(EVENT_PANEL_SWITCHED));
            }

            return isFound;
        }

        private function removeLastPanel(removePanel:MenuPanel):void
        {
            if (removePanel)
            {
                removePanel.dispose();
                if (this.contains(removePanel))
                {
                    this.removeChild(removePanel);
                }
                removePanel = null;
            }
            SystemUtil.gc();
        }

        ///- Popupa
        override public function addPopup(_panel:*, newLayer:Boolean = false):void
        {
            if (newLayer && _panel is MenuPanel)
            {
                removeChildClass(ObjectUtil.getClass(_panel));
                this.addChild(_panel);
                if (!_panel.hasInit)
                {
                    _panel.init();
                    _panel.hasInit = true;
                }
                _panel.stageAdd();
            }
            else
            {
                if (current_popup)
                {
                    removePopup();
                }

                //- Add Requested Popop
                if (_panel is String)
                {
                    switch (_panel)
                    {
                        case POPUP_OPTIONS:
                            current_popup = new PopupOptions(this);
                            break;
                        case POPUP_HELP:
                            current_popup = new PopupHelp(this);
                            break;
                        case POPUP_REPLAY_HISTORY:
                            current_popup = new PopupReplayHistory(this);
                            break;
                    }
                }
                else if (_panel is MenuPanel)
                {
                    current_popup = _panel;
                }
                this.addChildAt(current_popup, 3);
                if (!current_popup.hasInit)
                {
                    current_popup.init();
                    current_popup.hasInit = true;
                }
                current_popup.stageAdd();
            }
        }

        public function addPopupQueue(_panel:*, newLayer:Boolean = false):void
        {
            popupQueue.push({"panel": _panel, "layer": newLayer});
        }

        public function displayPopupQueue():void
        {
            if (popupQueue.length > 0)
            {
                var pop:Object = popupQueue.shift();
                addPopup(pop["panel"], pop["layer"]);
            }
        }

        override public function removePopup():void
        {
            if (current_popup)
            {
                current_popup.stageRemove();
                if (this.contains(current_popup))
                    this.removeChild(current_popup);
                current_popup = null;
            }
            stage.focus = this.stage;
            SystemUtil.gc();
            displayPopupQueue();
        }

        private function removeChildClass(clazz:Class):void
        {
            for (var i:int = 0; i < this.numChildren; i++)
            {
                if (this.getChildAt(i) is clazz)
                {
                    this.removeChildAt(i);
                    break;
                }
            }
        }

        ///- Game Alerts
        public function addAlert(message:String, age:int = 120, color:uint = 0x000000):void
        {
            if (activeAlert == null)
            {
                activeAlert = new Alert(message, age, color);
                activeAlert.x = GAME_WIDTH - activeAlert.width - 5;
                activeAlert.y = GAME_HEIGHT - activeAlert.height - 5;
                this.addChild(activeAlert);

                this.addEventListener(Event.ENTER_FRAME, alertOnFrame);
            }
            else
            {
                alertsQueue.push({ms: message, ag: age, col: color});
            }
        }

        private function alertOnFrame(e:Event):void
        {
            // Progress Active Alert
            if (activeAlert)
            {
                activeAlert.progress();
                if (activeAlert.time > activeAlert.age)
                {
                    this.removeChild(activeAlert);
                    activeAlert = null;
                    this.removeEventListener(Event.ENTER_FRAME, alertOnFrame);
                }
            }

            // Add new alert if the old alert is finished
            if (activeAlert == null && alertsQueue.length >= 1)
            {
                var newAlert:Object = alertsQueue.splice(0, 1)[0];
                addAlert(newAlert.ms, newAlert.ag, newAlert.col);
            }

            // General cleanup in case
            if (activeAlert == null && alertsQueue.length == 0)
            {
                this.removeEventListener(Event.ENTER_FRAME, alertOnFrame);
            }
        }

        ///- Fullscreen Handling
        private function toggleContextPopup(e:Event = null):void
        {
            if (current_popup is PopupContextMenu)
            {
                removePopup();
            }
            else
            {
                if (!disablePopups)
                {
                    addPopup(new PopupContextMenu(this));
                }
            }
        }

        ///- Key Handling
        private function keyboardKeyDown(e:KeyboardEvent):void
        {
            var keyCode:int = e.keyCode;
            if (loadComplete && !disablePopups)
            {
                // Options
                if (keyCode == _gvars.playerUser.keyOptions && (stage.focus == null || !(stage.focus is TextField)))
                {
                    if (current_popup is PopupOptions)
                    {
                        removePopup();
                    }
                    else
                    {
                        addPopup(Main.POPUP_OPTIONS);
                    }
                }

                // Help Menu
                else if (keyCode == Keyboard.F1)
                {
                    if (current_popup is PopupHelp)
                    {
                        removePopup();
                    }
                    else
                    {
                        addPopup(Main.POPUP_HELP);
                    }
                }

                // Replay History
                else if (keyCode == Keyboard.F2)
                {
                    if (current_popup is PopupReplayHistory)
                    {
                        removePopup();
                    }
                    else
                    {
                        addPopup(Main.POPUP_REPLAY_HISTORY);
                    }
                }
            }
        }
    }
}
