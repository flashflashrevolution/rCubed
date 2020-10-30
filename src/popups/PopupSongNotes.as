package popups
{
    import assets.GameBackgroundColor;
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxCheck;
    import classes.HeartSelector;
    import classes.Language;
    import classes.Playlist;
    import classes.StarSelector;
    import classes.Text;
    import classes.ValidatedText;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import menu.MainMenu;
    import menu.MenuPanel;
    import menu.MenuSongSelection;
    import sql.SQLSongDetails;

    public class PopupSongNotes extends MenuPanel
    {
        private var _lang:Language = Language.instance;
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _playlist:Playlist = Playlist.instance;
        private var _loader:URLLoader;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var sObject:Object;
        private var sDetails:SQLSongDetails;

        private var sRating:StarSelector;
        private var sFavorite:HeartSelector;

        private var notesLength:Text;
        private var notesField:TextField;
        private var setMirrorInvert:BoxCheck;
        private var setCustomOffsets:BoxCheck;

        private var optionMusicOffset:ValidatedText;
        private var optionJudgeOffset:ValidatedText;

        private var revertOptions:BoxButton;
        private var confirmOptions:BoxButton;
        private var closeOptions:BoxButton;

        public var songRatingValue:Number;

        public function PopupSongNotes(myParent:MenuPanel, song:Object)
        {
            super(myParent);
            sObject = song;

            var engine_id:String = song.engine != null ? song.engine.id : Constant.BRAND_NAME_SHORT_LOWER;
            sDetails = SQLQueries.getSongDetailsSafe(engine_id, song.level);

            songRatingValue = _gvars.playerUser.getSongRating(sObject);
        }

        override public function stageAdd():void
        {
            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);
            this.addChild(bmp);

            var bgbox:Box = new Box(this, (Main.GAME_WIDTH - 390) / 2, -1, false, false);
            bgbox.setSize(390, Main.GAME_HEIGHT + 2);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;

            box = new Box(this, bgbox.x, -1, false, false);
            box.setSize(bgbox.width, bgbox.height);
            box.activeAlpha = 0.4;

            var titleDisplay:Text = new Text(box, 5, 20, "- " + sObject["name"] + " -", 20);
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;

            // Divider
            box.graphics.lineStyle(1, 0xffffff);
            box.graphics.moveTo(10, 65);
            box.graphics.lineTo(box.width - 10, 65);

            var lblSongRating:Text = new Text(box, 20, 69, _lang.string("song_rating_label"), 14);
            lblSongRating.width = 145;
            lblSongRating.align = Text.LEFT;

            sRating = new StarSelector(box, 22, 95);

            var lblSongFavorite:Text = new Text(box, box.width - 165, 68, _lang.string("song_favorite_label"), 14);
            lblSongFavorite.width = 145;
            lblSongFavorite.align = Text.RIGHT;

            sFavorite = new HeartSelector(box, box.width - 52, 93);

            // Divider
            box.graphics.lineStyle(1, 0xffffff);
            box.graphics.moveTo(10, 130);
            box.graphics.lineTo(box.width - 10, 130);

            var xOff:int = 20;
            var yOff:int = 140;

            //- Notes Field
            var notesLabel:Text = new Text(box, xOff, yOff, _lang.string("song_notes"));

            notesLength = new Text(box, box.width - xOff, yOff, "0 / 250");
            notesLength.align = "right";
            yOff += 20;

            box.graphics.lineStyle(1, 0xffffff, 0.5);
            box.graphics.beginFill(0xffffff, 0.1);
            box.graphics.drawRect(xOff, yOff, box.width - 40, 80);
            box.graphics.endFill();

            notesField = new TextField();
            notesField.wordWrap = true;
            notesField.multiline = true;
            notesField.maxChars = 250;
            notesField.type = "input";
            notesField.antiAliasType = AntiAliasType.ADVANCED;
            notesField.embedFonts = true;
            notesField.defaultTextFormat = Constant.TEXT_FORMAT_UNICODE;
            notesField.width = 340;
            notesField.height = 70;
            notesField.x = xOff + 5;
            notesField.y = yOff + 5;
            notesField.addEventListener(Event.CHANGE, e_notesFieldChange);
            box.addChild(notesField);
            yOff += 90;

            // Settings
            var setMirrorInvertText:Text = new Text(box, xOff + 22, yOff, _lang.string("song_notes_setting_mirror_invert"));
            setMirrorInvert = new BoxCheck(box, xOff + 2, yOff + 2, clickHandler);
            yOff += 30;

            var setCustomOffsetsText:Text = new Text(box, xOff + 22, yOff, _lang.string("song_notes_setting_custom_offsets"));
            setCustomOffsets = new BoxCheck(box, xOff + 2, yOff + 2, clickHandler);
            yOff += 30;

            //- Global Offset
            var gameOffset:Text = new Text(box, xOff, yOff, _lang.string("options_global_offset"));
            yOff += 20;

            optionMusicOffset = new ValidatedText(box, xOff, yOff, 100, 20, ValidatedText.R_FLOAT, changeHandler);
            optionMusicOffset.text = "0";
            yOff += 30;

            //- Judge Offset
            var gameJudgeOffset:Text = new Text(box, xOff, yOff, _lang.string("options_judge_offset"));
            yOff += 20;

            optionJudgeOffset = new ValidatedText(box, xOff, yOff, 100, 20, ValidatedText.R_FLOAT, changeHandler);
            optionJudgeOffset.text = "0";

            //- Revert
            revertOptions = new BoxButton(box, 20, box.height - 42, 80, 27, _lang.string("menu_revert"), 12, clickHandler);
            revertOptions.color = 0xff0000;

            //- Close
            closeOptions = new BoxButton(box, box.width - 100, box.height - 42, 80, 27, _lang.string("menu_close"), 12, clickHandler);

            //- Confirm
            confirmOptions = new BoxButton(box, closeOptions.x - 95, box.height - 42, 80, 27, _lang.string("menu_confirm"), 12, clickHandler);

            refreshFields();
        }

        private function refreshFields():void
        {
            if (bmd != null && sDetails != null)
            {
                sRating.value = songRatingValue;
                sFavorite.checked = sDetails.song_favorite;
                notesField.text = sDetails.notes;
                notesLength.text = "(" + notesField.length + " / 250)";
                setMirrorInvert.checked = sDetails.set_mirror_invert;
                setCustomOffsets.checked = sDetails.set_custom_offsets;
                optionMusicOffset.text = sDetails.offset_music.toString();
                optionJudgeOffset.text = sDetails.offset_judge.toString();
            }
        }

        private function e_notesFieldChange(e:Event):void
        {
            notesLength.text = "(" + notesField.length + " / 250)";
        }

        override public function stageRemove():void
        {
            notesField.removeEventListener(Event.CHANGE, e_notesFieldChange);
            setMirrorInvert.dispose();
            setCustomOffsets.dispose();
            optionJudgeOffset.dispose();
            optionMusicOffset.dispose();

            notesLength.dispose();
            optionJudgeOffset.dispose();
            optionMusicOffset.dispose();
            revertOptions.dispose();
            closeOptions.dispose();
            confirmOptions.dispose();

            box.dispose();
            bmp = null;
            box = null;
        }

        private function changeHandler(e:Event):void
        {
            if (e.target is ValidatedText)
                (e.target as ValidatedText).validate(0);
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == setMirrorInvert)
                setMirrorInvert.checked = !setMirrorInvert.checked;

            else if (e.target == setCustomOffsets)
                setCustomOffsets.checked = !setCustomOffsets.checked;

            //- Confirm Rating
            else if (e.target == confirmOptions)
            {
                saveRatings();
                saveDetails();
                removePopup();

                // Update the Note Hover Directly
                if (_gvars.gameMain.activePanel != null && _gvars.gameMain.activePanel is MainMenu)
                {
                    var mmmenu:MainMenu = (_gvars.gameMain.activePanel as MainMenu);
                    if (mmmenu.panel != null && (mmmenu.panel is MenuSongSelection))
                    {
                        var msmenu:MenuSongSelection = (mmmenu.panel as MenuSongSelection);
                        msmenu.updateSongItemNote(sObject.level);
                    }
                }

                return;
            }
            //- Close
            else if (e.target == closeOptions)
            {
                removePopup();
                return;
            }
        }

        private function saveDetails():void
        {
            sDetails.song_favorite = sFavorite.checked;
            sDetails.offset_music = optionMusicOffset.validate(0);
            sDetails.offset_judge = optionJudgeOffset.validate(0);
            sDetails.set_mirror_invert = setMirrorInvert.checked;
            sDetails.set_custom_offsets = setCustomOffsets.checked;
            sDetails.notes = notesField.text;

            // Song Rating
            if (sDetails.engine != Constant.BRAND_NAME_SHORT_LOWER)
                sDetails.song_rating = sRating.value;
            else
                _gvars.playerUser.songRatings[sObject["level"]] = sRating.value;

            _gvars.writeUserSongData();
        }

        private function saveRatings():void
        {
            if (sRating.value == songRatingValue || sDetails.engine != Constant.BRAND_NAME_SHORT_LOWER)
                return;

            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(Constant.SONG_RATING_URL + "?d=" + new Date().getTime());
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = _gvars.userSession;
            requestVars.id = sObject["level"];
            requestVars.song_rating = sRating.value;
            requestVars.chart_rating = 2.5;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, ratingLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, ratingLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, ratingLoadError);
        }

        private function ratingLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            try
            {
                var _data:Object = JSON.parse(e.target.data);
                if (_data["result"] && _data["result"] == "success")
                {
                    _gvars.playerUser.songRatings[sObject["level"]] = sRating.value;
                    //_gvars.gameMain.addAlert("Saved rating for " + sObject["name"] + "!", 120, Alert.GREEN);
                    if (_data["type"] && _data["type"] == 1)
                    {
                        _playlist.playList[sObject["level"]]["song_rating"] = _data["new_value"];
                    }
                }
                else
                {
                    //_gvars.gameMain.addAlert("Failed to save song rating.", 120, Alert.RED);
                }
            }
            catch (e:Error)
            {
            }
        }

        private function removeLoaderListeners():void
        {
            _loader.removeEventListener(Event.COMPLETE, ratingLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, ratingLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, ratingLoadError);
        }

        private function ratingLoadError(e:Event):void
        {
            removeLoaderListeners();
        }
    }
}
