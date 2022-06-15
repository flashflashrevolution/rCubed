package popups.settings
{
    import arc.ArcGlobals;
    import classes.Alert;
    import classes.Language;
    import classes.ui.BoxCheck;
    import classes.ui.BoxSlider;
    import classes.ui.Prompt;
    import classes.ui.Text;
    import classes.ui.ValidatedText;
    import com.flashfla.utils.ArrayUtil;
    import com.flashfla.utils.StringUtil;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;

    public class SettingsTabGeneral extends SettingsTabBase
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;

        private var optionGameSpeed:ValidatedText;
        private var optionReceptorSpacing:ValidatedText;
        private var textNoteScale:Text;
        private var optionNoteScale:BoxSlider;
        private var textGameVolume:Text;
        private var optionGameVolume:BoxSlider;
        private var textMenuVolume:Text;
        private var optionMenuVolume:BoxSlider;

        private var optionOffset:ValidatedText;
        private var optionJudgeOffset:ValidatedText;
        private var optionJudgeOffsetAuto:BoxCheck;
        private var optionAutofail:Array;
        private var optionAutofailRestart:BoxCheck;

        private var optionScrollDirections:Vector.<BoxCheck>;
        private var optionMirrorMod:BoxCheck;
        private var optionRate:ValidatedText;
        private var optionIsolation:ValidatedText;
        private var optionIsolationTotal:ValidatedText;

        public function SettingsTabGeneral(settingsWindow:SettingsWindow):void
        {
            super(settingsWindow);
        }

        override public function get name():String
        {
            return "general";
        }

        override public function openTab():void
        {
            container.graphics.beginFill(0, 0.05);
            container.graphics.drawRect(198, 0, 196, 418);
            container.graphics.endFill();

            container.graphics.lineStyle(1, 0xFFFFFF, 0.05);
            container.graphics.moveTo(197, 0);
            container.graphics.lineTo(197, 418);
            container.graphics.moveTo(394, 0);
            container.graphics.lineTo(394, 418);

            var i:int;
            var xOff:int = 15;
            var yOff:int = 15;

            /// Col 1
            //- Speed
            new Text(container, xOff, yOff, _lang.string("options_speed"));
            yOff += 22;

            optionGameSpeed = new ValidatedText(container, xOff, yOff, 130, 20, ValidatedText.R_FLOAT_P, changeHandler);
            yOff += 30;

            //- Receptor Spacing
            new Text(container, xOff, yOff, _lang.string("options_receptor_spacing"));
            yOff += 22;

            optionReceptorSpacing = new ValidatedText(container, xOff, yOff, 130, 20, ValidatedText.R_INT, changeHandler);
            yOff += 30;

            yOff += drawSeperator(container, xOff, 170, yOff, 2, 4);

            //- Note Scale
            new Text(container, xOff, yOff, _lang.string("options_note_scale"));
            yOff += 22;

            optionNoteScale = new BoxSlider(container, xOff, yOff, 130, 10, changeHandler);
            optionNoteScale.minValue = 0.1;
            optionNoteScale.maxValue = 1.5;
            yOff += 10;

            textNoteScale = new Text(container, xOff, yOff, Math.round(_gvars.activeUser.noteScale * 100) + "%");
            yOff += 30;

            yOff += drawSeperator(container, xOff, 170, yOff, -4, 5);

            // Game Volume
            new Text(container, xOff, yOff, _lang.string("options_volume"));
            yOff += 22;

            optionGameVolume = new BoxSlider(container, xOff, yOff, 130, 10, changeHandler);
            optionGameVolume.maxValue = 1.25;
            yOff += 10;

            textGameVolume = new Text(container, xOff, yOff, Math.round(_gvars.activeUser.gameVolume * 100) + "%");
            yOff += 30;

            // Menu Music Volume
            new Text(container, xOff, yOff, _lang.string("air_options_menu_volume"));
            yOff += 22;

            optionMenuVolume = new BoxSlider(container, xOff, yOff, 130, 10, changeHandler);
            optionMenuVolume.maxValue = 1.25;
            yOff += 10;

            textMenuVolume = new Text(container, xOff, yOff, Math.round(_gvars.menuMusicSoundVolume * 100) + "%");
            yOff += 30;

            /// Col 2
            xOff = 211;
            yOff = 15;

            //- Global Offset
            new Text(container, xOff, yOff, _lang.string("options_global_offset"));
            yOff += 22;

            optionOffset = new ValidatedText(container, xOff, yOff, 130, 20, ValidatedText.R_FLOAT, changeHandler);
            yOff += 30;

            //- Judge Offset
            var judgeOffsetText:Text = new Text(container, xOff, yOff, _lang.string("options_judge_offset"));
            judgeOffsetText.mouseEnabled = true;
            judgeOffsetText.contextMenu = arcJudgeMenu(parent);
            yOff += 22;

            optionJudgeOffset = new ValidatedText(container, xOff, yOff, 130, 20, ValidatedText.R_FLOAT, changeHandler);
            yOff += 30;

            //- Auto Judge Offset
            new Text(container, xOff + 22, yOff, _lang.string("options_auto_judge_offset"));

            optionJudgeOffsetAuto = new BoxCheck(container, xOff + 2, yOff + 3, clickHandler);
            optionJudgeOffsetAuto.addEventListener(MouseEvent.MOUSE_OVER, e_autoJudgeMouseOver, false, 0, true);
            yOff += 25;

            yOff += drawSeperator(container, xOff, 170, yOff, 3, 5);

            // Autofail
            optionAutofail = [];

            new Text(container, xOff, yOff, _lang.string("options_autofail"));
            yOff += 22;

            for (i = 0; i < judgeTitles.length; i++)
            {
                new Text(container, xOff + 72, yOff + 1, _lang.string("game_" + judgeTitles[i]));

                var optionAutofailInput:ValidatedText = new ValidatedText(container, xOff, yOff, 65, 20, ValidatedText.R_INT_P, changeHandler);
                optionAutofailInput.autofail = judgeTitles[i];
                optionAutofailInput.field.maxChars = 5;
                optionAutofail.push(optionAutofailInput);
                yOff += 25;
            }
            // raw goods aren't a judge title, and is two words - so separate accordingly
            new Text(container, xOff + 72, yOff + 1, _lang.string("game_raw_goods"));

            optionAutofailInput = new ValidatedText(container, xOff, yOff, 65, 20, ValidatedText.R_FLOAT_P, changeHandler);
            optionAutofailInput.autofail = "rawGoods";
            optionAutofailInput.field.maxChars = 6;
            optionAutofail.push(optionAutofailInput);
            yOff += 34;

            // Autofail Restart
            new Text(container, xOff + 22, yOff - 4, _lang.string("options_autofail_restart"));

            optionAutofailRestart = new BoxCheck(container, xOff, yOff, clickHandler);
            yOff += 25;

            /// Col 3
            xOff = 407;
            yOff = 15;

            //- Direction
            optionScrollDirections = new <BoxCheck>[];

            new Text(container, xOff, yOff, _lang.string("options_scroll"));
            yOff += 20;

            var directionData:Array = _gvars.SCROLL_DIRECTIONS;
            for (i = 0; i < directionData.length; i++)
            {
                new Text(container, xOff + 22, yOff - 1, _lang.string("options_scroll_" + directionData[i]));

                var optionScrollCheck:BoxCheck = new BoxCheck(container, xOff + 2, yOff + 3, clickHandler);
                optionScrollCheck.slideDirection = directionData[i];
                optionScrollDirections.push(optionScrollCheck);
                yOff += 21;
            }

            yOff += drawSeperator(container, xOff, 170, yOff, 5, 6);

            // Mirror Mod
            new Text(container, xOff + 22, yOff - 1, _lang.string("options_mod_mirror"));

            optionMirrorMod = new BoxCheck(container, xOff + 2, yOff + 3, clickHandler);
            optionMirrorMod.visual_mod = "mirror";
            yOff += 25;

            yOff += drawSeperator(container, xOff, 170, yOff, 1);

            // Song Rate
            new Text(container, xOff, yOff, _lang.string("options_rate"));
            yOff += 22;

            optionRate = new ValidatedText(container, xOff, yOff, 130, 20, ValidatedText.R_FLOAT_P, changeHandler);
            yOff += 30;

            //- Isolation
            new Text(container, xOff, yOff, _lang.string("options_isolation_start"));
            yOff += 22;

            optionIsolation = new ValidatedText(container, xOff, yOff, 130, 20, ValidatedText.R_INT_P, changeHandler);
            yOff += 30;

            new Text(container, xOff, yOff, _lang.string("options_isolation_notes"));
            yOff += 22;

            optionIsolationTotal = new ValidatedText(container, xOff, yOff, 130, 20, ValidatedText.R_INT_P, changeHandler);
            yOff += 30;

            // set Text class max width
            setTextMaxWidth(166);
        }

        override public function setValues():void
        {
            var i:int;
            var item:*;

            // Set Speed
            optionGameSpeed.text = _gvars.activeUser.gameSpeed.toString();

            // Set Scroll
            for each (item in optionScrollDirections)
            {
                item.checked = (_gvars.activeUser.slideDirection == item.slideDirection);
            }

            // Set Offset
            optionOffset.text = _gvars.activeUser.GLOBAL_OFFSET.toString();

            // Set Judge Offset
            optionJudgeOffset.text = _gvars.activeUser.JUDGE_OFFSET.toString();

            // Set Auto Judge Offset
            optionJudgeOffsetAuto.checked = _gvars.activeUser.AUTO_JUDGE_OFFSET;
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

            // Set Song Rate
            optionRate.text = _gvars.activeUser.songRate.toString();

            // Mirror Mod
            optionMirrorMod.checked = (_gvars.activeUser.activeVisualMods.indexOf(optionMirrorMod.visual_mod) != -1);

            // Set Autofails
            for each (item in optionAutofail)
            {
                item.text = _gvars.activeUser["autofail" + StringUtil.upperCase(item.autofail)];
            }

            // Autofail Restart
            optionAutofailRestart.checked = _gvars.activeUser.autofailRestart;

            optionIsolation.text = (_avars.configIsolationStart + 1).toString();
            optionIsolationTotal.text = _avars.configIsolationLength.toString();
        }

        override public function clickHandler(e:MouseEvent):void
        {
            var item:*;

            if (e.target == optionJudgeOffsetAuto)
            {
                _gvars.activeUser.AUTO_JUDGE_OFFSET = !_gvars.activeUser.AUTO_JUDGE_OFFSET;
                optionJudgeOffset.selectable = !_gvars.activeUser.AUTO_JUDGE_OFFSET;
                optionJudgeOffset.alpha = _gvars.activeUser.AUTO_JUDGE_OFFSET ? 0.55 : 1.0;
                optionJudgeOffsetAuto.checked = _gvars.activeUser.AUTO_JUDGE_OFFSET;
            }

            else if (e.target == optionAutofailRestart)
            {
                _gvars.activeUser.autofailRestart = !_gvars.activeUser.autofailRestart;
                optionAutofailRestart.checked = _gvars.activeUser.autofailRestart;
            }

            else if (e.target.hasOwnProperty("slideDirection"))
            {
                var dir:String = e.target.slideDirection;
                _gvars.activeUser.slideDirection = dir;

                for each (item in optionScrollDirections)
                {
                    item.checked = (_gvars.activeUser.slideDirection == item.slideDirection);
                }
            }

            else if (e.target == optionMirrorMod)
            {
                var visual_mod:String = optionMirrorMod.visual_mod;
                if (_gvars.activeUser.activeVisualMods.indexOf(visual_mod) != -1)
                {
                    ArrayUtil.removeValue(visual_mod, _gvars.activeUser.activeVisualMods);
                }
                else
                {
                    _gvars.activeUser.activeVisualMods.push(visual_mod);
                }
                optionMirrorMod.checked = !optionMirrorMod.checked;
            }

            parent.checkValidMods();
        }

        override public function changeHandler(e:Event):void
        {
            if (e.target == optionGameSpeed)
            {
                _gvars.activeUser.gameSpeed = optionGameSpeed.validate(1, 0.1);
            }

            else if (e.target == optionOffset)
            {
                _gvars.activeUser.GLOBAL_OFFSET = optionOffset.validate(0);
            }

            else if (e.target == optionJudgeOffset)
            {
                _gvars.activeUser.JUDGE_OFFSET = optionJudgeOffset.validate(0);
            }

            else if (e.target == optionReceptorSpacing)
            {
                _gvars.activeUser.receptorGap = optionReceptorSpacing.validate(80);
            }

            else if (e.target == optionNoteScale)
            {
                var sliderValue:int = Math.round(Math.max(Math.min(optionNoteScale.slideValue, optionNoteScale.maxValue), optionNoteScale.minValue) * 100);

                // Snap to larger value when close.
                var snapTarget:int = 25;
                var snapValue:int = sliderValue % snapTarget;
                if (snapValue == 1 || snapValue == snapTarget - 1)
                    sliderValue = Math.round(sliderValue / snapTarget) * snapTarget;

                _gvars.activeUser.noteScale = sliderValue / 100;
                textNoteScale.text = sliderValue + "%";
            }

            else if (e.target == optionGameVolume)
            {
                _gvars.activeUser.gameVolume = optionGameVolume.slideValue;
                textGameVolume.text = Math.round(_gvars.activeUser.gameVolume * 100) + "%";
            }

            else if (e.target == optionRate)
            {
                _gvars.activeUser.songRate = optionRate.validate(1, 0.1);
                _gvars.removeSongFiles();
            }

            else if (e.target == optionIsolation)
            {
                _avars.configIsolationStart = optionIsolation.validate(1, 1) - 1;
                _avars.configIsolation = _avars.configIsolationStart > 0 || _avars.configIsolationLength > 0;
            }

            else if (e.target == optionIsolationTotal)
            {
                _avars.configIsolationLength = optionIsolationTotal.validate(0);
                _avars.configIsolation = _avars.configIsolationStart > 0 || _avars.configIsolationLength > 0;
            }

            else if (e.target == optionMenuVolume)
            {
                _gvars.menuMusicSoundVolume = optionMenuVolume.slideValue;
                if (isNaN(_gvars.menuMusicSoundVolume))
                {
                    _gvars.menuMusicSoundVolume = 1;
                }
                _gvars.menuMusicSoundVolume = Math.max(Math.min(_gvars.menuMusicSoundVolume, optionMenuVolume.maxValue), optionMenuVolume.minValue);
                textMenuVolume.text = Math.round(_gvars.menuMusicSoundVolume * 100) + "%";
                _gvars.menuMusicSoundTransform.volume = _gvars.menuMusicSoundVolume;

                if (_gvars.menuMusic && _gvars.menuMusic.isPlaying)
                {
                    _gvars.menuMusic.soundChannel.soundTransform = _gvars.menuMusicSoundTransform;
                }
            }

            else if (e.target.hasOwnProperty("autofail"))
            {
                var autofail:String = StringUtil.upperCase(e.target.autofail);
                _gvars.activeUser["autofail" + autofail] = e.target.validate(0, 0);
            }

            parent.checkValidMods();
        }

        private function e_autoJudgeMouseOver(e:Event):void
        {
            optionJudgeOffsetAuto.addEventListener(MouseEvent.MOUSE_OUT, e_autoJudgeMouseOut);
            displayToolTip(optionJudgeOffsetAuto.x, optionJudgeOffsetAuto.y + 25, _lang.string("popup_auto_judge_offset"));
        }

        private function e_autoJudgeMouseOut(e:Event):void
        {
            optionJudgeOffsetAuto.removeEventListener(MouseEvent.MOUSE_OUT, e_autoJudgeMouseOut);
            hideTooltip();
        }

        private function arcJudgeMenu(parent:SettingsWindow):ContextMenu
        {
            var judgeMenu:ContextMenu = new ContextMenu();
            var judgeItem:ContextMenuItem = new ContextMenuItem("Custom Judge Windows");
            judgeItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void
            {
                new Prompt(parent, 320, "Judge Window", 100, "SUBMIT", e_changeJudgeWindow);
            });
            judgeMenu.customItems.push(judgeItem);
            return judgeMenu;
        }

        private function e_changeJudgeWindow(judgeWindow:String):void
        {
            _avars.configJudge = null;
            var judge:Array;
            for each (var item:String in judgeWindow.split(":"))
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
            {
                Alert.add(_lang.string("judge_window_set"));
            }
            else
            {
                Alert.add(_lang.string("judge_window_cleared"));
            }
        }
    }
}
