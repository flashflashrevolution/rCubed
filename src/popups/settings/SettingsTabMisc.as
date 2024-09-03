package popups.settings
{
    import arc.ArcGlobals;
    import classes.Alert;
    import classes.Language;
    import classes.Playlist;
    import classes.chart.parse.ChartFFRLegacy;
    import classes.ui.BoxButton;
    import classes.ui.BoxCheck;
    import classes.ui.PromptInput;
    import classes.ui.Text;
    import classes.ui.ValidatedText;
    import com.bit101.components.ComboBox;
    import com.flashfla.utils.sprintf;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.NativeWindowBoundsEvent;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import flash.system.Capabilities;
    import menu.MainMenu;

    public class SettingsTabMisc extends SettingsTabBase
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _playlist:Playlist = Playlist.instance;

        private var optionGameLanguages:Array;
        private var languageCombo:ComboBox;
        private var languageComboIgnore:Boolean;

        private var useCacheCheckbox:BoxCheck;
        private var autoSaveLocalCheckbox:BoxCheck;
        private var useVSyncCheckbox:BoxCheck;
        private var useWebsocketCheckbox:BoxCheck;
        private var openWebsocketOverlay:BoxButton;

        private var engineCombo:ComboBox;
        private var engineDefaultCombo:ComboBox;
        private var engineComboIgnore:Boolean;
        private var optionFPS:ValidatedText;

        private var windowWidthBox:ValidatedText;
        private var windowHeightBox:ValidatedText;
        private var windowSizeSet:BoxButton;
        private var windowSizeReset:BoxButton;
        private var windowSaveSizeCheck:BoxCheck;
        private var windowXBox:ValidatedText;
        private var windowYBox:ValidatedText;
        private var windowPositionSet:BoxButton;
        private var windowPositionReset:BoxButton;
        private var windowSavePositionCheck:BoxCheck;

        public function SettingsTabMisc(settingsWindow:SettingsWindow):void
        {
            super(settingsWindow);
        }

        override public function get name():String
        {
            return "misc";
        }

        override public function openTab():void
        {
            Main.window.addEventListener(NativeWindowBoundsEvent.MOVE, e_windowPropertyChange);
            Main.window.addEventListener(NativeWindowBoundsEvent.RESIZE, e_windowPropertyChange);

            container.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            container.graphics.moveTo(295, 15);
            container.graphics.lineTo(295, 405);

            var i:int;
            var xOff:int = 15;
            var yOff:int = 15;

            /// Col 1
            //- Game Languages
            optionGameLanguages = [];
            var gameLanguageLabel:Text = new Text(container, xOff, yOff, _lang.string("options_game_language"));
            yOff += 20;

            var selectedLanguage:String = "";
            for (var id:String in _lang.indexed)
            {
                var lang:String = _lang.indexed[id];
                var lang_name:String = _lang.string2Simple("_real_name", lang) + (_lang.data[lang]['_en_name'] != _lang.data[lang]['_real_name'] ? (' / ' + _lang.string2Simple("_en_name", lang)) : '');
                optionGameLanguages.push({"label": lang_name, "data": lang});
                if (lang == _gvars.activeUser.language)
                {
                    selectedLanguage = lang_name;
                }
            }

            languageCombo = new ComboBox(container, xOff, yOff, selectedLanguage, optionGameLanguages);
            languageCombo.x = xOff;
            languageCombo.y = yOff;
            languageCombo.setSize(200, 22);
            languageCombo.openPosition = ComboBox.BOTTOM;
            languageCombo.fontSize = 11;
            languageCombo.addEventListener(Event.SELECT, languageSelect);
            setLanguage();
            yOff += 30;

            yOff += drawSeperator(container, xOff, 250, yOff, 0, 0);

            new Text(container, xOff + 23, yOff, _lang.string("air_options_save_local_replays"));
            autoSaveLocalCheckbox = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            yOff += 30;

            new Text(container, xOff + 23, yOff, _lang.string("air_options_use_cache"));
            useCacheCheckbox = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            yOff += 30;

            new Text(container, xOff + 23, yOff, _lang.string("air_options_use_websockets"));
            useWebsocketCheckbox = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            useWebsocketCheckbox.addEventListener(MouseEvent.MOUSE_OVER, e_websocketMouseOver, false, 0, true);
            yOff += 30;

            // https://github.com/flashflashrevolution/web-stream-overlay
            openWebsocketOverlay = new BoxButton(container, xOff, yOff, 200, 27, _lang.string("options_overlay_instructions"), 12, clickHandler);
            yOff += 30;

            /// Col 2
            xOff = 330;
            yOff = 15;

            // Game Engine
            new Text(container, xOff, yOff, _lang.string("options_game_engine"));
            yOff += 20;

            engineCombo = new ComboBox(container, xOff, yOff);
            engineCombo.setSize(200, 22);
            engineCombo.openPosition = ComboBox.BOTTOM;
            engineCombo.fontSize = 11;
            engineCombo.addEventListener(Event.SELECT, engineSelect);
            yOff += 30;

            // Default Game Engine
            new Text(container, xOff, yOff, _lang.string("options_default_game_engine"));
            yOff += 20;

            engineDefaultCombo = new ComboBox(container, xOff, yOff);
            engineDefaultCombo.setSize(200, 22);
            engineDefaultCombo.openPosition = ComboBox.BOTTOM;
            engineDefaultCombo.fontSize = 11;
            engineDefaultCombo.addEventListener(Event.SELECT, engineDefaultSelect);
            container.addChild(engineDefaultCombo);
            engineRefresh();
            yOff += 30;

            yOff += drawSeperator(container, xOff, 250, yOff, 0, 0);

            // Engine Framerate
            new Text(container, xOff, yOff, _lang.string("options_framerate"));
            yOff += 20;

            optionFPS = new ValidatedText(container, xOff + 3, yOff + 3, 120, 20, ValidatedText.R_INT_P, changeHandler);

            new Text(container, xOff + 163, yOff + 4, _lang.string("air_options_use_vsync"));
            useVSyncCheckbox = new BoxCheck(container, xOff + 143, yOff + 7, clickHandler);
            if (!Main.VSYNC_SUPPORT)
            {
                useVSyncCheckbox.alpha = 0.5;
                useVSyncCheckbox.addEventListener(MouseEvent.MOUSE_OVER, e_vsyncMouseOver, false, 0, true);
            }
            yOff += 30;

            yOff += drawSeperator(container, xOff, 250, yOff, 0, 0);

            // Window Size
            new Text(container, xOff, yOff, _lang.string("air_options_window_size"));
            yOff += 20;

            windowWidthBox = new ValidatedText(container, xOff + 3, yOff + 3, 60, 20, ValidatedText.R_INT);
            new Text(container, xOff + 73, yOff + 3, "X");
            windowHeightBox = new ValidatedText(container, xOff + 93, yOff + 3, 60, 20, ValidatedText.R_INT);
            windowSizeSet = new BoxButton(container, xOff + 163, yOff + 3, 51, 21, "Set", 12, clickHandler);
            windowSizeReset = new BoxButton(container, xOff + 223, yOff + 3, 21, 21, "R", 12, clickHandler);
            yOff += 30;

            new Text(container, xOff + 23, yOff, _lang.string("air_options_save_window_size"));
            windowSaveSizeCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            yOff += 30;

            // Window Position
            new Text(container, xOff, yOff, _lang.string("air_options_window_position"));
            yOff += 20;

            windowXBox = new ValidatedText(container, xOff + 3, yOff + 3, 60, 20, ValidatedText.R_INT);
            new Text(container, xOff + 73, yOff + 3, "X");
            windowYBox = new ValidatedText(container, xOff + 93, yOff + 3, 60, 20, ValidatedText.R_INT);
            windowPositionSet = new BoxButton(container, xOff + 163, yOff + 3, 51, 21, "Set", 12, clickHandler);
            windowPositionReset = new BoxButton(container, xOff + 223, yOff + 3, 21, 21, "R", 12, clickHandler);
            yOff += 30;

            new Text(container, xOff + 23, yOff, _lang.string("air_options_save_window_position"));
            windowSavePositionCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            yOff += 30;

            setTextMaxWidth(245);
        }

        override public function closeTab():void
        {
            Main.window.removeEventListener(NativeWindowBoundsEvent.MOVE, e_windowPropertyChange);
            Main.window.removeEventListener(NativeWindowBoundsEvent.RESIZE, e_windowPropertyChange);
        }

        override public function setValues():void
        {
            // Set Framerate
            optionFPS.text = _gvars.activeUser.frameRate.toString();

            setLanguage();

            autoSaveLocalCheckbox.checked = _gvars.air_autoSaveLocalReplays;
            useCacheCheckbox.checked = _gvars.air_useLocalFileCache;
            useWebsocketCheckbox.checked = _gvars.air_useWebsockets;

            if (Main.VSYNC_SUPPORT)
                useVSyncCheckbox.checked = _gvars.air_useVSync;
            else
                useVSyncCheckbox.checked = true;

            windowWidthBox.text = _gvars.air_windowProperties.width;
            windowHeightBox.text = _gvars.air_windowProperties.height;
            windowXBox.text = _gvars.air_windowProperties.x;
            windowYBox.text = _gvars.air_windowProperties.y;

            windowSavePositionCheck.checked = _gvars.air_saveWindowPosition;
            windowSaveSizeCheck.checked = _gvars.air_saveWindowSize;
        }

        override public function clickHandler(e:MouseEvent):void
        {
            //- Auto Save Local Replays
            if (e.target == autoSaveLocalCheckbox)
            {
                e.target.checked = !e.target.checked;
                _gvars.air_autoSaveLocalReplays = !_gvars.air_autoSaveLocalReplays;
                LocalOptions.setVariable("auto_save_local_replays", _gvars.air_autoSaveLocalReplays);
            }

            //- SWF File Cache
            else if (e.target == useCacheCheckbox)
            {
                e.target.checked = !e.target.checked;
                _gvars.air_useLocalFileCache = !_gvars.air_useLocalFileCache;
                LocalOptions.setVariable("use_local_file_cache", _gvars.air_useLocalFileCache);
            }

            //- Vsync Toggle
            else if (e.target == useVSyncCheckbox)
            {
                if (Main.VSYNC_SUPPORT)
                {
                    e.target.checked = !e.target.checked;
                    _gvars.gameMain.stage.vsyncEnabled = _gvars.air_useVSync = !_gvars.air_useVSync;
                    LocalOptions.setVariable("vsync", _gvars.air_useVSync);
                }
            }

            // Use HTTP Websockets
            else if (e.target == useWebsocketCheckbox)
            {
                if (_gvars.air_useWebsockets)
                {
                    _gvars.destroyWebsocketServer();
                    _gvars.air_useWebsockets = false;
                    useWebsocketCheckbox.checked = false;
                    LocalOptions.setVariable("use_websockets", _gvars.air_useWebsockets);
                }
                else
                {
                    if (_gvars.initWebsocketServer())
                    {
                        _gvars.air_useWebsockets = true;
                        useWebsocketCheckbox.checked = true;
                        LocalOptions.setVariable("use_websockets", _gvars.air_useWebsockets);
                        e_websocketMouseOver();
                    }
                    else
                    {
                        useWebsocketCheckbox.checked = false;
                        Alert.add(_lang.string("air_options_unable_to_start_websockets"), 120, Alert.RED);
                    }
                }
            }

            // HTTP Websockets Instructions
            else if (e.target == openWebsocketOverlay)
            {
                navigateToURL(new URLRequest(Constant.WEBSOCKET_OVERLAY_URL), "_blank");
                return;
            }

            //- Window Position
            else if (e.target == windowSavePositionCheck)
            {
                e.target.checked = !e.target.checked;
                _gvars.air_saveWindowPosition = !_gvars.air_saveWindowPosition;
                LocalOptions.setVariable("save_window_position", _gvars.air_saveWindowPosition);
            }
            else if (e.target == windowPositionSet)
            {
                parent.addChild(new WindowSettingConfirm(this, _gvars.air_windowProperties));

                _gvars.air_windowProperties["x"] = windowXBox.validate(Math.round((Capabilities.screenResolutionX - Main.window.width) * 0.5));
                _gvars.air_windowProperties["y"] = windowYBox.validate(Math.round((Capabilities.screenResolutionY - Main.window.height) * 0.5));
                e_windowSetUpdate();
            }
            else if (e.target == windowPositionReset)
            {
                _gvars.air_windowProperties["x"] = Math.round((Capabilities.screenResolutionX - Main.window.width) * 0.5);
                _gvars.air_windowProperties["y"] = Math.round((Capabilities.screenResolutionY - Main.window.height) * 0.5);
                e_windowSetUpdate();
            }

            //- Window Size
            else if (e.target == windowSaveSizeCheck)
            {
                e.target.checked = !e.target.checked;
                _gvars.air_saveWindowSize = !_gvars.air_saveWindowSize;
                LocalOptions.setVariable("save_window_size", _gvars.air_saveWindowSize);
            }
            else if (e.target == windowSizeSet)
            {
                parent.addChild(new WindowSettingConfirm(this, _gvars.air_windowProperties));

                _gvars.air_windowProperties["width"] = windowWidthBox.validate(Main.GAME_WIDTH);
                _gvars.air_windowProperties["height"] = windowHeightBox.validate(Main.GAME_HEIGHT);
                e_windowSetUpdate();
            }
            else if (e.target == windowSizeReset)
            {
                _gvars.air_windowProperties["width"] = Main.GAME_WIDTH;
                _gvars.air_windowProperties["height"] = Main.GAME_HEIGHT;
                e_windowSetUpdate();
            }
        }

        override public function changeHandler(e:Event):void
        {
            if (e.target == optionFPS)
            {
                _gvars.activeUser.frameRate = optionFPS.validate(60);
                _gvars.activeUser.frameRate = Math.max(Math.min(_gvars.activeUser.frameRate, 1000), 10);
            }
        }

        private function e_windowPropertyChange(e:Event):void
        {
            windowWidthBox.text = _gvars.air_windowProperties["width"];
            windowHeightBox.text = _gvars.air_windowProperties["height"];

            windowXBox.text = _gvars.air_windowProperties["x"];
            windowYBox.text = _gvars.air_windowProperties["y"];
        }

        public function e_windowSetUpdate():void
        {
            _gvars.gameMain.ignoreWindowChanges = true;
            Main.window.x = _gvars.air_windowProperties["x"];
            Main.window.y = _gvars.air_windowProperties["y"];
            Main.window.width = _gvars.air_windowProperties["width"] + Main.WINDOW_WIDTH_EXTRA;
            Main.window.height = _gvars.air_windowProperties["height"] + Main.WINDOW_HEIGHT_EXTRA;
            _gvars.gameMain.ignoreWindowChanges = false;
        }

        private function e_websocketMouseOver(e:Event = null):void
        {
            if (_gvars.air_useWebsockets)
            {
                var activePort:uint = _gvars.websocketPortNumber("websocket");
                if (activePort > 0)
                {
                    useWebsocketCheckbox.addEventListener(MouseEvent.MOUSE_OUT, e_websocketMouseOut);
                    displayToolTip(useWebsocketCheckbox.x, useWebsocketCheckbox.y + 22, sprintf(_lang.string("air_options_active_port"), {"port": _gvars.websocketPortNumber("websocket").toString()}));
                }
            }
        }

        private function e_websocketMouseOut(e:Event):void
        {
            useWebsocketCheckbox.removeEventListener(MouseEvent.MOUSE_OUT, e_websocketMouseOut);
            hideTooltip();
        }

        private function setLanguage():void
        {
            languageComboIgnore = true;
            languageCombo.selectedItemByData = _gvars.activeUser.language;
            languageComboIgnore = false;
        }

        private function languageSelect(e:Event):void
        {
            if (!languageComboIgnore)
            {
                _gvars.activeUser.language = e.target.selectedItem.data as String;

                _gvars.gameMain.activePanel.draw();
                _gvars.gameMain.buildContextMenu();

                if (_gvars.gameMain.activePanel is MainMenu)
                {
                    var mmpanel:MainMenu = (_gvars.gameMain.activePanel as MainMenu);
                    mmpanel.updateMenuMusicControls();
                }

                // refresh popup
                _gvars.gameMain.addPopup(Main.POPUP_OPTIONS);
            }
        }

        private function engineDefaultSelect(e:Event):void
        {
            if (!engineComboIgnore)
            {
                _avars.legacyDefaultEngine = (e.target as ComboBox).selectedItem.data;
                _avars.legacyDefaultSave();
            }
        }

        private function e_addEngine(url:String):void
        {
            ChartFFRLegacy.parseEngine(url, engineAdd);
        }

        private function engineSelect(e:Event):void
        {
            var data:Object = engineCombo.selectedItem.data;
            // Add Engine
            if (data == this)
            {
                new PromptInput(parent, _lang.string("custom_engine_url"), _lang.string("custom_engine_add_engine"), e_addEngine);
            }
            // Clears Engines
            else if (data == engineCombo)
            {
                _avars.legacyEngines = [];
                _avars.legacySave();
                engineRefresh();
            }
            // Change Engine
            else if (!engineComboIgnore && data != _avars.configLegacy)
            {
                _avars.configLegacy = data;
                _playlist.addEventListener(GlobalVariables.LOAD_COMPLETE, _playlist.engineChangeHandler);
                _playlist.addEventListener(GlobalVariables.LOAD_ERROR, _playlist.engineChangeHandler);
                _playlist.load();
            }
        }

        private function engineAdd(engine:Object):void
        {
            Alert.add(sprintf(_lang.string("custom_engine_loaded"), {"name": engine.name}), 80);
            for (var i:int = 0; i < _avars.legacyEngines.length; i++)
            {
                if (_avars.legacyEngines[i].id == engine.id)
                {
                    engine.level_ranks = _avars.legacyEngines[i].level_ranks;
                    _avars.legacyEngines[i] = engine;
                    break;
                }
            }
            if (i == _avars.legacyEngines.length)
                _avars.legacyEngines.push(engine);
            _avars.legacySave();
            engineRefresh();
        }

        private function engineRefresh():void
        {
            engineComboIgnore = true;

            // engine Playlist Select
            engineCombo.removeAll();
            engineDefaultCombo.removeAll();
            engineCombo.addItem({label: Constant.BRAND_NAME_LONG, data: null});
            engineDefaultCombo.addItem({label: Constant.BRAND_NAME_LONG, data: null});
            engineCombo.selectedIndex = 0;
            engineDefaultCombo.selectedIndex = 0;
            for each (var engine:Object in _avars.legacyEngines)
            {
                var item:Object = {label: engine.name, data: engine};
                if (!ChartFFRLegacy.validURL(engine["playlistURL"]))
                    continue;
                if (engine["config_url"] == null)
                {
                    Alert.add("Please re-add " + engine["name"] + ", missing required information.", 240, Alert.RED);
                    continue;
                }
                engineCombo.addItem(item);
                engineDefaultCombo.addItem(item);
                if (engine == _avars.configLegacy || (_avars.configLegacy && engine["id"] == _avars.configLegacy["id"]))
                    engineCombo.selectedItem = item;
                if (engine == _avars.legacyDefaultEngine || (_avars.legacyDefaultEngine && engine["id"] == _avars.legacyDefaultEngine["id"]))
                    engineDefaultCombo.selectedItem = item;
            }
            engineCombo.addItem({label: _lang.stringSimple("custom_engine_add_engine"), data: this});
            if (_avars.legacyEngines.length > 0 && engineCombo.items.length > 2)
                engineCombo.addItem({label: _lang.stringSimple("custom_engine_clear_engines"), data: engineCombo});
            engineComboIgnore = false;
        }

        private function e_vsyncMouseOver(e:Event):void
        {
            useVSyncCheckbox.addEventListener(MouseEvent.MOUSE_OUT, e_vsyncMouseOut);
            displayToolTip(useVSyncCheckbox.x - 4, useVSyncCheckbox.y, _lang.string("air_options_use_vsync_unavailable"), "right");
        }

        private function e_vsyncMouseOut(e:Event):void
        {
            useVSyncCheckbox.removeEventListener(MouseEvent.MOUSE_OUT, e_vsyncMouseOut);
            hideTooltip();
        }
    }
}

import classes.Language;
import classes.ui.BoxButton;
import classes.ui.Text;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;
import popups.settings.SettingsTabMisc;

internal class WindowSettingConfirm extends Sprite
{
    private var _lang:Language = Language.instance;

    private var tab:SettingsTabMisc;
    private var properties:Object;
    private var previousWidth:int;
    private var previousHeight:int;
    private var previousX:int;
    private var previousY:int;

    private var confirmTimer:Timer;

    private var window_text:Text;
    private var window_timer_text:Text;
    private var confirm_btn:BoxButton;

    public function WindowSettingConfirm(tab:SettingsTabMisc, properties:Object):void
    {
        this.tab = tab;
        this.properties = properties;

        this.previousX = properties["x"];
        this.previousY = properties["y"];
        this.previousWidth = properties["width"];
        this.previousHeight = properties["height"];

        this.graphics.lineStyle(0, 0, 0);
        this.graphics.beginFill(0, 0.95);
        this.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
        this.graphics.endFill();

        confirmTimer = new Timer(1000, 10);
        confirmTimer.addEventListener(TimerEvent.TIMER, e_timerTick);
        confirmTimer.start();

        window_text = new Text(this, 0, 200, _lang.string("option_window_settings_confirm_text"), 24);
        window_text.setAreaParams(Main.GAME_WIDTH, 30, "center");

        window_timer_text = new Text(this, 0, 250, "10", 38);
        window_timer_text.setAreaParams(Main.GAME_WIDTH, 30, "center");

        confirm_btn = new BoxButton(this, Main.GAME_WIDTH / 2 - 50, 400, 100, 30, _lang.string("menu_confirm"), 12, e_confirm);
    }

    private function e_timerTick(e:TimerEvent):void
    {
        window_timer_text.text = (confirmTimer.repeatCount - confirmTimer.currentCount).toString();

        if (confirmTimer.currentCount >= confirmTimer.repeatCount)
        {
            e_cancel();
        }
    }

    private function e_confirm(e:Event):void
    {
        confirmTimer.stop();
        this.parent.removeChild(this);
    }

    private function e_cancel():void
    {
        properties["width"] = previousWidth;
        properties["height"] = previousHeight;
        properties["x"] = previousX;
        properties["y"] = previousY;

        confirmTimer.stop();
        this.parent.removeChild(this);

        this.tab.e_windowSetUpdate();
    }
}
