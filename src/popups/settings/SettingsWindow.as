package popups.settings
{
    import arc.ArcGlobals;
    import assets.GameBackgroundColor;
    import classes.Language;
    import classes.SongInfo;
    import classes.User;
    import classes.chart.Song;
    import classes.ui.BoxButton;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.SimpleBoxButton;
    import classes.ui.Text;
    import com.bit101.components.Window;
    import com.flashfla.utils.SpriteUtil;
    import com.greensock.TweenLite;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.media.SoundMixer;
    import flash.media.SoundTransform;
    import game.GameOptions;
    import menu.MainMenu;
    import menu.MenuPanel;
    import menu.MenuSongSelection;

    public class SettingsWindow extends MenuPanel
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;

        private var box:Sprite;
        private var bmp:Bitmap;

        public var scrollbar:ScrollBar;
        public var pane:ScrollPane;

        private var TABS:Vector.<SettingsTabBase>;

        private var CURRENT_TAB:SettingsTabBase;
        private var CURRENT_INDEX:int = -1;
        private static var LAST_INDEX:int = 0;

        private var TAB_BUTTONS:Vector.<TabButton>;

        private var txt_settings:Text;
        private var txt_mod_warning:Text;

        // buttons
        private var btn_close:BoxButton;
        private var btn_manage:BoxButton;
        private var btn_reset:BoxButton;

        private var btn_editor_gameplay:TabButton;
        private var btn_editor_multiplayer:TabButton;
        private var btn_editor_spectator:TabButton;

        private var game_options_test:GameOptions = new GameOptions();

        private var win_manage:ManageWindow;

        public function SettingsWindow(myParent:MenuPanel)
        {
            // build menus
            TABS = new <SettingsTabBase>[new SettingsTabGeneral(this),
                new SettingsTabInput(this),
                new SettingsTabNoteskin(this),
                new SettingsTabModifiers(this),
                new SettingsTabVisuals(this),
                new SettingsTabColors(this),
                new SettingsTabMisc(this)];

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
            box.graphics.moveTo(0, 60);
            box.graphics.lineTo(Main.GAME_WIDTH, 60);
            box.graphics.moveTo(174, 61);
            box.graphics.lineTo(174, Main.GAME_HEIGHT);
            box.graphics.moveTo(Main.GAME_WIDTH - 16, 61);
            box.graphics.lineTo(Main.GAME_WIDTH - 16, Main.GAME_HEIGHT);

            this.addChild(box);

            // scroll pane
            pane = new ScrollPane(this, 175, 61, 589, Main.GAME_HEIGHT - 61);
            pane.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMoved, false, 0, false);
            scrollbar = new ScrollBar(this, Main.GAME_WIDTH - 16, 61, 16, Main.GAME_HEIGHT - 61, null, new Sprite());
            scrollbar.addEventListener(Event.CHANGE, scrollBarMoved, false, 0, false);

            // ui
            buildTabs();

            txt_settings = new Text(box, 15, 5, _lang.string("settings_title"), 32);

            txt_mod_warning = new Text(box, 215, 18, _lang.string("options_warning_save"), 14, "#f06868");
            txt_mod_warning.setAreaParams(265, 24, "right");

            btn_reset = new BoxButton(box, 495, 15, 80, 29, _lang.string("menu_reset"), 12, clickHandler);
            btn_reset.color = 0xff0000;

            btn_manage = new BoxButton(box, 590, 15, 80, 29, _lang.string("menu_manage"), 12, clickHandler);

            btn_close = new BoxButton(box, 685, 15, 80, 29, _lang.string("menu_close"), 12, clickHandler);
            //btn_close.contextMenu = _contextImportExport;

            changeTab(LAST_INDEX);
        }

        override public function stageRemove():void
        {
            CURRENT_TAB.closeTab();
            scrollbar.removeEventListener(Event.CHANGE, scrollBarMoved, false);
            pane.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelMoved, false);
        }

        public function buildTabs():void
        {
            var tabBox:TabButton;

            for (var idx:int = 0; idx < TABS.length; idx++)
            {
                TABS[idx].container = pane.content;

                tabBox = new TabButton(box, -1, 60 + 33 * idx, idx, _lang.string("settings_tab_" + TABS[idx].name));
                tabBox.tabIndex = idx;
                tabBox.addEventListener(MouseEvent.CLICK, tabHandler);

                TAB_BUTTONS.push(tabBox);
            }

            // editor buttons
            btn_editor_gameplay = new TabButton(box, -1, 364, -1, _lang.string("settings_tab_editor_gameplay"), true);
            btn_editor_gameplay.addEventListener(MouseEvent.CLICK, clickHandler);
            btn_editor_multiplayer = new TabButton(box, -1, 397, -1, _lang.string("settings_tab_editor_multiplayer"));
            btn_editor_multiplayer.addEventListener(MouseEvent.CLICK, clickHandler);
            btn_editor_spectator = new TabButton(box, -1, 430, -1, _lang.string("settings_tab_editor_spectator"));
            btn_editor_spectator.addEventListener(MouseEvent.CLICK, clickHandler);
        }

        public function changeTab(idx:int):void
        {
            if (CURRENT_INDEX == idx)
                return;

            if (CURRENT_TAB != null)
            {
                CURRENT_TAB.closeTab();
                pane.clear();
                pane.content.graphics.clear();
            }

            CURRENT_INDEX = idx;
            CURRENT_TAB = TABS[idx];
            CURRENT_TAB.openTab();
            CURRENT_TAB.setValues();
            LAST_INDEX = idx;

            pane.update();

            pane.scrollTo(0);
            scrollbar.scrollTo(0);

            scrollbar.visible = (pane.content.height > 425);

            // update buttons
            for each (var tabButton:TabButton in TAB_BUTTONS)
                tabButton.setActive(tabButton.index == idx);

            checkValidMods();
        }

        private function tabHandler(e:MouseEvent):void
        {
            changeTab((e.currentTarget as TabButton).index);
        }

        public function checkValidMods():void
        {
            game_options_test.fill();
            txt_mod_warning.visible = !game_options_test.isScoreValid();
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.currentTarget == btn_editor_gameplay || e.currentTarget == btn_editor_multiplayer || e.currentTarget == btn_editor_spectator)
            {
                _gvars.options = new GameOptions();
                _gvars.options.isEditor = true;

                var tempSongInfo:SongInfo = new SongInfo();
                tempSongInfo.level = 1337;
                tempSongInfo.chart_type = "EDITOR";
                _gvars.options.song = new Song(tempSongInfo);

                _gvars.options.fill();
                removePopup();
                _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
                return;
            }

            else if (e.target == btn_manage)
            {
                win_manage = new ManageWindow(this);
                addChild(win_manage);
            }

            else if (e.target == btn_reset)
            {
                var confirmP:Window = new Window(this, 0, 0, "Confirm Settings Reset");
                confirmP.hasMinimizeButton = false;
                confirmP.hasCloseButton = false;
                confirmP.setSize(110, 105);
                confirmP.x = (Main.GAME_WIDTH / 2 - confirmP.width / 2);
                confirmP.y = (Main.GAME_HEIGHT / 2 - confirmP.height / 2);

                function doReset(e:Event):void
                {
                    confirmP.parent.removeChild(confirmP);
                    if (_gvars.activeUser == _gvars.playerUser)
                    {
                        _gvars.activeUser.settings = new User().settings;
                        _avars.resetSettings();
                    }
                    changeTab(CURRENT_INDEX);
                }

                function closeReset(e:Event):void
                {
                    confirmP.parent.removeChild(confirmP);
                }

                var resB:BoxButton = new BoxButton(confirmP, 5, 5, 100, 35, _lang.string("menu_reset"), 12, doReset);
                resB.color = 0x330000;
                resB.textColor = "#990000";

                var conB:BoxButton = new BoxButton(confirmP, 5, 45, 100, 35, _lang.string("menu_close"), 12, closeReset);
                conB.color = 0;
                conB.textColor = "#000000";
            }

            else if (e.target == btn_close)
            {
                if (_gvars.activeUser == _gvars.playerUser)
                {
                    _gvars.activeUser.saveLocal();
                    _gvars.activeUser.save();

                    // Setup Background Colors
                    GameBackgroundColor.BG_LIGHT = _gvars.activeUser.gameColors[0];
                    GameBackgroundColor.BG_DARK = _gvars.activeUser.gameColors[1];
                    GameBackgroundColor.BG_STATIC = _gvars.activeUser.gameColors[2];
                    GameBackgroundColor.BG_POPUP = _gvars.activeUser.gameColors[3];
                    GameBackgroundColor.BG_STAGE = _gvars.activeUser.gameColors[4];
                    (_gvars.gameMain.getChildAt(0) as GameBackgroundColor).redraw();

                    if (_gvars.gameMain.activePanel is MainMenu && ((_gvars.gameMain.activePanel as MainMenu).panel is MenuSongSelection))
                    {
                        var panel:MenuSongSelection = ((_gvars.gameMain.activePanel as MainMenu).panel as MenuSongSelection);
                        panel.buildGenreList();
                        panel.drawPages();
                    }
                }
                SoundMixer.soundTransform = new SoundTransform(_gvars.activeUser.gameVolume);
                LocalOptions.setVariable("menu_music_volume", _gvars.menuMusicSoundVolume);
                removePopup();
                return;
            }
        }

        private function mouseWheelMoved(e:MouseEvent):void
        {
            if (!scrollbar.visible)
                return;

            var dist:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(dist);
            scrollbar.scrollTo(dist);
        }

        private function scrollBarMoved(e:Event):void
        {
            pane.scrollTo(e.target.scroll);
        }
    }
}

import assets.GameBackgroundColor;
import assets.menu.icons.fa.iconRight;
import classes.Alert;
import classes.Language;
import classes.ui.BoxButton;
import classes.ui.SimpleBoxButton;
import classes.ui.Text;
import com.flashfla.utils.SpriteUtil;
import com.flashfla.utils.SystemUtil;
import com.greensock.TweenLite;
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.text.AntiAliasType;
import flash.text.GridFitType;
import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import popups.settings.SettingsWindow;

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

internal class ManageWindow extends Sprite
{
    private var _gvars:GlobalVariables = GlobalVariables.instance;
    private var _lang:Language = Language.instance;
    private var bmp:Bitmap;
    private var box:Sprite;
    private var win:SettingsWindow;

    private var boxMid:Number = (Main.GAME_WIDTH - 200) / 2;

    private var saveJSON:String;

    private var btn_close:BoxButton;
    private var txt_export:TextField;
    private var btn_export:BoxButton;
    private var txt_import:TextField;
    private var btn_import:BoxButton;

    public function ManageWindow(win:SettingsWindow):void
    {
        this.win = win;

        saveJSON = JSON.stringify(_gvars.activeUser.save(true));

        bmp = SpriteUtil.getBitmapSprite(win.stage);
        this.addChild(bmp);

        box = new Sprite();
        box.graphics.beginFill(0, 0.25);
        box.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
        box.graphics.endFill();

        box.graphics.lineStyle(1, 0xffffff, 0.35);
        box.graphics.beginFill(GameBackgroundColor.BG_POPUP, 0.7);
        box.graphics.drawRect(100, 100, Main.GAME_WIDTH - 200, Main.GAME_HEIGHT - 200);
        box.graphics.endFill();

        box.graphics.moveTo(100 + boxMid, 110);
        box.graphics.lineTo(100 + boxMid, 100 + Main.GAME_HEIGHT - 210);
        this.addChild(box);

        var xOff:Number = 100;
        var yOff:Number = 100;

        btn_close = new BoxButton(box, xOff + Main.GAME_WIDTH - 300, yOff + Main.GAME_HEIGHT - 190, 100, 29, _lang.string("menu_close"), 12, clickHandler);

        new Text(box, xOff + 10, yOff + 12, "Export", 16).setAreaParams(160, 30);
        btn_export = new BoxButton(box, xOff + 179, yOff + 10, 100, 26, "Copy", 12, clickHandler);

        txt_export = makeTextfield();
        txt_export.x = xOff + 15;
        txt_export.y = yOff + 50;
        txt_export.type = TextFieldType.DYNAMIC;
        txt_export.text = saveJSON;

        box.graphics.beginFill(0, 0.4);
        box.graphics.drawRect(txt_export.x - 4, txt_export.y - 4, txt_export.width + 8, txt_export.height + 8);
        box.graphics.endFill();

        xOff += boxMid;

        new Text(box, xOff + 10, yOff + 12, "Import", 16).setAreaParams(160, 30);
        btn_import = new BoxButton(box, xOff + 179, yOff + 10, 100, 26, "Save", 12, clickHandler);

        txt_import = makeTextfield();
        txt_import.x = xOff + 15;
        txt_import.y = yOff + 50;
        txt_import.type = TextFieldType.INPUT;

        box.graphics.beginFill(0, 0.4);
        box.graphics.drawRect(txt_import.x - 4, txt_import.y - 4, txt_import.width + 8, txt_import.height + 8);
        box.graphics.endFill();
    }

    private function makeTextfield():TextField
    {
        var _tf:TextField = new TextField();
        _tf.width = boxMid - 30;
        _tf.height = 215;
        _tf.multiline = true;
        _tf.defaultTextFormat = new TextFormat(Fonts.BASE_FONT, 10, 0xFFFFFF, true);
        _tf.type = TextFieldType.DYNAMIC;
        _tf.embedFonts = true;
        _tf.antiAliasType = AntiAliasType.ADVANCED;
        _tf.gridFitType = GridFitType.SUBPIXEL;
        _tf.wordWrap = true;
        box.addChild(_tf);
        return _tf;
    }

    private function clickHandler(e:Event):void
    {
        if (e.target == btn_export)
        {
            var success:Boolean = SystemUtil.setClipboard(saveJSON);

            if (success)
                Alert.add(_lang.string("clipboard_success"), 120, Alert.GREEN);
            else
                Alert.add(_lang.string("clipboard_failure"), 120, Alert.RED);
        }

        else if (e.target == btn_import)
        {
            try
            {
                var optionsJSON:String = txt_import.text;
                if (optionsJSON.length >= 2 && optionsJSON.charAt(0) == "{")
                {
                    var item:Object = JSON.parse(optionsJSON);
                    _gvars.activeUser.settings = item;
                    Alert.add("Settings Imported!", 120, Alert.GREEN);
                }
                else
                {
                    Alert.add("Nothing to Import", 120, Alert.RED);
                }
            }
            catch (e:Error)
            {
                Alert.add("Import Fail...", 120, Alert.RED);
            }
        }

        else if (e.target == btn_close)
        {
            win.removeChild(this);
        }
    }
}
