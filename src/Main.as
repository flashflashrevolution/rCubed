/**
 * @author Jonathan (Velocity)
 */

package
{
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.Language;
    import classes.Noteskins;
    import classes.Playlist;
    import classes.Site;
    import classes.User;
    import classes.ui.BoxButton;
    import classes.ui.ProgressBar;
    import classes.ui.Text;
    import com.flashdynamix.utils.SWFProfiler;
    import com.flashfla.utils.ObjectUtil;
    import com.flashfla.utils.SystemUtil;
    import com.greensock.TweenLite;
    import com.greensock.TweenMax;
    import com.greensock.easing.SineInOut;
    import com.greensock.plugins.AutoAlphaPlugin;
    import com.greensock.plugins.TintPlugin;
    import com.greensock.plugins.TweenPlugin;
    import flash.desktop.NativeApplication;
    import flash.desktop.NativeProcess;
    import flash.desktop.NativeProcessStartupInfo;
    import flash.display.NativeWindow;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.NativeWindowBoundsEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.filesystem.File;
    import flash.system.Capabilities;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.Keyboard;
    import game.GameMenu;
    import menu.MainMenu;
    import menu.MenuPanel;
    import popups.PopupContextMenu;
    import popups.PopupHelp;
    import popups.replays.ReplayHistoryWindow;
    import popups.settings.SettingsWindow;

    public class Main extends MenuPanel
    {
        public static const GAME_WIDTH:int = 780;
        public static const GAME_HEIGHT:int = 480;
        public static var VSYNC_SUPPORT:Boolean = false;
        public static var window:NativeWindow;

        public static const GAME_LOGIN_PANEL:String = "GameLoginPanel";
        public static const GAME_MENU_PANEL:String = "GameMenuPanel";
        public static const GAME_PLAY_PANEL:String = "GamePlayPanel";
        public static const POPUP_OPTIONS:String = "PopupOptions";
        public static const POPUP_HELP:String = "PopupHelp";
        public static const POPUP_REPLAY_HISTORY:String = "PopupReplayHistory";
        public static const EVENT_PANEL_SWITCHED:String = "MainEventSwitched";

        public static var WINDOW_WIDTH_EXTRA:Number = 0;
        public static var WINDOW_HEIGHT_EXTRA:Number = 0;

        public var _lang:Language = Language.instance;
        public var _gvars:GlobalVariables = GlobalVariables.instance;
        public var _site:Site = Site.instance;
        public var _playlist:Playlist = Playlist.instance;
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
        public var ignoreWindowChanges:Boolean = false;

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

            if (stage)
                gameInit();
            else
                this.addEventListener(Event.ADDED_TO_STAGE, gameInit);
        }

        private function gameInit(e:Event = null):void
        {
            //- Remove Stage Listener
            if (e != null)
            {
                this.removeEventListener(Event.ADDED_TO_STAGE, gameInit);
            }

            //- Static Class Init
            Logger.init();
            AirContext.initFolders();
            LocalOptions.init();
            Alert.init(stage);

            //- Setup Tween Override mode
            TweenPlugin.activate([TintPlugin, AutoAlphaPlugin]);
            TweenLite.defaultOverwrite = "all";
            stage.stageFocusRect = false;

            //- Load Air Items
            _gvars.loadAirOptions();

            //- Window Options
            VSYNC_SUPPORT = stage.hasOwnProperty("vsyncEnabled");
            window = stage.nativeWindow;
            window.addEventListener(Event.CLOSING, e_onNativeWindowClosing);
            NativeApplication.nativeApplication.addEventListener(Event.EXITING, e_onNativeShutdown);
            window.addEventListener(NativeWindowBoundsEvent.MOVE, e_onNativeWindowPropertyChange, false, 1);
            window.addEventListener(NativeWindowBoundsEvent.RESIZE, e_onNativeWindowPropertyChange, false, 1);
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, e_uncaughtErrorHandler);
            stage.addEventListener("vSyncStateChangeAvailability", e_onVsyncStateChangeAvailability); // Lacking proper event class due to SDK limitations in Air 26.

            window.title = Constant.AIR_WINDOW_TITLE;

            WINDOW_WIDTH_EXTRA = window.width - GAME_WIDTH;
            WINDOW_HEIGHT_EXTRA = window.height - GAME_HEIGHT;

            ignoreWindowChanges = true;
            if (_gvars.air_saveWindowPosition)
            {
                window.x = _gvars.air_windowProperties.x;
                window.y = _gvars.air_windowProperties.y;
            }
            if (_gvars.air_saveWindowSize)
            {
                window.width = Math.max(100, _gvars.air_windowProperties.width + WINDOW_WIDTH_EXTRA);
                window.height = Math.max(100, _gvars.air_windowProperties.height + WINDOW_HEIGHT_EXTRA);
            }
            ignoreWindowChanges = false;

            //- Load Menu Music
            _gvars.loadMenuMusic();

            //- Background
            this.stage.color = 0x000000;

            bg = new GameBackgroundColor();
            this.addChild(bg);

            //- Epilepsy Warning
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
            ver = new Text(this, stage.width - 5, 2, Capabilities.version.replace(/,/g, ".") + " - Build " + CONFIG::timeStamp + " - " + Constant.AIR_VERSION);
            ver.alpha = 0.15;
            ver.align = Text.RIGHT;
            ver.mouseEnabled = false;
            ver.cacheAsBitmap = true;

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

            //- Build global right-click context menu
            buildContextMenu();

            //- Build Preloader
            buildPreloader();

            //- Load Game Data
            loadSiteData();

            //- Key listener
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardKeyDown, false, 0, true);
            stage.focus = this.stage;

            //- No Reason
            CONFIG::debug
            {
                Alert.add("Development Build - " + CONFIG::timeStamp + " - NOT FOR RELEASE", 120, Alert.RED);
            }
        }

        public function buildContextMenu():void
        {
            //- Backup Menu incase
            var cm:ContextMenu = new ContextMenu();

            //- Toggle Fullscreen
            var fscmi:ContextMenuItem = new ContextMenuItem(_lang.stringSimple("show_menu"));
            fscmi.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, toggleContextPopup);
            cm.customItems.push(fscmi);

            //- Assign Menu Context
            this.contextMenu = cm;

            //- Profiler
            SWFProfiler.init(stage, this);

            CONFIG::release
            {
                cm.hideBuiltInItems();
            }
        }

        ///- Window Methods
        private function e_onNativeShutdown(e:Event):void
        {
            Logger.destroy();
            LocalOptions.flush();
            _gvars.onNativeProcessClose(e);
        }

        private function e_onNativeWindowClosing(e:Event):void
        {
            _gvars.air_windowProperties["width"] = window.width - Main.WINDOW_WIDTH_EXTRA;
            _gvars.air_windowProperties["height"] = window.height - Main.WINDOW_HEIGHT_EXTRA;
            _gvars.air_windowProperties["x"] = window.x;
            _gvars.air_windowProperties["y"] = window.y;
            LocalOptions.setVariable("window_properties", _gvars.air_windowProperties);
        }

        private function e_onNativeWindowPropertyChange(e:NativeWindowBoundsEvent):void
        {
            if (ignoreWindowChanges)
                return;

            _gvars.air_windowProperties["width"] = e.afterBounds.width - Main.WINDOW_WIDTH_EXTRA;
            _gvars.air_windowProperties["height"] = e.afterBounds.height - Main.WINDOW_HEIGHT_EXTRA;
            _gvars.air_windowProperties["x"] = e.afterBounds.x;
            _gvars.air_windowProperties["y"] = e.afterBounds.y;
        }

        private function e_uncaughtErrorHandler(e:UncaughtErrorEvent):void
        {
            Logger.enableLogger();
            Logger.error("UNCAUGHT_ERROR", e.error);
            Logger.info("INFO", "If possible, please submit this crash to the developers.");
            Alert.add("A fatal error has occured. You should restart the game.", 7200, Alert.RED);
        }

        /**
         * Called when the vsync state can be set.
         * This is even called in Air 26, when the actual event doesn't exist yet in the SDK
         * but is dispatched if you hardcode the event name.
         */
        public function e_onVsyncStateChangeAvailability(event:*):void
        {
            if (VSYNC_SUPPORT)
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
            loadStatus.text = "\n\n\n\n\nConnecting...";
            this.addChild(loadStatus);

            //- Preloader Display
            preloader = new ProgressBar(this, 10, GAME_HEIGHT - 30, GAME_WIDTH - 20, 20);

            //- Frame Listener
            this.addEventListener(Event.ENTER_FRAME, updatePreloader);
        }

        ///- Game Data
        private static var LOAD_ATTEMPTS:int = 0;

        public function loadSiteData():void
        {
            if (isLoginLoad)
            {
                loadGameData(false);
                return;
            }

            if (LOAD_ATTEMPTS < 2)
            {
                _site.addEventListener(GlobalVariables.LOAD_COMPLETE, gameDataScriptLoad);
                _site.addEventListener(GlobalVariables.LOAD_ERROR, gameDataScriptLoadError);
                _site.load();
                LOAD_ATTEMPTS++;
            }
            else
            {
                loadStatus.text = "\n\n\n\n\nUnable to connect to the server, please check your internet connection.";
            }
        }

        private function gameDataScriptLoad(e:Event = null):void
        {
            e.target.removeEventListener(GlobalVariables.LOAD_COMPLETE, gameDataScriptLoad);
            e.target.removeEventListener(GlobalVariables.LOAD_ERROR, gameDataScriptLoadError);
            loadScripts++;

            loadGameData();
        }

        private function gameDataScriptLoadError(e:Event = null):void
        {
            e.target.removeEventListener(GlobalVariables.LOAD_COMPLETE, gameDataScriptLoad);
            e.target.removeEventListener(GlobalVariables.LOAD_ERROR, gameDataScriptLoadError);

            // Fallback to http
            if (LOAD_ATTEMPTS == 1)
                URLs.protocol = "http";

            loadSiteData();
        }

        public function loadGameData(skipSite:Boolean = true):void
        {
            loadTotal = (!isLoginLoad) ? 5 : 3;

            _gvars.playerUser = new User(true, true);
            _gvars.playerUser.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            _gvars.playerUser.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
            _gvars.activeUser = _gvars.playerUser;

            _playlist.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            _playlist.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
            _playlist.load();

            if (!skipSite)
            {
                _site.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _site.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _site.load();
            }

            if (!isLoginLoad)
            {
                _lang.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _lang.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _noteskins.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _noteskins.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _lang.load();
                _noteskins.load();
            }
        }

        private function gameScriptLoad(e:Event = null):void
        {
            e.target.removeEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            e.target.removeEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
            loadScripts++;
        }

        private function gameScriptLoadError(e:Event = null):void
        {
            e.target.removeEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
            e.target.removeEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
        }

        private function updateLoaderText():void
        {
            if (loadStatus != null && _gvars.playerUser != null)
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
            preloader.update(loadScripts / loadTotal);
            if (loadTimer >= 300 && !retryLoadButton)
            {
                retryLoadButton = new BoxButton(this, Main.GAME_WIDTH - 85, preloader.y - 35, 75, 25, "RELOAD", 12, e_retryClick);
            }

            if (preloader.isComplete)
            {
                loadComplete = true;
                if (retryLoadButton && this.contains(retryLoadButton))
                {
                    removeChild(retryLoadButton);
                    retryLoadButton.dispose();
                }

                buildContextMenu();

                CONFIG::updater
                {
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
                }

                loadScripts = 0;
                preloader.remove();
                removeChild(loadStatus);
                this.removeEventListener(Event.ENTER_FRAME, updatePreloader);
                _playlist.updateSongAccess();
                _playlist.updatePublicSongsCount();
                _gvars.loadUserSongData();
                _gvars.playerUser.getUserSkillRatingData();
                switchTo(_gvars.playerUser.isGuest ? GAME_LOGIN_PANEL : GAME_MENU_PANEL);
            }
        }

        private function e_retryClick(e:Event):void
        {
            Alert.add(_lang.string("reload_scripts"));

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
            if (!_gvars.playerUser || !_gvars.playerUser.isLoaded())
            {
                _gvars.playerUser = new User(true, true);
                _gvars.playerUser.addEventListener(GlobalVariables.LOAD_COMPLETE, gameScriptLoad);
                _gvars.playerUser.addEventListener(GlobalVariables.LOAD_ERROR, gameScriptLoadError);
                _gvars.playerUser.load();
                _gvars.activeUser = _gvars.playerUser;
            }

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
        override public function switchTo(_panel:String):Boolean
        {
            var isFound:Boolean = false;
            var nextPanel:MenuPanel;

            if (_panel == "none")
            {
                // Make background force displayed.
                bg.updateDisplay();
                ver.visible = true;

                //- Remove last panel if exist
                if (activePanel != null)
                {
                    activePanel.stageRemove();
                    TweenLite.to(activePanel, 0.5, {alpha: 0, onComplete: removeLastPanel, onCompleteParams: [activePanel]});
                }

                // Only load data that depend on the global session token after logging in
                this.isLoginLoad = true;

                //- Build Preloader
                buildPreloader();

                //- Load Game Data
                loadGameData(false);

                return true;
            }

            //- Add Requested Panel
            switch (_panel)
            {
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
                if (removePanel.stage != null)
                {
                    removePanel.stageRemove();
                    removePanel.parent.removeChild(removePanel);
                }
                removePanel.dispose();
                removePanel = null;
            }
            SystemUtil.gc();
        }

        ///- Popups
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
                            current_popup = new SettingsWindow(this);
                            break;
                        case POPUP_HELP:
                            current_popup = new PopupHelp(this);
                            break;
                        case POPUP_REPLAY_HISTORY:
                            current_popup = new ReplayHistoryWindow(this);
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
            if (current_popup != null)
                return;

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
            if (Flags.VALUES[Flags.ENABLE_GLOBAL_POPUPS])
            {
                // Options
                if (keyCode == _gvars.playerUser.keyOptions && (stage.focus == null || !(stage.focus is TextField)))
                {
                    if (current_popup is SettingsWindow)
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
                    if (current_popup is ReplayHistoryWindow)
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

        public function restartApplication():void
        {
            var applicationDescriptor:XML = NativeApplication.nativeApplication.applicationDescriptor;
            var xmlns:Namespace = new Namespace(applicationDescriptor.namespace());
            var applicationName:String = applicationDescriptor.xmlns::filename;

            var applicationExecutable:File;

            if (Capabilities.os.indexOf("Win") > -1)
                applicationExecutable = new File(File.applicationDirectory.nativePath + "/" + applicationName + ".exe");
            else if (Capabilities.os.indexOf("Mac") > -1)
                applicationExecutable = new File(File.applicationDirectory.nativePath.replace("Resources", "MacOS/" + applicationName));

            if (!applicationExecutable || !applicationExecutable.exists)
                return;

            // Handle Shutdown
            NativeApplication.nativeApplication.removeEventListener(Event.EXITING, e_onNativeShutdown);
            e_onNativeShutdown(null);

            // Start New
            var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
            var nativeProcess:NativeProcess = new NativeProcess();
            nativeProcessStartupInfo.executable = applicationExecutable;
            nativeProcess.start(nativeProcessStartupInfo);

            // Exit Current
            NativeApplication.nativeApplication.exit();
        }
    }
}
