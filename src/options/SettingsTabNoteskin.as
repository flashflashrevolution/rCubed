package options
{
    import assets.menu.icons.fa.iconRefresh;
    import classes.Alert;
    import classes.Language;
    import classes.Noteskins;
    import classes.NoteskinsStruct;
    import classes.ui.BoxButton;
    import classes.ui.BoxCheck;
    import classes.ui.BoxIcon;
    import classes.ui.Prompt;
    import classes.ui.Text;
    import com.bit101.components.ComboBox;
    import com.flashfla.utils.SystemUtil;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.net.URLRequest;
    import flash.net.navigateToURL;
    import game.noteskins.ExternalNoteskin;

    public class SettingsTabNoteskin extends SettingsTabBase
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _noteskins:Noteskins = Noteskins.instance;

        private var noteskin_struct:Object = NoteskinsStruct.getDefaultStruct();

        private var noteColorComboArray:Array = [];
        private var optionNoteskins:Array;
        private var optionNoteskinPreview:Sprite;
        private var optionNoteSkinCombo:ComboBox;
        private var optionNoteSkinComboIgnore:Boolean = false;
        private var optionNoteskinComboRefresh:BoxIcon;

        private var optionOpenCustomNoteskinEditor:BoxButton;
        private var optionOpenNoteskinFolder:BoxButton;
        private var optionImportCustomNoteskin:BoxButton;
        private var optionExportCustomNoteskin:BoxButton;

        private var optionNoteColors:Array;
        private var arrayColorSprites:Array;
        private var arrayColorSpritesReplace:Array;

        private var lastNoteskin:int;

        public function SettingsTabNoteskin(settingsWindow:SettingsWindow):void
        {
            super(settingsWindow);

            lastNoteskin = _gvars.activeUser.activeNoteskin;

            noteColorComboArray = [];
            for (var i:int = 0; i < DEFAULT_OPTIONS.noteColors.length; i++)
            {
                noteColorComboArray.push({"label": _lang.stringSimple("note_colors_" + DEFAULT_OPTIONS.noteColors[i]), "data": DEFAULT_OPTIONS.noteColors[i]});
            }
        }

        override public function get name():String
        {
            return "noteskin";
        }

        override public function openTab():void
        {
            container.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            container.graphics.moveTo(295, 15);
            container.graphics.lineTo(295, 405);

            var item:*;
            var i:int;
            var xOff:int = 15;
            var yOff:int = 15;

            optionNoteskinPreview = addNoteImage(xOff + 233, yOff + 32, 64, "blue");

            //- Noteskins
            optionNoteskins = [];
            var textNoteskinGroup:Text = new Text(container, xOff, yOff, _lang.string("options_noteskin"), 14);
            textNoteskinGroup.width = 265;
            yOff += 25;

            var gameNoteskinCheck:BoxCheck;

            var noteskinData:Object = _noteskins.data;
            var noteskin_ids:Array = [];

            for each (item in noteskinData)
                if (item["_hidden"] == null)
                    noteskin_ids.push(item.id);

            noteskin_ids.sort(Array.NUMERIC);

            for each (var noteskin_id:String in noteskin_ids)
            {
                item = noteskinData[noteskin_id];
                new Text(container, xOff + 23, yOff, item.name);

                gameNoteskinCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
                gameNoteskinCheck.skin = item.id;
                optionNoteskins.push(gameNoteskinCheck);

                yOff += 20;
            }

            yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);

            // Custom
            new Text(container, xOff + 23, yOff, _lang.string("options_noteskin_custom"));

            gameNoteskinCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            gameNoteskinCheck.skin = 0;
            optionNoteskins.push(gameNoteskinCheck);
            yOff += 30;

            optionNoteSkinCombo = new ComboBox(container, xOff, yOff, "-- Change Custom Noteskin --");
            optionNoteSkinCombo.setSize(240, 22);
            optionNoteSkinCombo.openPosition = ComboBox.BOTTOM;
            optionNoteSkinCombo.fontSize = 11;
            optionNoteSkinCombo.numVisibleItems = 10;
            optionNoteSkinCombo.addEventListener(Event.SELECT, gameNoteSkinSelect);
            setCustomNoteskinCombo();

            optionNoteskinComboRefresh = new BoxIcon(container, xOff + 240, yOff + 1, 20, 20, new iconRefresh(), clickHandler);
            optionNoteskinComboRefresh.padding = 7;

            yOff += 31;

            optionOpenCustomNoteskinEditor = new BoxButton(container, xOff, yOff, 125, 29, _lang.string("options_open_noteskin_editor"), 12, clickHandler);
            optionImportCustomNoteskin = new BoxButton(container, xOff + 135, yOff, 125, 29, _lang.string("options_import_noteskin_json"), 12, clickHandler);

            yOff += 39;

            optionOpenNoteskinFolder = new BoxButton(container, xOff, yOff, 125, 29, _lang.string("options_open_noteskin_folder"), 12, clickHandler);
            optionExportCustomNoteskin = new BoxButton(container, xOff + 135, yOff, 125, 29, _lang.string("options_copy_noteskin_data"), 12, clickHandler);

            /// Col 2
            xOff = 310;
            yOff = 15;

            var gameNoteColorTitle:Text = new Text(container, xOff + 5, yOff, _lang.string("options_note_colors_title"), 14);
            gameNoteColorTitle.width = 265;
            gameNoteColorTitle.align = Text.CENTER;
            yOff += 28;
            yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);

            optionNoteColors = [];
            arrayColorSprites = [];
            arrayColorSpritesReplace = [];
            for (i = 0; i < DEFAULT_OPTIONS.noteColors.length; i++)
            {
                arrayColorSprites.push(addNoteImage(xOff + 11, yOff + 11, 22, DEFAULT_OPTIONS.noteColors[i]));

                var gameNoteColor:Text = new Text(container, xOff + 25, yOff, _lang.string("note_colors_" + DEFAULT_OPTIONS.noteColors[i]));
                gameNoteColor.width = 95;

                var gameNoteColorCombo:ComboBox = new ComboBox(container, xOff + 125, yOff, _lang.stringSimple("note_colors_" + DEFAULT_OPTIONS.noteColors[i]), noteColorComboArray);
                gameNoteColorCombo.setSize(114, 22);
                gameNoteColorCombo.openPosition = ComboBox.BOTTOM;
                gameNoteColorCombo.fontSize = 11;
                gameNoteColorCombo.numVisibleItems = DEFAULT_OPTIONS.noteColors.length;
                gameNoteColorCombo.addEventListener(Event.SELECT, gameNoteColorSelect);
                optionNoteColors.push(gameNoteColorCombo);

                arrayColorSpritesReplace.push(addNoteImage(xOff + 255, yOff + 11, 22, _gvars.activeUser.noteColors[i]));

                yOff += 20;
                yOff += drawSeperator(container, xOff, 266, yOff, -3, -4);
            }
        }

        private function addNoteImage(xOff:Number, yOff:Number, receptorSize:Number, color:String):Sprite
        {
            var data:Object = _noteskins.getInfo(_gvars.activeUser.activeNoteskin);
            var hasRotation:Boolean = (data.rotation != 0);

            var noteHolder:Sprite = new Sprite();
            noteHolder.x = xOff;
            noteHolder.y = yOff;
            container.addChild(noteHolder);

            var noteSprite:Sprite = _noteskins.getNote(data.id, color, "U");
            noteSprite.x = -(data.width >> 1);
            noteSprite.y = -(data.height >> 1);
            noteHolder.addChild(noteSprite);

            // scale
            if (hasRotation)
                noteHolder.rotation = data.rotation * 2;

            var noteScale:Number = Math.min(1, (receptorSize / Math.max(noteHolder.width, noteHolder.height)));
            noteHolder.scaleX = noteHolder.scaleY = noteScale;
            noteHolder.visible = true;

            return noteHolder;
        }

        private function replaceNoteImage(oldSprite:Sprite, receptorSize:Number, color:String):Sprite
        {
            var xOff:Number = oldSprite.x;
            var yOff:Number = oldSprite.y;

            oldSprite.parent.removeChild(oldSprite);

            return addNoteImage(xOff, yOff, receptorSize, color);
        }

        private function updateNoteImages():void
        {
            for (var i:int = 0; i < DEFAULT_OPTIONS.noteColors.length; i++)
            {
                arrayColorSprites[i] = replaceNoteImage(arrayColorSprites[i], 22, DEFAULT_OPTIONS.noteColors[i]);
                arrayColorSpritesReplace[i] = replaceNoteImage(arrayColorSpritesReplace[i], 22, _gvars.activeUser.noteColors[i]);
            }

            optionNoteskinPreview = replaceNoteImage(optionNoteskinPreview, 64, "blue");
        }

        override public function setValues():void
        {
            // Set Noteskin
            for each (var item:BoxCheck in optionNoteskins)
            {
                item.checked = (item.skin == _gvars.activeUser.activeNoteskin);
            }

            for (var i:int = 0; i < DEFAULT_OPTIONS.noteColors.length; i++)
            {
                (optionNoteColors[i] as ComboBox).selectedItemByData = _gvars.activeUser.noteColors[i];
            }

            if (lastNoteskin != _gvars.activeUser.activeNoteskin)
            {
                lastNoteskin = _gvars.activeUser.activeNoteskin;
                updateNoteImages();
            }
        }

        override public function clickHandler(e:MouseEvent):void
        {
            //- Noteskin
            if (e.target.hasOwnProperty("skin"))
            {
                _gvars.activeUser.activeNoteskin = e.target.skin;
            }

            //- Custom Refresh
            if (e.target == optionNoteskinComboRefresh)
            {
                _noteskins.loadExternalNoteskins();
                setCustomNoteskinCombo();
            }

            //- Custom Noteskin Editor
            else if (e.target == optionOpenCustomNoteskinEditor)
            {
                navigateToURL(new URLRequest(Constant.NOTESKIN_EDITOR_URL), "_blank");
                return;
            }

            //- Custom Noteskin Folder
            else if (e.target == optionOpenNoteskinFolder)
            {
                AirContext.STORAGE_PATH.resolvePath(Constant.NOTESKIN_PATH).openWithDefaultApplication();
                return;
            }

            //- Import Custom Noteskin
            else if (e.target == optionImportCustomNoteskin)
            {
                new Prompt(parent, 320, _lang.string("popup_noteskin_import_json"), 100, _lang.string("popup_noteskin_import"), e_importNoteskin);
                return;
            }

            //- Export Custom Noteskin
            else if (e.target == optionExportCustomNoteskin)
            {
                var nsString:String = noteskinsString();
                if (nsString != null)
                {
                    var success:Boolean = SystemUtil.setClipboard(nsString);
                    if (success)
                        Alert.add(_lang.string("clipboard_success"), 120, Alert.GREEN);
                    else
                        Alert.add(_lang.string("clipboard_failure"), 120, Alert.RED);
                }
                return;
            }

            setValues();
        }

        private function gameNoteColorSelect(e:Event):void
        {
            var data:Object = e.target.selectedItem.data;
            for (var i:int = 0; i < optionNoteColors.length; i++)
            {
                if (optionNoteColors[i] == e.target)
                {
                    _gvars.activeUser.noteColors[i] = data;
                    arrayColorSpritesReplace[i] = replaceNoteImage(arrayColorSpritesReplace[i], 22, _gvars.activeUser.noteColors[i]);
                }
            }
        }

        private function setCustomNoteskinCombo():void
        {
            var extList:Vector.<ExternalNoteskin> = _noteskins.externalNoteskins;
            var noteskinList:Array = [];
            var ns:ExternalNoteskin;

            var noteskinData:String = LocalStore.getVariable(Noteskins.CUSTOM_NOTESKIN_DATA, null);
            var noteskinImport:String = LocalStore.getVariable(Noteskins.CUSTOM_NOTESKIN_IMPORT, null);
            var noteskinFilename:String = LocalStore.getVariable(Noteskins.CUSTOM_NOTESKIN_FILE, null);

            if (extList.length > 0)
            {
                for (var i:int = 0; i < extList.length; i++)
                {
                    ns = extList[i];

                    var nsName:String = ns.data.name.indexOf("Custom Export") != -1 ? ns.file.substr(0, ns.file.length - 4) : ns.data.name;

                    noteskinList.push({"label": nsName, "data": extList[i]});
                }
                noteskinList.sortOn("label", Array.CASEINSENSITIVE);
            }

            if (noteskinImport != null)
            {
                if (extList.length > 0)
                    noteskinList.unshift({"label": "------------------------------------", "data": null});

                noteskinList.unshift({"label": "Imported Noteskin", "data": optionNoteSkinCombo});
            }

            optionNoteSkinComboIgnore = true;
            optionNoteSkinCombo.items = noteskinList;

            // select combo box index
            if (noteskinFilename != null)
            {
                for (i = 0; i < noteskinList.length; i++)
                {
                    if (noteskinList[i].data != null && (noteskinList[i].data is ExternalNoteskin) && noteskinList[i].data.file == noteskinFilename)
                    {
                        optionNoteSkinCombo.selectedIndex = i;
                        break;
                    }
                }
            }
            else
            {
                optionNoteSkinCombo.selectedIndex = 0;
            }
            optionNoteSkinComboIgnore = false;
        }

        private function gameNoteSkinSelect(e:Event):void
        {
            if (optionNoteSkinComboIgnore)
                return;

            var data:Object = e.target.selectedItem.data;
            if (data == null)
                return;

            else if (data == optionNoteSkinCombo)
            {
                var json:String = LocalStore.getVariable(Noteskins.CUSTOM_NOTESKIN_IMPORT, null);
                LocalStore.setVariable(Noteskins.CUSTOM_NOTESKIN_DATA, json);
                LocalStore.setVariable(Noteskins.CUSTOM_NOTESKIN_FILE, null);
            }
            else
            {
                var extNS:ExternalNoteskin = data as ExternalNoteskin;
                LocalStore.setVariable(Noteskins.CUSTOM_NOTESKIN_DATA, extNS.json);
                LocalStore.setVariable(Noteskins.CUSTOM_NOTESKIN_FILE, extNS.file);
            }

            if (_gvars.activeUser.activeNoteskin != 0)
            {
                _gvars.activeUser.activeNoteskin = 0;
                setValues();
            }

            _noteskins.loadCustomNoteskin();
            parent.addEventListener(Event.ENTER_FRAME, e_delayCustomUpdate);
        }


        private function e_importNoteskin(noteskinJSON:String):void
        {
            try
            {
                var json:Object = JSON.parse(noteskinJSON);

                LocalStore.setVariable(Noteskins.CUSTOM_NOTESKIN_DATA, noteskinJSON);
                LocalStore.setVariable(Noteskins.CUSTOM_NOTESKIN_IMPORT, noteskinJSON);
                LocalStore.setVariable(Noteskins.CUSTOM_NOTESKIN_FILE, null);

                _noteskins.loadCustomNoteskin();
                setCustomNoteskinCombo();

                Alert.add(_lang.string("popup_noteskin_saved"), 90, Alert.GREEN);

                parent.addEventListener(Event.ENTER_FRAME, e_delayCustomUpdate);
            }
            catch (e:Error)
            {
            }
        }

        private function e_delayCustomUpdate(e:Event):void
        {
            // reload images, custom noteskins are async loaded so we just check for them to load
            if (_gvars.activeUser.activeNoteskin == 0)
            {
                if (_noteskins.data[0]["notes"]["blue"] != null)
                {
                    parent.removeEventListener(Event.ENTER_FRAME, e_delayCustomUpdate);
                    if (parent != null && parent.stage != null)
                    {
                        updateNoteImages();
                    }
                }
            }
        }

        private function noteskinsString():String
        {
            return LocalStore.getVariable("custom_noteskin", null);
        }
    }
}
