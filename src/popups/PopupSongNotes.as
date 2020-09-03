package popups
{
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxCheck;
    import classes.BoxText;
    import classes.Language;
    import classes.Playlist;
    import classes.StarSelector;
    import classes.Text;
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
    import classes.HeartSelector;

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

        private var optionMusicOffset:BoxText;
        private var optionJudgeOffset:BoxText;

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

            var bgbox:Box = new Box(390, Main.GAME_HEIGHT + 2, false, false);
            bgbox.x = (Main.GAME_WIDTH - 390) / 2;
            bgbox.y = -1;
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;
            this.addChild(bgbox);

            box = new Box(bgbox.width, bgbox.height, false, false);
            box.x = bgbox.x;
            box.y = -1;
            box.activeAlpha = 0.4;
            this.addChild(box);

            var titleDisplay:Text = new Text("- " + sObject["name"] + " -", 20);
            titleDisplay.x = 5;
            titleDisplay.y = 20;
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;
            box.addChild(titleDisplay);

            // Divider
            box.graphics.lineStyle(1, 0xffffff);
            box.graphics.moveTo(10, 65);
            box.graphics.lineTo(box.width - 10, 65);

            var lblSongRating:Text = new Text(_lang.string("song_rating_label"), 14);
            lblSongRating.x = 20;
            lblSongRating.y = 69;
            lblSongRating.width = 145;
            lblSongRating.align = Text.LEFT;
            box.addChild(lblSongRating);

            sRating = new StarSelector();
            sRating.x = 22;
            sRating.y = 95;
            box.addChild(sRating);

            var lblSongFavorite:Text = new Text(_lang.string("song_favorite_label"), 14);
            lblSongFavorite.x = box.width - 165;
            lblSongFavorite.y = 68;
            lblSongFavorite.width = 145;
            lblSongFavorite.align = Text.RIGHT;
            box.addChild(lblSongFavorite);

            sFavorite = new HeartSelector();
            sFavorite.x = box.width - 52;
            sFavorite.y = 93
            box.addChild(sFavorite);

            // Divider
            box.graphics.lineStyle(1, 0xffffff);
            box.graphics.moveTo(10, 130);
            box.graphics.lineTo(box.width - 10, 130);

            var xOff:int = 20;
            var yOff:int = 140;

            //- Notes Field
            var notesLabel:Text = new Text(_lang.string("song_notes"));
            notesLabel.x = xOff;
            notesLabel.y = yOff;
            box.addChild(notesLabel);

            notesLength = new Text("0 / 250");
            notesLength.x = box.width - xOff;
            notesLength.y = yOff;
            notesLength.align = "right";
            box.addChild(notesLength);
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
            var setMirrorInvertText:Text = new Text(_lang.string("song_notes_setting_mirror_invert"));
            setMirrorInvertText.x = xOff + 22;
            setMirrorInvertText.y = yOff;
            box.addChild(setMirrorInvertText);

            setMirrorInvert = new BoxCheck();
            setMirrorInvert.x = xOff + 2;
            setMirrorInvert.y = yOff + 2;
            setMirrorInvert.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(setMirrorInvert);
            yOff += 30;

            var setCustomOffsetsText:Text = new Text(_lang.string("song_notes_setting_custom_offsets"));
            setCustomOffsetsText.x = xOff + 22;
            setCustomOffsetsText.y = yOff;
            box.addChild(setCustomOffsetsText);

            setCustomOffsets = new BoxCheck();
            setCustomOffsets.x = xOff + 2;
            setCustomOffsets.y = yOff + 2;
            setCustomOffsets.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(setCustomOffsets);
            yOff += 30;

            //- Global Offset
            var gameOffset:Text = new Text(_lang.string("options_global_offset"));
            gameOffset.x = xOff;
            gameOffset.y = yOff;
            box.addChild(gameOffset);
            yOff += 20;

            optionMusicOffset = new BoxText(100, 20);
            optionMusicOffset.x = xOff;
            optionMusicOffset.y = yOff;
            optionMusicOffset.restrict = "-0-9";
            optionMusicOffset.text = "0";
            box.addChild(optionMusicOffset);
            yOff += 30;

            //- Judge Offset
            var gameJudgeOffset:Text = new Text(_lang.string("options_judge_offset"));
            gameJudgeOffset.x = xOff;
            gameJudgeOffset.y = yOff;
            box.addChild(gameJudgeOffset);
            yOff += 20;

            optionJudgeOffset = new BoxText(100, 20);
            optionJudgeOffset.x = xOff;
            optionJudgeOffset.y = yOff;
            optionJudgeOffset.restrict = "-0-9";
            optionJudgeOffset.text = "0";
            box.addChild(optionJudgeOffset);


            //- Revert
            revertOptions = new BoxButton(80, 27, _lang.string("menu_revert"));
            revertOptions.x = 20;
            revertOptions.y = box.height - 42;
            revertOptions.color = 0xff0000;
            revertOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(revertOptions);

            //- Close
            closeOptions = new BoxButton(80, 27, _lang.string("menu_close"));
            closeOptions.x = box.width - 100;
            closeOptions.y = box.height - 42;
            closeOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(closeOptions);

            //- Confirm
            confirmOptions = new BoxButton(80, 27, _lang.string("menu_confirm"));
            confirmOptions.x = closeOptions.x - 95
            confirmOptions.y = box.height - 42;
            confirmOptions.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(confirmOptions);

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
            box.dispose();
            bmp = null;
            box = null;
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == setMirrorInvert)
                setMirrorInvert.checked = !setMirrorInvert.checked

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
            sDetails.offset_music = verifyFloat(optionMusicOffset.text, 0);
            sDetails.offset_judge = verifyFloat(optionJudgeOffset.text, 0);
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

        private function verifyFloat(text:String, default_val:Number):Number
        {
            var temp:Number = parseFloat(text);
            if (isNaN(temp))
                return default_val;

            return temp;
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
