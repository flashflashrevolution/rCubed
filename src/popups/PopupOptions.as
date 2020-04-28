package popups
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerPrompt;
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.BoxSlider;
    import classes.MouseTooltip;
    import com.bit101.components.Window;
    import com.flashfla.components.ColorField;
    import com.flashfla.net.Multiplayer;
    import assets.options.checkBox;
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxText;
    import classes.chart.Song;
    import classes.chart.parse.ChartFFRLegacy;
    import classes.GameNote;
    import classes.Language;
    import classes.Noteskins;
    import classes.Playlist;
    import classes.Text;
    import classes.User;
    import com.bit101.components.ComboBox;
    import com.bit101.components.Style;
    import com.flashfla.utils.ArrayUtil;
    import com.flashfla.utils.ColorUtil;
    import com.flashfla.utils.StringUtil;
    import com.flashfla.utils.SystemUtil;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.events.ContextMenuEvent;
    import menu.MainMenu;
    import menu.MenuPanel;
    import game.GameOptions;
    import flash.media.SoundMixer;
    import flash.media.SoundTransform;
    import menu.MenuSongSelection;

    CONFIG::air
    {
        import flash.filesystem.File;
    }

    public class PopupOptions extends MenuPanel
    {
        private const TAB_MAIN:int = 0;
        private const TAB_VISUAL_MODS:int = 1;
        private const TAB_COLORS:int = 2;
        private const TAB_OTHER:int = 3;

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _lang:Language = Language.instance;
        private var _noteskins:Noteskins = Noteskins.instance;
        private var _playlist:Playlist = Playlist.instance;

        private var DEFAULT_OPTIONS:GameOptions = new GameOptions();

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var CURRENT_TAB:int = TAB_MAIN;

        private var keyListenerTarget:*;

        //- Arrays
        private var keyInputs:Array = ["left", "down", "up", "right", "restart", "quit", "options"];
        private var judgeTitles:Array = ["amazing", "perfect", "good", "average", "miss", "boo"];
        private var displayArray:Array = ["SONG_FLAG", "----", "JUDGE", "HEALTH", "SCORE", "COMBO", "PACOUNT", "SONGPROGRESS", "AMAZING", "PERFECT", "TOTAL", "SCREENCUT", "MP_MASK", "GAME_TOP_BAR", "GAME_BOTTOM_BAR"];
        private var noteColorComboArray:Array = [];
        private var startUpScreenSelections:Array = [];

        //- Menu
        private var menuMain:BoxButton;
        private var menuVisualMods:BoxButton;
        private var menuGameColors:BoxButton;
        private var menuOther:BoxButton;
        private var closeOptions:BoxButton;
        private var resetOptions:BoxButton;
        private var editorOptions:BoxButton;
        private var editorOptionsMP:BoxButton;
        private var editorOptionsMPSpec:BoxButton;
        private var warningOptions:Text;
        private var _contextImportExport:ContextMenu;
        private var hover_message:MouseTooltip;

        //- Options
        private var optionGameSpeed:BoxText;
        private var optionOffset:BoxText;
        private var optionJudgeOffset:BoxText;
        private var gameJudgeOffset:Text
        private var autoJudgeOffsetCheck:checkBox;
        private var gameAutoJudgeOffset:Text;
        private var optionReceptorSpacing:BoxText;
        private var optionNoteScale:BoxSlider;
        private var optionGameVolume:BoxSlider;
        private var gameVolumeValueDisplay:Text;
        private var optionFPS:BoxText;
        private var optionRate:BoxText;
        private var forceJudgeCheck:checkBox;
        private var gameForceJudgeMode:Text;
        private var optionScrollDirections:Array;
        private var menuVolumeValueDisplay:Text;
        private var noteScaleValueDisplay:Text;
        private var optionMenuVolume:BoxSlider;
        private var optionKeyInputs:Array;
        private var optionAutofail:Array;

        private var optionDisplays:Array;
        private var optionVisualGameMods:Array;
        private var optionGameMods:Array;
        private var optionNoteskins:Array;
        private var optionNoteskinPreview:GameNote;
        private var optionNoteskinsCustom:BoxButton;

        private var optionJudgeColors:Array;
        private var optionComboColors:Array;
        private var optionGameColors:Array;
        private var optionNoteColors:Array;

        private var isolationText:BoxText;
        private var isolationTotalText:BoxText;
        private var optionMPSize:BoxText;
        private var timestampCheck:checkBox;
        private var startUpScreenCombo:ComboBox;
        private var optionGameLanguages:Array;
        private var engineCombo:ComboBox;
        private var engineDefaultCombo:ComboBox;
        private var engineComboIgnore:Boolean;
        private var legacySongsCheck:checkBox;

        CONFIG::air
        {
            private var useCacheCheckbox:checkBox;
            private var autoSaveLocalCheckbox:checkBox;
            private var useVSyncCheckbox:checkBox;
        }

        public function PopupOptions(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function stageAdd():void
        {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
            stage.focus = this.stage;

            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);

            this.addChild(bmp);

            var bgbox:Box = new Box(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40, false, false);
            bgbox.x = 20;
            bgbox.y = 20;
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;
            this.addChild(bgbox);

            box = new Box(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40, false, false);
            box.x = 20;
            box.y = 20;
            box.activeAlpha = 0.4;
            this.addChild(box);

            // Create ComboBox Data
            for (var i:int = 0; i < DEFAULT_OPTIONS.noteColors.length; i++)
            {
                noteColorComboArray.push({"label": _lang.stringSimple("note_colors_" + DEFAULT_OPTIONS.noteColors[i]), "data": DEFAULT_OPTIONS.noteColors[i]});
            }
            for (i = 0; i <= 2; i++)
            {
                startUpScreenSelections.push({"label": _lang.stringSimple("options_startup_" + i), "data": i});
            }

            // Import / Export Context Menu
            _contextImportExport = new ContextMenu();
            var expOptionsImport:ContextMenuItem = new ContextMenuItem(_lang.stringSimple("popup_options_import"));
            expOptionsImport.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_contextOptionsImport);
            var expOptionsExport:ContextMenuItem = new ContextMenuItem(_lang.stringSimple("popup_options_export"));
            expOptionsExport.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_contextOptionsExport);
            _contextImportExport.customItems.push(expOptionsImport, expOptionsExport);

            // Render Options
            renderOptions();

        }

        private function e_contextOptionsExport(e:ContextMenuEvent):void
        {
            var optionsString:String = JSON.stringify(_gvars.activeUser.save(true));
            var success:Boolean = SystemUtil.setClipboard(optionsString);
            if (success)
            {
                _gvars.gameMain.addAlert("Copied to Clipboard!", 120, Alert.GREEN);
            }
            else
            {
                _gvars.gameMain.addAlert("Error Copying to Clipboard", 120, Alert.RED);
            }
        }

        private function e_contextOptionsImport(e:ContextMenuEvent):void
        {
            var prompt:MultiplayerPrompt = new MultiplayerPrompt(box.parent, _lang.stringSimple("popup_options_import"));
            prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
            {
                try
                {
                    var item:Object = JSON.parse(subevent.params.value);
                    _gvars.activeUser.settings = item;
                    _gvars.gameMain.addAlert("Settings Imported!", 120, Alert.GREEN);
                    renderOptions();
                }
                catch (e:Error)
                {
                    _gvars.gameMain.addAlert("Import Fail...", 120, Alert.GREEN);
                }
            });
        }


        private function renderMenu():void
        {
            var tab_width:int = 170;
            menuMain = new BoxButton(tab_width, 25, _lang.string("options_menu_main"));
            menuMain.x = 15;
            menuMain.y = 15;
            menuMain.menu_select = TAB_MAIN;

            menuVisualMods = new BoxButton(tab_width, 25, _lang.string("options_menu_visual_mods"));
            menuVisualMods.x = menuMain.x + tab_width + 10;
            menuVisualMods.y = 15;
            menuVisualMods.menu_select = TAB_VISUAL_MODS;

            menuGameColors = new BoxButton(tab_width, 25, _lang.string("options_menu_game_colors"));
            menuGameColors.x = menuVisualMods.x + tab_width + 10;
            menuGameColors.y = 15;
            menuGameColors.menu_select = TAB_COLORS;

            menuOther = new BoxButton(tab_width, 25, _lang.string("options_menu_other"));
            menuOther.x = menuGameColors.x + tab_width + 10;
            menuOther.y = 15;
            menuOther.menu_select = TAB_OTHER;

            //- Close
            closeOptions = new BoxButton(80, 27, _lang.string("menu_close"));
            closeOptions.x = box.width - 95;
            closeOptions.y = box.height - 42;
            closeOptions.contextMenu = _contextImportExport;

            //- Reset
            resetOptions = new BoxButton(80, 27, _lang.string("menu_reset"));
            resetOptions.x = box.width - 180;
            resetOptions.y = box.height - 42;
            resetOptions.boxColor = 0xff0000;

            //- Editor
            editorOptions = new BoxButton(80, 27, _lang.string("menu_editor"));
            editorOptions.x = box.width - 265;
            editorOptions.y = box.height - 42;
            editorOptions.editor_multiplayer = null;

            //- Editor - MP
            editorOptionsMP = new BoxButton(130, 27, _lang.string("menu_editor_mp"));
            editorOptionsMP.x = editorOptions.x - editorOptionsMP.width - 5;
            editorOptionsMP.y = editorOptions.y;
            editorOptionsMP.editor_multiplayer = {playerCount: 2,
                    connection: {mode: Multiplayer.GAME_R3, currentUser: {userID: 1}},
                    user: {userID: 1, playerID: 1, isPlayer: true},
                    players: [{playerID: 1, userID: 1830376, userName: "arcnmx"}, {playerID: 2, userID: 249481, userName: "Velocity"}]};

            //- Editor - MP Spectate
            editorOptionsMPSpec = new BoxButton(130, 27, _lang.string("menu_editor_mp_spec"));
            editorOptionsMPSpec.x = editorOptionsMP.x - editorOptionsMPSpec.width - 5;
            editorOptionsMPSpec.y = editorOptionsMP.y;
            editorOptionsMPSpec.editor_multiplayer = {playerCount: 2,
                    connection: {mode: Multiplayer.GAME_R3, currentUser: {userID: 0}},
                    user: {userID: 0, playerID: -1, isPlayer: false},
                    players: [{playerID: -1, userID: 0}, {playerID: 1, userID: 1830376, userName: "arcnmx"}, {playerID: 2, userID: 249481, userName: "Velocity"}]};

            warningOptions = new Text(_lang.string("options_warning_save"), 14, "#f06868");
            warningOptions.x = editorOptions.x;
            warningOptions.y = editorOptions.y - 25;

            menuMain.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            menuVisualMods.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            menuGameColors.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            menuOther.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            box.addChild(menuMain);
            box.addChild(menuVisualMods);
            box.addChild(menuGameColors);
            box.addChild(menuOther);

            closeOptions.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            resetOptions.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            box.addChild(closeOptions);
            box.addChild(resetOptions);

            if (!_gvars.flashvars.replay && !_gvars.flashvars.preview_file)
            {
                editorOptions.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                editorOptionsMP.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                editorOptionsMPSpec.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                box.addChild(editorOptions);
                box.addChild(editorOptionsMP);
                box.addChild(editorOptionsMPSpec);
                box.addChild(warningOptions);
            }
        }

        override public function stageRemove():void
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
            for (var index:int = 0; index < box.numChildren; index++)
            {
                var item:DisplayObject = box.getChildAt(index);
                item.removeEventListener(MouseEvent.CLICK, clickHandler);
                item.removeEventListener(Event.CHANGE, changeHandler);
            }

            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        private function renderOptions():void
        {
            if (box == null)
            {
                return;
            }

            for (var index:int = box.numChildren - 1; index >= 2; index--)
            {
                var olditem:DisplayObject = box.getChildAt(index);
                olditem.removeEventListener(MouseEvent.CLICK, clickHandler);
                olditem.removeEventListener(Event.CHANGE, changeHandler);
                box.removeChild(olditem);
            }

            renderMenu();

            var BASE_Y_POSITION:int = 50;
            var item:Object;
            var xOff:int = 15;
            var yOff:int = BASE_Y_POSITION;

            if (CURRENT_TAB == TAB_MAIN)
            {
                /// Col 1
                //- Speed
                var gameSpeed:Text = new Text(_lang.string("options_speed"));
                gameSpeed.x = xOff;
                gameSpeed.y = yOff;
                box.addChild(gameSpeed);
                yOff += 20;

                optionGameSpeed = new BoxText(100, 20);
                optionGameSpeed.x = xOff;
                optionGameSpeed.y = yOff;
                optionGameSpeed.restrict = "0-9.";
                optionGameSpeed.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionGameSpeed);
                yOff += 30;

                //- Global Offset
                var gameOffset:Text = new Text(_lang.string("options_global_offset"));
                gameOffset.x = xOff;
                gameOffset.y = yOff;
                box.addChild(gameOffset);
                yOff += 20;

                optionOffset = new BoxText(100, 20);
                optionOffset.x = xOff;
                optionOffset.y = yOff;
                optionOffset.restrict = "-0-9";
                optionOffset.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionOffset);
                yOff += 30;

                //- Judge Offset
                gameJudgeOffset = new Text(_lang.string("options_judge_offset"));
                gameJudgeOffset.x = xOff;
                gameJudgeOffset.y = yOff;
                box.addChild(gameJudgeOffset);
                yOff += 20;

                optionJudgeOffset = new BoxText(100, 20);
                optionJudgeOffset.x = xOff;
                optionJudgeOffset.y = yOff;
                optionJudgeOffset.restrict = "-0-9";
                optionJudgeOffset.addEventListener(Event.CHANGE, changeHandler);
                optionJudgeOffset.contextMenu = arcJudgeMenu();
                box.addChild(optionJudgeOffset);

                //- Auto Judge Offset
                xOff += 105;
                autoJudgeOffsetCheck = new checkBox();
                autoJudgeOffsetCheck.x = xOff;
                autoJudgeOffsetCheck.y = yOff;
                autoJudgeOffsetCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                autoJudgeOffsetCheck.addEventListener(MouseEvent.MOUSE_OVER, e_autoJudgeMouseOver, false, 0, true);
                box.addChild(autoJudgeOffsetCheck);
                gameAutoJudgeOffset = new Text(_lang.string("options_auto_judge_offset"));
                gameAutoJudgeOffset.x = xOff - 2;
                gameAutoJudgeOffset.y = yOff - 20;
                box.addChild(gameAutoJudgeOffset);
                xOff -= 105;
                yOff += 30;

                //- Receptor Spacing
                var gameReceptorSpacing:Text = new Text(_lang.string("options_receptor_spacing"));
                gameReceptorSpacing.x = xOff;
                gameReceptorSpacing.y = yOff;
                box.addChild(gameReceptorSpacing);
                yOff += 20;

                optionReceptorSpacing = new BoxText(100, 20);
                optionReceptorSpacing.x = xOff;
                optionReceptorSpacing.y = yOff;
                optionReceptorSpacing.restrict = "-0-9";
                optionReceptorSpacing.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionReceptorSpacing);
                yOff += 30;

                //- Note Scale
                var gameNoteScale:Text = new Text(_lang.string("options_note_scale"));
                gameNoteScale.x = xOff;
                gameNoteScale.y = yOff;
                box.addChild(gameNoteScale);
                yOff += 20;

                optionNoteScale = new BoxSlider(100, 10);
                optionNoteScale.x = xOff;
                optionNoteScale.y = yOff;
                optionNoteScale.maxValue = 1;
                optionNoteScale.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionNoteScale);
                yOff += 10;

                noteScaleValueDisplay = new Text(Math.round(_gvars.activeUser.noteScale * 100) + "%");
                noteScaleValueDisplay.x = xOff;
                noteScaleValueDisplay.y = yOff;
                box.addChild(noteScaleValueDisplay);
                yOff += 20;

                // Engine Framerate
                var gameFPS:Text = new Text(_lang.string("options_framerate"));
                gameFPS.x = xOff;
                gameFPS.y = yOff;
                box.addChild(gameFPS);
                yOff += 20;

                optionFPS = new BoxText(100, 20);
                optionFPS.x = xOff;
                optionFPS.y = yOff;
                optionFPS.restrict = "0-9";
                optionFPS.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionFPS);
                yOff += 30;

                // Song Rate
                var gameRate:Text = new Text(_lang.string("options_rate"));
                gameRate.x = xOff;
                gameRate.y = yOff;
                box.addChild(gameRate);
                yOff += 20;

                if (SystemUtil.isFlashNewerThan(10, 0))
                {
                    optionRate = new BoxText(100, 20);
                    optionRate.x = xOff;
                    optionRate.y = yOff;
                    optionRate.restrict = ".0-9";
                    optionRate.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(optionRate);
                }
                else
                {
                    var gameRateF10:Text = new Text(_lang.string("options_f10_required"));
                    gameRateF10.x = xOff;
                    gameRateF10.y = yOff;
                    box.addChild(gameRateF10);
                }
                yOff += 40;

                // Force engine Judge Mode
                forceJudgeCheck = new checkBox();
                forceJudgeCheck.x = xOff;
                forceJudgeCheck.y = yOff;
                forceJudgeCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                box.addChild(forceJudgeCheck);

                gameForceJudgeMode = new Text(_lang.string("options_force_judge_mode"));
                gameForceJudgeMode.x = xOff + 20;
                gameForceJudgeMode.y = yOff - 3;
                box.addChild(gameForceJudgeMode);

                /// Col 2
                xOff += 176;
                yOff = BASE_Y_POSITION;

                //- Direction
                optionScrollDirections = [];
                var gameDirection:Text = new Text(_lang.string("options_scroll"));
                gameDirection.x = xOff;
                gameDirection.y = yOff;
                box.addChild(gameDirection);
                yOff += 20;

                var directionData:Array = _gvars.SCROLL_DIRECTIONS;
                for (var i:int = 0; i < directionData.length; i++)
                {
                    var gameDirectionOptionText:Text = new Text(_lang.string("options_scroll_" + directionData[i]));
                    gameDirectionOptionText.x = xOff + 22;
                    gameDirectionOptionText.y = yOff;
                    box.addChild(gameDirectionOptionText);
                    yOff += 2;

                    var optionScrollCheck:checkBox = new checkBox();
                    optionScrollCheck.x = xOff + 2;
                    optionScrollCheck.y = yOff;
                    optionScrollCheck.slideDirection = directionData[i];
                    optionScrollCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(optionScrollCheck);
                    optionScrollDirections.push(optionScrollCheck);
                    yOff += 20;
                }

                // Game Volume
                yOff = Math.max(yOff, 250);
                var gameVolume:Text = new Text(_lang.string("options_volume"));
                gameVolume.x = xOff;
                gameVolume.y = yOff;
                box.addChild(gameVolume);
                yOff += 20;

                optionGameVolume = new BoxSlider(100, 10);
                optionGameVolume.x = xOff;
                optionGameVolume.y = yOff;
                optionGameVolume.maxValue = 1.25;
                optionGameVolume.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionGameVolume);
                yOff += 10;

                gameVolumeValueDisplay = new Text(Math.round(_gvars.activeUser.gameVolume * 100) + "%");
                gameVolumeValueDisplay.x = xOff;
                gameVolumeValueDisplay.y = yOff;
                box.addChild(gameVolumeValueDisplay);
                yOff += 20;

                // Menu Music Volume
                var menuVolume:Text = new Text(_lang.string("air_options_menu_volume"));
                menuVolume.x = xOff;
                menuVolume.y = yOff;
                box.addChild(menuVolume);
                yOff += 20;

                optionMenuVolume = new BoxSlider(100, 10);
                optionMenuVolume.x = xOff;
                optionMenuVolume.y = yOff;
                optionMenuVolume.maxValue = 1.25;
                optionMenuVolume.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionMenuVolume);
                yOff += 10;

                menuVolumeValueDisplay = new Text(Math.round(_gvars.menuMusicSoundVolume * 100) + "%");
                menuVolumeValueDisplay.x = xOff;
                menuVolumeValueDisplay.y = yOff;
                box.addChild(menuVolumeValueDisplay);
                yOff += 20;

                /// Col 3
                xOff += 176;
                yOff = BASE_Y_POSITION;

                //- Keys
                optionKeyInputs = [];
                var gameKeys:Text = new Text(_lang.string("options_keys"));
                gameKeys.x = xOff;
                gameKeys.y = yOff;
                box.addChild(gameKeys);
                yOff += 20;

                for (i = 0; i < keyInputs.length; i++)
                {
                    var gameKeyText:Text = new Text(_lang.string("options_scroll_" + keyInputs[i]));
                    gameKeyText.x = xOff + 57;
                    gameKeyText.y = yOff - 1;
                    box.addChild(gameKeyText);

                    var gameKeyInput:BoxText = new BoxText(50, 20);
                    gameKeyInput.x = xOff;
                    gameKeyInput.y = yOff;
                    gameKeyInput.autoSize = TextFieldAutoSize.CENTER;
                    gameKeyInput.selectable = false;
                    gameKeyInput.mouseChildren = false;
                    gameKeyInput.key = keyInputs[i];
                    gameKeyInput.addEventListener(MouseEvent.CLICK, clickHandler);
                    box.addChild(gameKeyInput);
                    optionKeyInputs.push(gameKeyInput);
                    yOff += 25;
                }

                /// Col 4
                xOff += 176;
                yOff = BASE_Y_POSITION;

                // Autofail
                optionAutofail = [];
                var gameAutofail:Text = new Text(_lang.string("options_autofail"));
                gameAutofail.x = xOff;
                gameAutofail.y = yOff;
                box.addChild(gameAutofail);
                yOff += 20;

                for (i = 0; i < judgeTitles.length; i++)
                {
                    var optionAutofailText:Text = new Text(_lang.string("game_" + judgeTitles[i]));
                    optionAutofailText.x = xOff + 77;
                    optionAutofailText.y = yOff - 1;
                    box.addChild(optionAutofailText);

                    var optionAutofailInput:BoxText = new BoxText(70, 20);
                    optionAutofailInput.x = xOff;
                    optionAutofailInput.y = yOff;
                    optionAutofailInput.autofail = judgeTitles[i];
                    optionAutofailInput.restrict = "0-9";
                    optionAutofailInput.field.maxChars = 5;
                    optionAutofailInput.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(optionAutofailInput);
                    optionAutofail.push(optionAutofailInput);
                    yOff += 25;
                }
            }
            else if (CURRENT_TAB == TAB_VISUAL_MODS)
            {
                ///- Col 1
                //- Display
                optionDisplays = [];
                var gameDisplay:Text = new Text(_lang.string("options_display"));
                gameDisplay.x = xOff;
                gameDisplay.y = yOff;
                box.addChild(gameDisplay);
                yOff += 20;

                for (i = 0; i < displayArray.length; i++)
                {
                    var gameDisplayName:Text;
                    if (displayArray[i] == "----")
                    {
                        gameDisplayName = new Text("----");
                        gameDisplayName.x = xOff + 23;
                        gameDisplayName.y = yOff - 8;
                        box.addChild(gameDisplayName);
                        yOff += 10;
                    }
                    else
                    {
                        gameDisplayName = new Text(_lang.string("options_" + displayArray[i].toLowerCase()));
                        gameDisplayName.x = xOff + 23;
                        gameDisplayName.y = yOff - 3;
                        box.addChild(gameDisplayName);

                        var gameDisplayCheck:checkBox = new checkBox();
                        gameDisplayCheck.x = xOff + 3;
                        gameDisplayCheck.y = yOff;
                        gameDisplayCheck.display = displayArray[i];
                        gameDisplayCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                        box.addChild(gameDisplayCheck);
                        optionDisplays.push(gameDisplayCheck);
                        yOff += 20;
                    }
                }

                ///- Col 2
                xOff += 206;
                yOff = BASE_Y_POSITION;

                //- Mods
                optionGameMods = [];
                var gameModsName:Text = new Text(_lang.string("options_game_mods"));
                gameModsName.x = xOff;
                gameModsName.y = yOff;
                box.addChild(gameModsName);
                yOff += 20;

                var modsData:Array = _gvars.GAME_MODS;
                for (i = 0; i < modsData.length; i++)
                {
                    if (modsData[i] == "----")
                    {
                        var gameModOptionTextSpacer:Text = new Text("----");
                        gameModOptionTextSpacer.x = xOff + 23;
                        gameModOptionTextSpacer.y = yOff - 8;
                        box.addChild(gameModOptionTextSpacer);
                        yOff += 10;
                        continue;
                    }
                    var gameModOptionText:Text = new Text(_lang.string("options_mod_" + modsData[i]));
                    gameModOptionText.x = xOff + 23;
                    gameModOptionText.y = yOff - 3;
                    box.addChild(gameModOptionText);

                    var optionModCheck:checkBox = new checkBox();
                    optionModCheck.x = xOff + 3;
                    optionModCheck.y = yOff;
                    optionModCheck.mod = modsData[i];
                    optionModCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(optionModCheck);
                    optionGameMods.push(optionModCheck);
                    yOff += 20;
                }

                ///- Col 3
                xOff += 146;
                yOff = BASE_Y_POSITION;

                //- Visual Mods
                optionVisualGameMods = [];
                var gameVisualModsName:Text = new Text(_lang.string("options_visual_mods"));
                gameVisualModsName.x = xOff;
                gameVisualModsName.y = yOff;
                box.addChild(gameVisualModsName);
                yOff += 20;

                var modsVisualData:Array = _gvars.VISUAL_MODS;
                for (i = 0; i < modsVisualData.length; i++)
                {
                    if (modsVisualData[i] == "----")
                    {
                        var gameVisualModOptionTextSpacer:Text = new Text("----");
                        gameVisualModOptionTextSpacer.x = xOff + 23;
                        gameVisualModOptionTextSpacer.y = yOff - 8;
                        box.addChild(gameVisualModOptionTextSpacer);
                        yOff += 10;
                        continue;
                    }
                    var gameVisualModOptionText:Text = new Text(_lang.string("options_mod_" + modsVisualData[i]));
                    gameVisualModOptionText.x = xOff + 23;
                    gameVisualModOptionText.y = yOff - 3;
                    box.addChild(gameVisualModOptionText);

                    var optionVisualModCheck:checkBox = new checkBox();
                    optionVisualModCheck.x = xOff + 3;
                    optionVisualModCheck.y = yOff;
                    optionVisualModCheck.visual_mod = modsVisualData[i];
                    optionVisualModCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(optionVisualModCheck);
                    optionVisualGameMods.push(optionVisualModCheck);
                    yOff += 20;
                }

                ///- Col 4
                xOff += 176;
                yOff = BASE_Y_POSITION;

                //- Noteskins
                optionNoteskins = [];
                var gameNoteskin:Text = new Text(_lang.string("options_noteskin"));
                gameNoteskin.x = xOff;
                gameNoteskin.y = yOff;
                box.addChild(gameNoteskin);
                yOff += 20;

                var gameNoteskinName:Text;
                var gameNoteskinCheck:checkBox;

                // Custom
                gameNoteskinName = new Text(_lang.string("options_noteskin_custom"));
                gameNoteskinName.x = xOff + 23;
                gameNoteskinName.y = yOff - 3;
                box.addChild(gameNoteskinName);

                gameNoteskinCheck = new checkBox();
                gameNoteskinCheck.x = xOff + 3;
                gameNoteskinCheck.y = yOff;
                gameNoteskinCheck.skin = 0;
                gameNoteskinCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                box.addChild(gameNoteskinCheck);
                optionNoteskins.push(gameNoteskinCheck);
                yOff += 20;

                var noteskinData:Object = _noteskins.data;
                var noteskin_ids:Array = [];
                for each (item in noteskinData)
                    if (item["_hidden"] == null)
                        noteskin_ids.push(item.id);
                noteskin_ids.sort(Array.NUMERIC);
                for each (var noteskin_id:String in noteskin_ids)
                {
                    item = noteskinData[noteskin_id];
                    gameNoteskinName = new Text(item.name);
                    gameNoteskinName.x = xOff + 23;
                    gameNoteskinName.y = yOff - 3;
                    box.addChild(gameNoteskinName);

                    gameNoteskinCheck = new checkBox();
                    gameNoteskinCheck.x = xOff + 3;
                    gameNoteskinCheck.y = yOff;
                    gameNoteskinCheck.skin = item.id;
                    gameNoteskinCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(gameNoteskinCheck);
                    optionNoteskins.push(gameNoteskinCheck);
                    yOff += 20;
                }

                optionNoteskinsCustom = new BoxButton(179, 23, _lang.string("options_noteskins_edit_custom"));
                optionNoteskinsCustom.x = xOff + 3;
                optionNoteskinsCustom.y = yOff + 1;
                optionNoteskinsCustom.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                box.addChild(optionNoteskinsCustom);

            }
            else if (CURRENT_TAB == TAB_COLORS)
            {
                ///- Col 1

                var gameJudgeColorTitle:Text = new Text(_lang.string("options_judge_colors_title"));
                gameJudgeColorTitle.x = xOff + 5;
                gameJudgeColorTitle.y = yOff;
                gameJudgeColorTitle.width = 211;
                gameJudgeColorTitle.align = Text.CENTER;
                box.addChild(gameJudgeColorTitle);
                yOff += 24;

                optionJudgeColors = [];
                for (i = 0; i < judgeTitles.length; i++)
                {
                    var gameJudgeColor:Text = new Text(_lang.string("game_" + judgeTitles[i]));
                    gameJudgeColor.x = xOff;
                    gameJudgeColor.y = yOff;
                    gameJudgeColor.width = 70;
                    gameJudgeColor.align = Text.RIGHT;
                    box.addChild(gameJudgeColor);

                    var optionJudgeColor:BoxText = new BoxText(70, 20);
                    optionJudgeColor.x = xOff + 75;
                    optionJudgeColor.y = yOff;
                    optionJudgeColor.judge_color_id = i;
                    optionJudgeColor.restrict = "#0-9a-f";
                    optionJudgeColor.field.maxChars = 7;
                    optionJudgeColor.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(optionJudgeColor);

                    var gameJudgeColorDisplay:ColorField = new ColorField(0, 45, 20);
                    gameJudgeColorDisplay.x = xOff + 150;
                    gameJudgeColorDisplay.y = yOff;
                    gameJudgeColorDisplay.key_name = "optionJudgeColor";
                    gameJudgeColorDisplay.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(gameJudgeColorDisplay);

                    var optionJudgeColorReset:BoxButton = new BoxButton(20, 20, "R");
                    optionJudgeColorReset.x = xOff + 200;
                    optionJudgeColorReset.y = yOff;
                    optionJudgeColorReset.judge_color_reset_id = i;
                    optionJudgeColorReset.boxColor = 0xff0000;
                    optionJudgeColorReset.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(optionJudgeColorReset);
                    optionJudgeColors.push({"text": optionJudgeColor, "display": gameJudgeColorDisplay, "reset": optionJudgeColorReset});

                    yOff += 25;
                }

                yOff += 25;

                var gameComboColorTitle:Text = new Text(_lang.string("options_combo_colors_title"));
                gameComboColorTitle.x = xOff + 5;
                gameComboColorTitle.y = yOff;
                gameComboColorTitle.width = 211;
                gameComboColorTitle.align = Text.CENTER;
                box.addChild(gameComboColorTitle);
                yOff += 24;

                optionComboColors = [];
                for (i = 0; i < DEFAULT_OPTIONS.comboColours.length; i++)
                {
                    var gameComboColor:Text = new Text(_lang.string("options_combo_colors_" + i));
                    gameComboColor.x = xOff;
                    gameComboColor.y = yOff;
                    gameComboColor.width = 70;
                    gameComboColor.align = Text.RIGHT;
                    box.addChild(gameComboColor);

                    var optionComboColor:BoxText = new BoxText(70, 20);
                    optionComboColor.x = xOff + 75;
                    optionComboColor.y = yOff;
                    optionComboColor.combo_color_id = i;
                    optionComboColor.restrict = "#0-9a-f";
                    optionComboColor.field.maxChars = 7;
                    optionComboColor.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(optionComboColor);

                    var gameComboColorDisplay:ColorField = new ColorField(0, 45, 20);
                    gameComboColorDisplay.x = xOff + 150;
                    gameComboColorDisplay.y = yOff;
                    gameComboColorDisplay.key_name = "gameComboColorDisplay";
                    gameComboColorDisplay.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(gameComboColorDisplay);

                    var optionComboColorReset:BoxButton = new BoxButton(20, 20, "R");
                    optionComboColorReset.x = xOff + 200;
                    optionComboColorReset.y = yOff;
                    optionComboColorReset.combo_color_reset_id = i;
                    optionComboColorReset.boxColor = 0xff0000;
                    optionComboColorReset.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(optionComboColorReset);
                    optionComboColors.push({"text": optionComboColor, "display": gameComboColorDisplay, "reset": optionComboColorReset});

                    yOff += 25;
                }

                ///- Col 2
                xOff += 245;
                yOff = BASE_Y_POSITION;

                var gameGameColorTitle:Text = new Text(_lang.string("options_game_colors_title"));
                gameGameColorTitle.x = xOff + 5;
                gameGameColorTitle.y = yOff;
                gameGameColorTitle.width = 211;
                gameGameColorTitle.align = Text.CENTER;
                box.addChild(gameGameColorTitle);
                yOff += 24;

                optionGameColors = [];
                for (i = 0; i < DEFAULT_OPTIONS.gameColours.length; i++)
                {
                    if (i == 2 || i == 3)
                        continue;
                    var gameGameColor:Text = new Text(_lang.string("options_game_colors_" + i));
                    gameGameColor.x = xOff;
                    gameGameColor.y = yOff;
                    gameGameColor.width = 70;
                    gameGameColor.align = Text.RIGHT;
                    box.addChild(gameGameColor);

                    var optionGameColor:BoxText = new BoxText(70, 20);
                    optionGameColor.x = xOff + 75;
                    optionGameColor.y = yOff;
                    optionGameColor.game_color_id = i;
                    optionGameColor.restrict = "#0-9a-f";
                    optionGameColor.field.maxChars = 7;
                    optionGameColor.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(optionGameColor);

                    var gameGameColorDisplay:ColorField = new ColorField(0, 45, 20);
                    gameGameColorDisplay.x = xOff + 150;
                    gameGameColorDisplay.y = yOff;
                    gameGameColorDisplay.key_name = "gameGameColorDisplay";
                    gameGameColorDisplay.addEventListener(Event.CHANGE, changeHandler);
                    box.addChild(gameGameColorDisplay);

                    var optionGameColorReset:BoxButton = new BoxButton(20, 20, "R");
                    optionGameColorReset.x = xOff + 200;
                    optionGameColorReset.y = yOff;
                    optionGameColorReset.game_color_reset_id = i;
                    optionGameColorReset.boxColor = 0xff0000;
                    optionGameColorReset.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(optionGameColorReset);
                    optionGameColors.push({"text": optionGameColor, "display": gameGameColorDisplay, "reset": optionGameColorReset});

                    yOff += 25;
                }

                ///- Col 3
                xOff += 245;
                yOff = BASE_Y_POSITION;

                var gameNoteColorTitle:Text = new Text(_lang.string("options_note_colors_title"));
                gameNoteColorTitle.x = xOff + 5;
                gameNoteColorTitle.y = yOff;
                gameNoteColorTitle.width = 211;
                gameNoteColorTitle.align = Text.CENTER;
                box.addChild(gameNoteColorTitle);
                yOff += 24;

                optionNoteColors = [];
                for (i = 0; i < DEFAULT_OPTIONS.noteColors.length; i++)
                {
                    var gameNoteColor:Text = new Text(_lang.string("note_colors_" + DEFAULT_OPTIONS.noteColors[i]));
                    gameNoteColor.x = xOff;
                    gameNoteColor.y = yOff;
                    gameNoteColor.width = 70;
                    gameNoteColor.align = Text.RIGHT;
                    box.addChild(gameNoteColor);

                    var gameNoteColorCombo:ComboBox = new ComboBox(box, xOff + 75, yOff, _lang.stringSimple("note_colors_" + DEFAULT_OPTIONS.noteColors[i]), noteColorComboArray);
                    gameNoteColorCombo.width = 105;
                    gameNoteColorCombo.openPosition = ComboBox.BOTTOM;
                    gameNoteColorCombo.fontSize = 11;
                    gameNoteColorCombo.addEventListener(Event.SELECT, gameNoteColorSelect);
                    box.addChild(gameNoteColorCombo);
                    optionNoteColors.push(gameNoteColorCombo);
                    yOff += 25;
                }

            }
            else if (CURRENT_TAB == TAB_OTHER)
            {
                //- Isolation
                var gameIsolationStart:Text = new Text(_lang.string("options_isolation_start"));
                gameIsolationStart.x = xOff;
                gameIsolationStart.y = yOff;
                box.addChild(gameIsolationStart);
                yOff += 20;

                isolationText = new BoxText(100, 20);
                isolationText.x = xOff;
                isolationText.y = yOff;
                isolationText.restrict = "0-9";
                isolationText.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(isolationText);
                yOff += 30;

                var gameIsolationtotal:Text = new Text(_lang.string("options_isolation_notes"));
                gameIsolationtotal.x = xOff;
                gameIsolationtotal.y = yOff;
                box.addChild(gameIsolationtotal);
                yOff += 20;

                isolationTotalText = new BoxText(100, 20);
                isolationTotalText.x = xOff;
                isolationTotalText.y = yOff;
                isolationTotalText.restrict = "0-9";
                isolationTotalText.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(isolationTotalText);
                yOff += 80;

                //- Air Options
                CONFIG::air
                {
                    var airDividerText:Text = new Text("______________________________");
                    airDividerText.x = xOff;
                    airDividerText.y = yOff;
                    box.addChild(airDividerText);
                    yOff += 30;

                    var autoSaveLocalCheckboxText:Text = new Text(_lang.string("air_options_save_local_replays"));
                    autoSaveLocalCheckboxText.x = xOff + 22;
                    autoSaveLocalCheckboxText.y = yOff;
                    box.addChild(autoSaveLocalCheckboxText);
                    yOff += 2;

                    autoSaveLocalCheckbox = new checkBox();
                    autoSaveLocalCheckbox.x = xOff + 2;
                    autoSaveLocalCheckbox.y = yOff;
                    autoSaveLocalCheckbox.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(autoSaveLocalCheckbox);
                    yOff += 30;

                    var useCacheCheckboxText:Text = new Text(_lang.string("air_options_use_cache"));
                    useCacheCheckboxText.x = xOff + 22;
                    useCacheCheckboxText.y = yOff;
                    box.addChild(useCacheCheckboxText);
                    yOff += 2;

                    useCacheCheckbox = new checkBox();
                    useCacheCheckbox.x = xOff + 2;
                    useCacheCheckbox.y = yOff;
                    useCacheCheckbox.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(useCacheCheckbox);
                    yOff += 30;

                    var useVSyncCheckboxText:Text = new Text(_lang.string("air_options_use_vsync"));
                    useVSyncCheckboxText.x = xOff + 22;
                    useVSyncCheckboxText.y = yOff;
                    box.addChild(useVSyncCheckboxText);
                    yOff += 2;

                    useVSyncCheckbox = new checkBox();
                    useVSyncCheckbox.x = xOff + 2;
                    useVSyncCheckbox.y = yOff;
                    useVSyncCheckbox.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(useVSyncCheckbox);
                    yOff += 30;
                }

                ///- Col 2
                xOff += 176;
                yOff = BASE_Y_POSITION;

                // Multiplayer - Text Size
                var gameMPTextSize:Text = new Text(_lang.string("options_mp_textsize"));
                gameMPTextSize.x = xOff;
                gameMPTextSize.y = yOff;
                box.addChild(gameMPTextSize);
                yOff += 20;

                optionMPSize = new BoxText(100, 20);
                optionMPSize.x = xOff;
                optionMPSize.y = yOff;
                optionMPSize.restrict = "0-9";
                optionMPSize.text = "10";
                optionMPSize.addEventListener(Event.CHANGE, changeHandler);
                box.addChild(optionMPSize);
                yOff += 30;

                // Multiplayer - Timestamps
                timestampCheck = new checkBox();
                timestampCheck.x = xOff + 3;
                timestampCheck.y = yOff;
                timestampCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                box.addChild(timestampCheck);

                var gameMPTimestamps:Text = new Text(_lang.string("options_mp_timestamp"));
                gameMPTimestamps.x = xOff + 23;
                gameMPTimestamps.y = yOff - 3;
                box.addChild(gameMPTimestamps);
                yOff += 30;

                // Start Up Screen
                var startUpScreenLabel:Text = new Text(_lang.string("options_startup_screen"));
                startUpScreenLabel.x = xOff;
                startUpScreenLabel.y = yOff;
                box.addChild(startUpScreenLabel);
                yOff += 20;

                startUpScreenCombo = new ComboBox(box, xOff, yOff, "Selection...", startUpScreenSelections);
                startUpScreenCombo.x = xOff;
                startUpScreenCombo.y = yOff;
                startUpScreenCombo.width = 135;
                startUpScreenCombo.openPosition = ComboBox.BOTTOM;
                startUpScreenCombo.fontSize = 11;
                startUpScreenCombo.addEventListener(Event.SELECT, startUpScreenSelect);
                yOff += 30;

                ///- Col 3
                xOff += 176;
                yOff = BASE_Y_POSITION;

                //- Game Languages
                optionGameLanguages = [];
                var gameLanguageLabel:Text = new Text(_lang.string("options_game_language"));
                gameLanguageLabel.x = xOff;
                gameLanguageLabel.y = yOff;
                box.addChild(gameLanguageLabel);
                yOff += 20;

                for (var id:String in _lang.indexed)
                {
                    var lang:String = _lang.indexed[id];
                    var gameLanguageOptionText:Text = new Text(_lang.string2("_real_name", lang) + (_lang.data[lang]['_en_name'] != _lang.data[lang]['_real_name'] ? (' / ' + _lang.string2("_en_name", lang)) : ''));
                    gameLanguageOptionText.x = xOff + 22;
                    gameLanguageOptionText.y = yOff;
                    box.addChild(gameLanguageOptionText);
                    yOff += 2;

                    var optionLanguageCheck:checkBox = new checkBox();
                    optionLanguageCheck.x = xOff + 2;
                    optionLanguageCheck.y = yOff;
                    optionLanguageCheck.languageID = lang;
                    optionLanguageCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    box.addChild(optionLanguageCheck);
                    optionGameLanguages.push(optionLanguageCheck);
                    yOff += 20;
                }

                ///- Col 4
                xOff += 176;
                yOff = BASE_Y_POSITION;

                // Game Engine
                var gameEngineLabel:Text = new Text(_lang.string("options_game_engine"));
                gameEngineLabel.x = xOff;
                gameEngineLabel.y = yOff;
                box.addChild(gameEngineLabel);
                yOff += 20;

                engineCombo = new ComboBox();
                engineCombo.x = xOff;
                engineCombo.y = yOff;
                engineCombo.width = 185;
                engineCombo.openPosition = ComboBox.BOTTOM;
                engineCombo.fontSize = 11;
                engineCombo.addEventListener(Event.SELECT, engineSelect);
                box.addChild(engineCombo);
                yOff += 30;

                // Default Game Engine
                var gameEngineDefaultLabel:Text = new Text(_lang.string("options_default_game_engine"));
                gameEngineDefaultLabel.x = xOff;
                gameEngineDefaultLabel.y = yOff;
                box.addChild(gameEngineDefaultLabel);
                yOff += 20;

                engineDefaultCombo = new ComboBox();
                engineDefaultCombo.x = xOff;
                engineDefaultCombo.y = yOff;
                engineDefaultCombo.width = 185;
                engineDefaultCombo.openPosition = ComboBox.BOTTOM;
                engineDefaultCombo.fontSize = 11;
                engineDefaultCombo.addEventListener(Event.SELECT, engineDefaultSelect);
                box.addChild(engineDefaultCombo);
                engineRefresh();
                yOff += 30;


                // Legacy Song Display
                legacySongsCheck = new checkBox();
                legacySongsCheck.x = xOff + 3;
                legacySongsCheck.y = yOff;
                legacySongsCheck.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                legacySongsCheck.addEventListener(MouseEvent.MOUSE_OVER, e_legacyEngineMouseOver, false, 0, true);
                box.addChild(legacySongsCheck);

                var gameLegacySongsCheck:Text = new Text(_lang.string("options_include_legacy_songs"));
                gameLegacySongsCheck.x = xOff + 23;
                gameLegacySongsCheck.y = yOff - 3;
                box.addChild(gameLegacySongsCheck);
                yOff += 30;
            }
            setSettings();
            checkMods();
        }

        private function changeHandler(e:Event):void
        {
            if (e.target == optionGameSpeed)
            {
                _gvars.activeUser.gameSpeed = parseFloat(optionGameSpeed.text);
                if (isNaN(_gvars.activeUser.gameSpeed) || _gvars.activeUser.gameSpeed <= 0.1)
                {
                    _gvars.activeUser.gameSpeed = 1;
                }
            }
            else if (e.target == optionOffset)
            {
                _gvars.activeUser.GLOBAL_OFFSET = parseFloat(optionOffset.text);
                if (isNaN(_gvars.activeUser.GLOBAL_OFFSET))
                {
                    _gvars.activeUser.GLOBAL_OFFSET = 0;
                }
            }
            else if (e.target == optionJudgeOffset)
            {
                _gvars.activeUser.JUDGE_OFFSET = parseFloat(optionJudgeOffset.text);
                if (isNaN(_gvars.activeUser.JUDGE_OFFSET))
                {
                    _gvars.activeUser.JUDGE_OFFSET = 0;
                }
            }
            else if (e.target == optionReceptorSpacing)
            {
                _gvars.activeUser.receptorGap = parseInt(optionReceptorSpacing.text);
                if (isNaN(_gvars.activeUser.receptorGap))
                {
                    _gvars.activeUser.receptorGap = 80;
                }
            }
            else if (e.target == optionNoteScale)
            {
                var snapValue:int = Math.floor(optionNoteScale.slideValue * 100 / 5) * 5;
                _gvars.activeUser.noteScale = snapValue / 100;
                if (isNaN(_gvars.activeUser.noteScale))
                {
                    _gvars.activeUser.noteScale = 1;
                }
                _gvars.activeUser.noteScale = Math.max(Math.min(_gvars.activeUser.noteScale, optionNoteScale.maxValue), 0.2);
                noteScaleValueDisplay.text = Math.round(_gvars.activeUser.noteScale * 100) + "%";
            }
            else if (e.target == optionGameVolume)
            {
                _gvars.activeUser.gameVolume = optionGameVolume.slideValue;
                if (isNaN(_gvars.activeUser.gameVolume))
                {
                    _gvars.activeUser.gameVolume = 1;
                }
                _gvars.activeUser.gameVolume = Math.max(Math.min(_gvars.activeUser.gameVolume, optionGameVolume.maxValue), optionGameVolume.minValue);
                gameVolumeValueDisplay.text = Math.round(_gvars.activeUser.gameVolume * 100) + "%";
            }
            else if (e.target == optionFPS)
            {
                _gvars.activeUser.frameRate = parseInt(optionFPS.text);
                if (isNaN(_gvars.activeUser.frameRate))
                    _gvars.activeUser.frameRate = 60;
                _gvars.activeUser.frameRate = Math.max(Math.min(_gvars.activeUser.frameRate, 250), 10);
                forceJudgeCheck.visible = gameForceJudgeMode.visible = (_gvars.activeUser.frameRate <= 30);
                _gvars.removeSongFiles();
            }
            else if (e.target == optionRate)
            {
                _gvars.activeUser.songRate = parseFloat(optionRate.text);
                if (isNaN(_gvars.activeUser.songRate) || _gvars.activeUser.songRate < 0.1)
                    _gvars.activeUser.songRate = 1;
                _gvars.removeSongFiles();
            }
            else if (e.target == isolationText)
            {
                _avars.configIsolationStart = Math.max(parseInt(isolationText.text) - 1, 0);
                _avars.configIsolation = _avars.configIsolationStart > 0 || _avars.configIsolationLength > 0;
            }
            else if (e.target == isolationTotalText)
            {
                _avars.configIsolationLength = Math.max(parseInt(isolationTotalText.text), 0);
                _avars.configIsolation = _avars.configIsolationStart > 0 || _avars.configIsolationLength > 0;
            }
            else if (e.target == optionMPSize)
            {
                _avars.configMPSize = parseInt(optionMPSize.text);
                if (isNaN(_avars.configMPSize))
                    _avars.configMPSize = 10;
                Style.fontSize = _avars.configMPSize;
                _avars.mpSave();
            }
            else if (e.target.hasOwnProperty("autofail"))
            {
                var t:BoxText = e.target as BoxText;
                var autofail:String = StringUtil.upperCase(t.autofail);
                _gvars.activeUser["autofail" + autofail] = parseInt(t.text);
                if (isNaN(_gvars.activeUser["autofail" + autofail]) || _gvars.activeUser["autofail" + autofail] < 0)
                    _gvars.activeUser["autofail" + autofail] = 0;
            }
            else if (e.target.hasOwnProperty("judge_color_id"))
            {
                var jid:int = e.target.judge_color_id;
                var newColorJ:int = parseInt("0x" + e.target.text.replace("#", ""), 16);
                if (isNaN(newColorJ) || newColorJ < 0)
                    newColorJ = 0;
                _gvars.activeUser.judgeColours[jid] = newColorJ;
                optionJudgeColors[jid]["display"].color = _gvars.activeUser.judgeColours[jid];
            }
            else if (e.target.hasOwnProperty("combo_color_id"))
            {
                var cid:int = e.target.combo_color_id;
                var newColorC:int = parseInt("0x" + e.target.text.replace("#", ""), 16);
                if (isNaN(newColorC) || newColorC < 0)
                    newColorC = 0;
                _gvars.activeUser.comboColours[cid] = newColorC;
                optionComboColors[cid]["display"].color = _gvars.activeUser.comboColours[cid];
            }
            else if (e.target.hasOwnProperty("game_color_id"))
            {
                var gid:int = e.target.game_color_id;
                var newColorG:int = parseInt("0x" + e.target.text.replace("#", ""), 16);
                if (isNaN(newColorG) || newColorG < 0)
                    newColorG = 0;
                _gvars.activeUser.gameColours[gid] = newColorG;

                if (gid == 0)
                    _gvars.activeUser.gameColours[2] = ColorUtil.darkenColor(newColorG, 0.27);
                if (gid == 1)
                    _gvars.activeUser.gameColours[3] = ColorUtil.brightenColor(newColorG, 0.08);

                optionGameColors[gid]["display"].color = _gvars.activeUser.gameColours[gid];
            }
            else if (e.target is ColorField)
            {
                var sourceArray:Array;
                switch (e.target.key_name)
                {
                    case "optionJudgeColor":
                        sourceArray = optionJudgeColors;
                        break;
                    case "gameComboColorDisplay":
                        sourceArray = optionComboColors;
                        break;
                    case "gameGameColorDisplay":
                        sourceArray = optionGameColors;
                        break;
                }
                for each (var item:Object in sourceArray)
                {
                    if (item.display == e.target)
                    {
                        (item.text as BoxText).text = "#" + StringUtil.pad((e.target as ColorField).color.toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                        (item.text as BoxText).dispatchEvent(new Event(Event.CHANGE));
                    }
                }
            }
            else if (e.target == optionMenuVolume)
            {
                _gvars.menuMusicSoundVolume = optionMenuVolume.slideValue;
                if (isNaN(_gvars.menuMusicSoundVolume))
                {
                    _gvars.menuMusicSoundVolume = 1;
                }
                _gvars.menuMusicSoundVolume = Math.max(Math.min(_gvars.menuMusicSoundVolume, optionMenuVolume.maxValue), optionMenuVolume.minValue);
                menuVolumeValueDisplay.text = Math.round(_gvars.menuMusicSoundVolume * 100) + "%";
                _gvars.menuMusicSoundTransform.volume = _gvars.menuMusicSoundVolume;

                if (_gvars.menuMusic && _gvars.menuMusic.isPlaying)
                {
                    _gvars.menuMusic.soundChannel.soundTransform = _gvars.menuMusicSoundTransform;
                }
            }

            checkMods();
        }

        private function keyDownHandler(e:KeyboardEvent):void
        {
            if (keyListenerTarget)
            {
                var keyCode:uint = e.keyCode;
                var keyChar:String = StringUtil.keyCodeChar(keyCode);
                if (keyChar != "")
                {
                    _gvars.activeUser["key" + StringUtil.upperCase(keyListenerTarget.key)] = keyCode;
                    keyListenerTarget = null;
                    setSettings();
                }
            }
        }

        private function e_autoJudgeMouseOver(e:Event):void
        {
            autoJudgeOffsetCheck.addEventListener(MouseEvent.MOUSE_OUT, e_autoJudgeMouseOut);
            displayToolTip(autoJudgeOffsetCheck.x + 40, autoJudgeOffsetCheck.y + 15, _lang.string("popup_auto_judge_offset"));
        }

        private function e_autoJudgeMouseOut(e:Event):void
        {
            autoJudgeOffsetCheck.removeEventListener(MouseEvent.MOUSE_OUT, e_autoJudgeMouseOut);
            removeChild(hover_message);
        }

        private function e_legacyEngineMouseOver(e:Event):void
        {
            legacySongsCheck.addEventListener(MouseEvent.MOUSE_OUT, e_legacyEngineMouseOut);
            displayToolTip(legacySongsCheck.x + 16, legacySongsCheck.y + 15, _lang.string("popup_legacy_songs"), "right");
        }

        private function e_legacyEngineMouseOut(e:Event):void
        {
            legacySongsCheck.removeEventListener(MouseEvent.MOUSE_OUT, e_legacyEngineMouseOut);
            removeChild(hover_message);
        }

        private function displayToolTip(tx:Number, ty:Number, text:String, align:String = "left"):void
        {
            if (!hover_message)
                hover_message = new MouseTooltip();
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
            }

            addChild(hover_message);
        }

        private function clickHandler(e:MouseEvent):void
        {
            //- Menu Select
            if (e.target.hasOwnProperty("menu_select"))
            {
                CURRENT_TAB = e.target.menu_select;
                renderOptions();
            } //- Scroll Direction
            else if (e.target.hasOwnProperty("slideDirection"))
            {
                var dir:String = e.target.slideDirection;
                _gvars.activeUser.slideDirection = dir;
            }
            //- Keys
            else if (e.target.hasOwnProperty("key"))
            {
                setSettings();
                keyListenerTarget = e.target;
                keyListenerTarget.htmlText = _lang.string("options_key_pick");
                return;
            }
            //- Visual Mods
            else if (e.target.hasOwnProperty("visual_mod"))
            {
                var visual_mod:String = e.target.visual_mod;
                if (_gvars.activeUser.activeVisualMods.indexOf(visual_mod) != -1)
                {
                    ArrayUtil.removeValue(visual_mod, _gvars.activeUser.activeVisualMods);
                }
                else
                {
                    _gvars.activeUser.activeVisualMods.push(visual_mod);
                }
            }
            //- Mods
            else if (e.target.hasOwnProperty("mod"))
            {
                var mod:String = e.target.mod;
                if (_gvars.activeUser.activeMods.indexOf(mod) != -1)
                {
                    ArrayUtil.removeValue(mod, _gvars.activeUser.activeMods);
                }
                else
                {
                    _gvars.activeUser.activeMods.push(mod);
                }
                if (mod == "reverse")
                    _gvars.removeSongFiles();
            }
            //- Skin
            else if (e.target.hasOwnProperty("skin"))
            {
                _gvars.activeUser.activeNoteskin = e.target.skin;
            }
            //- custom Notekin
            else if (e.target == optionNoteskinsCustom)
            {
                _gvars.gameMain.addPopup(new PopupCustomNoteskin(_gvars.gameMain), true);
            }
            //- Language
            else if (e.target.hasOwnProperty("languageID"))
            {
                _gvars.activeUser.language = e.target.languageID;
                _gvars.gameMain.activePanel.draw();
                renderOptions();
            }
            //- Displays
            else if (e.target.hasOwnProperty("display"))
            {
                _gvars.activeUser["DISPLAY_" + e.target.display] = !_gvars.activeUser["DISPLAY_" + e.target.display];
                if (e.target.display == "SONG_FLAG")
                {
                    _gvars.gameMain.activePanel.draw();
                }
            }
            //- Auto Judge Offset
            else if (e.target == autoJudgeOffsetCheck)
            {
                _gvars.activeUser.AUTO_JUDGE_OFFSET = !_gvars.activeUser.AUTO_JUDGE_OFFSET;
                optionJudgeOffset.selectable = _gvars.activeUser.AUTO_JUDGE_OFFSET;
                optionJudgeOffset.alpha = _gvars.activeUser.AUTO_JUDGE_OFFSET ? 0.55 : 1.0;
            }
            // Force Judge Mode
            else if (e.target == forceJudgeCheck)
            {
                _gvars.activeUser.forceNewJudge = !_gvars.activeUser.forceNewJudge;
            }
            // MP Timestamp
            else if (e.target == timestampCheck)
            {
                _gvars.activeUser.DISPLAY_MP_TIMESTAMP = !_gvars.activeUser.DISPLAY_MP_TIMESTAMP;
            }
            // Legacy Songs
            else if (e.target == legacySongsCheck)
            {
                _gvars.activeUser.DISPLAY_LEGACY_SONGS = !_gvars.activeUser.DISPLAY_LEGACY_SONGS;
            }
            // Judge Color Reset
            else if (e.target.hasOwnProperty("judge_color_reset_id"))
            {
                _gvars.activeUser.judgeColours[e.target.judge_color_reset_id] = DEFAULT_OPTIONS.judgeColours[e.target.judge_color_reset_id];
            }
            // Combo Color Reset
            else if (e.target.hasOwnProperty("combo_color_reset_id"))
            {
                _gvars.activeUser.comboColours[e.target.combo_color_reset_id] = DEFAULT_OPTIONS.comboColours[e.target.combo_color_reset_id];
            }
            // Game Background Color Reset
            else if (e.target.hasOwnProperty("game_color_reset_id"))
            {
                var gid:int = e.target.game_color_reset_id;
                _gvars.activeUser.gameColours[gid] = DEFAULT_OPTIONS.gameColours[gid];
                if (gid == 0)
                    _gvars.activeUser.gameColours[2] = ColorUtil.darkenColor(DEFAULT_OPTIONS.gameColours[gid], 0.27);
                if (gid == 1)
                    _gvars.activeUser.gameColours[3] = ColorUtil.brightenColor(DEFAULT_OPTIONS.gameColours[gid], 0.08);
            }
            //- Editor
            else if (e.target.hasOwnProperty("editor_multiplayer"))
            {
                _gvars.options = new GameOptions();
                _gvars.options.isEditor = true;
                _gvars.options.multiplayer = e.target.editor_multiplayer;
                _gvars.options.song = new Song({level: 1337, type: "EDITOR"});
                _gvars.options.fill();
                removePopup();
                _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
                return;
            }

            //- Reset
            else if (e.target == resetOptions)
            {
                var confirmP:Window = new Window(box, 0, 0, "Confirm Settings Reset");
                confirmP.hasMinimizeButton = false;
                confirmP.hasCloseButton = false;
                confirmP.setSize(110, 105);
                confirmP.x = (box.width / 2 - confirmP.width / 2);
                confirmP.y = (box.height / 2 - confirmP.height / 2);
                box.addChild(confirmP);

                var resB:BoxButton = new BoxButton(100, 35, "RESET", 12, "#990000");
                resB.x = 5;
                resB.y = 5;
                resB.boxColor = 0x330000;
                confirmP.addChild(resB);
                resB.addEventListener(MouseEvent.CLICK, function(e:Event):void
                {
                    if (_gvars.activeUser == _gvars.playerUser)
                    {
                        _gvars.activeUser.settings = new User().settings;
                        _avars.resetSettings();
                    }
                    box.removeChild(confirmP);
                });

                var conB:BoxButton = new BoxButton(100, 35, "Close", 12, "#000000");
                conB.x = 5;
                conB.y = 45;
                conB.boxColor = 0;
                confirmP.addChild(conB);
                conB.addEventListener(MouseEvent.CLICK, function(e:Event):void
                {
                    box.removeChild(confirmP);
                });
            }

            //- Close
            else if (e.target == closeOptions)
            {
                if (_gvars.activeUser == _gvars.playerUser)
                {
                    _gvars.activeUser.saveLocal();
                    _gvars.activeUser.save();

                    // Setup Background Colours
                    try
                    { // Patch for old Loaders
                        GameBackgroundColor.BG_LIGHT = _gvars.activeUser.gameColours[0];
                        GameBackgroundColor.BG_DARK = _gvars.activeUser.gameColours[1];
                        GameBackgroundColor.BG_STATIC = _gvars.activeUser.gameColours[2];
                        GameBackgroundColor.BG_POPUP = _gvars.activeUser.gameColours[3];
                        (_gvars.gameMain.getChildAt(0) as GameBackgroundColor).redraw();
                    }
                    catch (err:Error)
                    {
                    }

                    if (_gvars.gameMain.activePanel is MainMenu && ((_gvars.gameMain.activePanel as MainMenu).panel is MenuSongSelection))
                    {
                        var panel:MenuSongSelection = ((_gvars.gameMain.activePanel as MainMenu).panel as MenuSongSelection);
                        panel.buildGenreList();
                        panel.drawPages();
                    }
                }
                SoundMixer.soundTransform = new SoundTransform(_gvars.activeUser.gameVolume);
                LocalStore.setVariable("menuMusicSoundVolume", _gvars.menuMusicSoundVolume);
                removePopup();
                return;
            }
            CONFIG::air
            {
                // Auto Save Local Replays
                if (e.target == autoSaveLocalCheckbox)
                {
                    _gvars.air_autoSaveLocalReplays = !_gvars.air_autoSaveLocalReplays;
                    LocalStore.setVariable("air_autoSaveLocalReplays", _gvars.air_autoSaveLocalReplays);
                }
                // Auto Save Local Replays
                if (e.target == useCacheCheckbox)
                {
                    _gvars.air_useLocalFileCache = !_gvars.air_useLocalFileCache;
                    LocalStore.setVariable("air_useLocalFileCache", _gvars.air_useLocalFileCache);
                }
                if (e.target == useVSyncCheckbox)
                {
                    _gvars.air_useVSync = !_gvars.air_useVSync;
                    LocalStore.setVariable("air_useVSync", _gvars.air_useVSync);
                    stage.vsyncEnabled = _gvars.air_useVSync;
                    _gvars.gameMain.addAlert("Set VSYNC: " + stage.vsyncEnabled, 120, Alert.RED);
                }
            }
            // Set Settings
            setSettings();

            // Set focus back
            stage.focus = this.stage;

            checkMods();
        }

        private function checkMods():void
        {
            var options:GameOptions = new GameOptions();
            options.fill();
            warningOptions.visible = !options.isScoreValid();
        }

        private function gameNoteColorSelect(e:Event):void
        {
            var data:Object = e.target.selectedItem.data;
            for (var i:int = 0; i < optionNoteColors.length; i++)
            {
                if (optionNoteColors[i] == e.target)
                {
                    _gvars.activeUser.noteColours[i] = data;
                }
            }
        }

        private function startUpScreenSelect(e:Event):void
        {
            _gvars.activeUser.startUpScreen = e.target.selectedItem.data as int;
        }

        private function engineDefaultSelect(e:Event):void
        {
            if (!engineComboIgnore)
            {
                _avars.legacyDefaultEngine = (e.target as ComboBox).selectedItem.data;
                _avars.legacyDefaultSave();
            }
        }

        private function engineSelect(e:Event):void
        {
            var data:Object = engineCombo.selectedItem.data;
            // Add Engine
            if (data == this)
            {
                var prompt:MultiplayerPrompt = new MultiplayerPrompt(this, "Engine URL");
                prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
                {
                    ChartFFRLegacy.parseEngine(subevent.params.value, engineAdd);
                });
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
            _gvars.gameMain.addAlert("Engine Loaded: " + engine.name, 80);
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
            engineCombo.addItem({label: Constant.BRAND_NAME(), data: null});
            engineDefaultCombo.addItem({label: Constant.BRAND_NAME(), data: null});
            engineCombo.selectedIndex = 0;
            engineDefaultCombo.selectedIndex = 0;
            for each (var engine:Object in _avars.legacyEngines)
            {
                var item:Object = {label: engine.name, data: engine};
                if (!ChartFFRLegacy.validURL(engine["playlistURL"]))
                    continue;
                if (engine["config_url"] == null)
                {
                    _gvars.gameMain.addAlert("Please re-add " + engine["name"] + ", missing required information.", 240, Alert.RED);
                    continue;
                }
                engineCombo.addItem(item);
                engineDefaultCombo.addItem(item);
                if (engine == _avars.configLegacy || (_avars.configLegacy && engine["id"] == _avars.configLegacy["id"]))
                    engineCombo.selectedItem = item;
                if (engine == _avars.legacyDefaultEngine || (_avars.legacyDefaultEngine && engine["id"] == _avars.legacyDefaultEngine["id"]))
                    engineDefaultCombo.selectedItem = item;
            }
            engineCombo.addItem({label: "Add Engine...", data: this});
            if (_avars.legacyEngines.length > 0 && engineCombo.items.length > 2)
                engineCombo.addItem({label: "Clear Engines", data: engineCombo});
            engineComboIgnore = false;
        }

        public function setSettings():void
        {
            var i:int;

            if (box == null)
            {
                return;
            }

            if (CURRENT_TAB == TAB_MAIN)
            {
                // Set Speed
                optionGameSpeed.text = _gvars.activeUser.gameSpeed.toString();

                // Set Scroll
                for each (var item:Object in optionScrollDirections)
                {
                    item.gotoAndStop(_gvars.activeUser.slideDirection == item.slideDirection ? 2 : 1);
                }

                // Set Keys
                for each (item in optionKeyInputs)
                {
                    item.text = StringUtil.keyCodeChar(_gvars.activeUser["key" + StringUtil.upperCase(item.key)]).toUpperCase();
                }

                // Set Offset
                optionOffset.text = _gvars.activeUser.GLOBAL_OFFSET.toString();

                // Set Judge Offset
                optionJudgeOffset.text = _gvars.activeUser.JUDGE_OFFSET.toString();

                // Set Auto Judge Offset
                autoJudgeOffsetCheck.gotoAndStop(_gvars.activeUser.AUTO_JUDGE_OFFSET ? 2 : 1);
                optionJudgeOffset.selectable = !_gvars.activeUser.AUTO_JUDGE_OFFSET;
                optionJudgeOffset.alpha = _gvars.activeUser.AUTO_JUDGE_OFFSET ? 0.55 : 1.0;

                // Set Receptor Spacing
                optionReceptorSpacing.text = _gvars.activeUser.receptorGap.toString();

                // Set Note Scale
                optionNoteScale.slideValue = _gvars.activeUser.noteScale;

                // Set Volume
                optionGameVolume.slideValue = _gvars.activeUser.gameVolume;

                // Set Menu Volume
                optionMenuVolume.slideValue = _gvars.menuMusicSoundVolume;

                // Set Framerate
                optionFPS.text = _gvars.activeUser.frameRate.toString();

                // Set Song Rate
                if (optionRate != null)
                {
                    optionRate.text = _gvars.activeUser.songRate.toString();
                }

                forceJudgeCheck.gotoAndStop(_gvars.activeUser.forceNewJudge ? 2 : 1);
                forceJudgeCheck.visible = gameForceJudgeMode.visible = (_gvars.activeUser.frameRate <= 30);

                // Set Autofails
                for each (item in optionAutofail)
                {
                    item.text = _gvars.activeUser["autofail" + StringUtil.upperCase(item.autofail)];
                }
            }
            else if (CURRENT_TAB == TAB_VISUAL_MODS)
            {
                // Set Game Mods
                for each (item in optionGameMods)
                {
                    item.gotoAndStop(_gvars.activeUser.activeMods.indexOf(item.mod) != -1 ? 2 : 1);
                }

                // Set Visual Game Mods
                for each (item in optionVisualGameMods)
                {
                    item.gotoAndStop(_gvars.activeUser.activeVisualMods.indexOf(item.visual_mod) != -1 ? 2 : 1);
                }

                // Set Noteskin
                for each (item in optionNoteskins)
                {
                    item.gotoAndStop(item.skin == _gvars.activeUser.activeNoteskin ? 2 : 1);
                }
                if (optionNoteskinPreview != null)
                {
                    if (box.contains(optionNoteskinPreview))
                        box.removeChild(optionNoteskinPreview);
                    optionNoteskinPreview.dispose();
                    optionNoteskinPreview = null;
                }
                optionNoteskinPreview = new GameNote(0, "U", "blue", 0, 0, 0, _gvars.activeUser.activeNoteskin);
                optionNoteskinPreview.x = 690;
                optionNoteskinPreview.y = 90;
                optionNoteskinPreview.rotation = (_noteskins.getInfo(_gvars.activeUser.activeNoteskin).rotation * 2);
                optionNoteskinPreview.scaleX = optionNoteskinPreview.scaleY = Math.min(1, (64 / Math.max(optionNoteskinPreview.width, optionNoteskinPreview.height)));
                box.addChild(optionNoteskinPreview);

                // Set Display
                for each (item in optionDisplays)
                {
                    item.gotoAndStop(_gvars.activeUser["DISPLAY_" + item.display] ? 2 : 1);
                }
            }
            else if (CURRENT_TAB == TAB_COLORS)
            {
                // Set Judge Colors
                for (i = 0; i < judgeTitles.length; i++)
                {
                    optionJudgeColors[i]["text"].text = "#" + StringUtil.pad(_gvars.activeUser.judgeColours[i].toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                    optionJudgeColors[i]["display"].color = _gvars.activeUser.judgeColours[i];
                }
                for (i = 0; i < DEFAULT_OPTIONS.comboColours.length; i++)
                {
                    optionComboColors[i]["text"].text = "#" + StringUtil.pad(_gvars.activeUser.comboColours[i].toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                    optionComboColors[i]["display"].color = _gvars.activeUser.comboColours[i];
                }
                for (i = 0; i < DEFAULT_OPTIONS.gameColours.length; i++)
                {
                    if (i == 2 || i == 3)
                        continue;
                    optionGameColors[i]["text"].text = "#" + StringUtil.pad(_gvars.activeUser.gameColours[i].toString(16).substr(0, 6), 6, "0", StringUtil.STR_PAD_LEFT);
                    optionGameColors[i]["display"].color = _gvars.activeUser.gameColours[i];
                }
                for (i = 0; i < DEFAULT_OPTIONS.noteColors.length; i++)
                {
                    (optionNoteColors[i] as ComboBox).selectedItemByData = _gvars.activeUser.noteColours[i];
                }
            }
            else if (CURRENT_TAB == TAB_OTHER)
            {
                isolationText.text = (_avars.configIsolationStart + 1).toString();
                isolationTotalText.text = _avars.configIsolationLength.toString();

                timestampCheck.gotoAndStop(_gvars.activeUser.DISPLAY_MP_TIMESTAMP ? 2 : 1);
                legacySongsCheck.gotoAndStop(_gvars.activeUser.DISPLAY_LEGACY_SONGS ? 2 : 1);
                optionMPSize.text = _avars.configMPSize.toString();
                startUpScreenCombo.selectedIndex = _gvars.activeUser.startUpScreen;

                // Set Language
                for each (item in optionGameLanguages)
                {
                    item.gotoAndStop(item.languageID == _gvars.activeUser.language ? 2 : 1);
                }

                CONFIG::air
                {
                    autoSaveLocalCheckbox.gotoAndStop(_gvars.air_autoSaveLocalReplays ? 2 : 1);
                    useCacheCheckbox.gotoAndStop(_gvars.air_useLocalFileCache ? 2 : 1);
                    useVSyncCheckbox.gotoAndStop(_gvars.air_useVSync ? 2 : 1);
                }
            }
            // Save Local
            if (_gvars.activeUser == _gvars.playerUser)
            {
                _gvars.activeUser.saveLocal();
            }
        }

        private function arcJudgeMenu():ContextMenu
        {
            var judgeMenu:ContextMenu = new ContextMenu();
            var judgeItem:ContextMenuItem = new ContextMenuItem("Custom Judge Windows");
            var self:PopupOptions = this;
            judgeItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
            {
                var prompt:MultiplayerPrompt = new MultiplayerPrompt(self, "Judge Window");
                prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
                {
                    _avars.configJudge = null;
                    var judge:Array;
                    for each (var item:String in subevent.params.value.split(":"))
                    {
                        if (!judge)
                            judge = new Array();
                        var items:Array = item.split(",");
                        if (items.length != 2)
                        {
                            judge = null;
                            break;
                        }
                        judge.push({t: parseInt(items[0]), s: parseInt(items[1])});
                    }
                    _avars.configJudge = judge;
                    if (judge)
                        _gvars.gameMain.addAlert("Judge window set, score saving disabled");
                    else
                        _gvars.gameMain.addAlert("Judge window cleared");
                });
            });
            judgeMenu.customItems.push(judgeItem);
            return judgeMenu;
        }
    }
}
