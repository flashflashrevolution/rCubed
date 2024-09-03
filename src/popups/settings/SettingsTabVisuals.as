package popups.settings
{
    import classes.Language;
    import classes.ui.BoxCheck;
    import classes.ui.BoxSlider;
    import classes.ui.ScrollPaneContent;
    import classes.ui.Text;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class SettingsTabVisuals extends SettingsTabBase
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        private var gameUIArray:Array = ["GAME_TOP_BAR",
            "GAME_BOTTOM_BAR",
            "JUDGE",
            "HEALTH",
            "SONGPROGRESS",
            "SONGPROGRESS_TEXT",
            "SCORE",
            "COMBO",
            "TOTAL",
            "PACOUNT",
            "ACCURACY_BAR",
            "SCREENCUT",
            "RAWGOODS",
            "----",
            "AMAZING",
            "PERFECT",
            "RECEPTOR_ANIMATIONS",
            "JUDGE_ANIMATIONS"];

        private var gameMPUIArray:Array = ["MULTIPLAYER_SCORES"];

        private var gameOtherArray:Array = ["GENRE_FLAG",
            "SONG_FLAG",
            "SONG_NOTE"];

        private var optionDisplays:Array;

        private var optionAccuracyBarFadeFactor:BoxSlider;
        private var textAccuracyBarFadeFactor:Text;

        private var optionReceptorSpeed:BoxSlider;
        private var textReceptorSpeed:Text;

        private var optionJudgeSpeed:BoxSlider;
        private var textJudgeSpeed:Text;

        private var optionJudgeScale:BoxSlider;
        private var textJudgeScale:Text;

        private var legacySongsCheck:BoxCheck;
        private var explicitSongsCheck:BoxCheck;
        private var unrankedSongsCheck:BoxCheck;

        public function SettingsTabVisuals(settingsWindow:SettingsWindow):void
        {
            super(settingsWindow);
        }

        override public function get name():String
        {
            return "visual_graphics";
        }

        override public function openTab():void
        {
            container.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            container.graphics.moveTo(295, 15);
            container.graphics.lineTo(295, 555);

            var i:int;
            var xOff:int = 15;
            var yOff:int = 15;

            /// Col 1
            //- Display
            optionDisplays = [];

            new Text(container, xOff, yOff, _lang.string("options_gameplay_display"), 14);
            yOff += 25;

            for (i = 0; i < gameUIArray.length; i++)
            {
                if (gameUIArray[i] == "----")
                {
                    yOff += drawSeperator(container, xOff, 250, yOff, 0, 1);
                    continue;
                }

                new Text(container, xOff + 23, yOff, _lang.string("options_" + gameUIArray[i].toLowerCase()));

                var gameDisplayCheck:BoxCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
                gameDisplayCheck.display = gameUIArray[i];
                optionDisplays.push(gameDisplayCheck);
                yOff += 19;

                if (gameUIArray[i] == "ACCURACY_BAR")
                {
                    yOff = drawAccuracyBarFadeFactor(xOff, yOff, container);
                }

                if (gameUIArray[i] == "RECEPTOR_ANIMATIONS")
                {
                    yOff = drawReceptorSpeed(xOff, yOff, container);
                }

                if (gameUIArray[i] == "JUDGE_ANIMATIONS")
                {
                    yOff = drawJudgeSpeed(xOff, yOff, container);
                    yOff = drawJudgeScale(xOff, yOff, container);
                }
            }

            /// Col 2
            xOff = 310;
            yOff = 15;

            new Text(container, xOff, yOff, _lang.string("options_gameplay_mp_display"), 14);
            yOff += 25;

            for (i = 0; i < gameMPUIArray.length; i++)
            {
                if (gameMPUIArray[i] == "----")
                {
                    yOff += drawSeperator(container, xOff, 250, yOff, 0, 1);
                    continue;
                }

                new Text(container, xOff + 23, yOff, _lang.string("options_" + gameMPUIArray[i].toLowerCase()));

                var gameMPDisplayCheck:BoxCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
                gameMPDisplayCheck.display = gameMPUIArray[i];
                optionDisplays.push(gameMPDisplayCheck);
                yOff += 19;
            }

            yOff += drawSeperator(container, xOff, 250, yOff, 6, 5);

            new Text(container, xOff, yOff, _lang.string("options_playlist_display"), 14);
            yOff += 25;

            for (i = 0; i < gameOtherArray.length; i++)
            {
                if (gameOtherArray[i] == "----")
                {
                    yOff += drawSeperator(container, xOff, 250, yOff, 0, 1);
                    continue;
                }

                new Text(container, xOff + 23, yOff, _lang.string("options_" + gameOtherArray[i].toLowerCase()));

                var optionModCheck:BoxCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
                optionModCheck.display = gameOtherArray[i];
                optionDisplays.push(optionModCheck);
                yOff += 19;
            }
            yOff += 11;

            // Legacy Song Display
            new Text(container, xOff + 23, yOff, _lang.string("options_include_legacy_songs"));
            legacySongsCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            legacySongsCheck.addEventListener(MouseEvent.MOUSE_OVER, e_legacyEngineMouseOver, false, 0, true);
            yOff += 19;

            // Explicit Song Display
            new Text(container, xOff + 23, yOff, _lang.string("options_include_explicit_songs"));
            explicitSongsCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            yOff += 19;

            // Unranked Song Display
            new Text(container, xOff + 23, yOff, _lang.string("options_include_unranked_songs"));
            unrankedSongsCheck = new BoxCheck(container, xOff + 3, yOff + 3, clickHandler);
            yOff += 19;
        }


        private function drawAccuracyBarFadeFactor(xOff:int, yOff:int, container:ScrollPaneContent):int
        {
            new Text(container, xOff + 23, yOff, _lang.string("options_accuracy_bar_fade_factor"));
            yOff += 22;

            optionAccuracyBarFadeFactor = new BoxSlider(container, xOff + 23, yOff + 3, 100, 10, changeHandler);
            optionAccuracyBarFadeFactor.minValue = 0.5;
            optionAccuracyBarFadeFactor.maxValue = 0.99;

            textAccuracyBarFadeFactor = new Text(container, xOff + 128, yOff - 2);
            yOff += 20;
            return yOff + 4;
        }

        private function drawReceptorSpeed(xOff:int, yOff:int, container:ScrollPaneContent):int
        {
            new Text(container, xOff + 23, yOff, _lang.string("options_receptor_speed"));
            yOff += 22;

            optionReceptorSpeed = new BoxSlider(container, xOff + 23, yOff + 3, 100, 10, changeHandler);
            optionReceptorSpeed.minValue = 0.25;
            optionReceptorSpeed.maxValue = 5;

            textReceptorSpeed = new Text(container, xOff + 128, yOff - 2);
            yOff += 20;
            return yOff + 4;
        }

        private function drawJudgeSpeed(xOff:int, yOff:int, container:ScrollPaneContent):int
        {
            new Text(container, xOff + 23, yOff, _lang.string("options_judge_speed"));
            yOff += 22;

            optionJudgeSpeed = new BoxSlider(container, xOff + 23, yOff + 3, 100, 10, changeHandler);
            optionJudgeSpeed.minValue = 0.25;
            optionJudgeSpeed.maxValue = 5;

            textJudgeSpeed = new Text(container, xOff + 128, yOff - 2);
            yOff += 20;

            return yOff + 4;
        }

        private function drawJudgeScale(xOff:int, yOff:int, container:ScrollPaneContent):int
        {
            new Text(container, xOff + 23, yOff, _lang.string("options_judge_scale"));
            yOff += 22;

            optionJudgeScale = new BoxSlider(container, xOff + 23, yOff + 3, 100, 10, changeHandler);
            optionJudgeScale.minValue = 0.25;
            optionJudgeScale.maxValue = 3;

            textJudgeScale = new Text(container, xOff + 128, yOff - 2);
            yOff += 20;

            return yOff + 4;
        }

        override public function setValues():void
        {
            for each (var item:BoxCheck in optionDisplays)
            {
                item.checked = (_gvars.activeUser["DISPLAY_" + item.display]);
            }

            optionAccuracyBarFadeFactor.slideValue = _gvars.activeUser.accuracyBarFadeFactor;
            textAccuracyBarFadeFactor.text = (_gvars.activeUser.accuracyBarFadeFactor * 100).toFixed(0) + "%";

            optionReceptorSpeed.slideValue = _gvars.activeUser.receptorSpeed;
            textReceptorSpeed.text = _gvars.activeUser.receptorSpeed.toFixed(2) + "x";

            optionJudgeSpeed.slideValue = _gvars.activeUser.judgeSpeed;
            textJudgeSpeed.text = _gvars.activeUser.judgeSpeed.toFixed(2) + "x";

            optionJudgeScale.slideValue = _gvars.activeUser.judgeScale;
            textJudgeScale.text = _gvars.activeUser.judgeScale.toFixed(2) + "x";

            legacySongsCheck.checked = _gvars.activeUser.DISPLAY_LEGACY_SONGS;
            explicitSongsCheck.checked = _gvars.activeUser.DISPLAY_EXPLICIT_SONGS;
            unrankedSongsCheck.checked = _gvars.activeUser.DISPLAY_UNRANKED_SONGS;
        }

        override public function clickHandler(e:MouseEvent):void
        {
            if (e.target.hasOwnProperty("display"))
            {
                _gvars.activeUser["DISPLAY_" + e.target.display] = !_gvars.activeUser["DISPLAY_" + e.target.display];
                e.target.checked = !e.target.checked;
                if (e.target.display == "GENRE_FLAG" || e.target.display == "SONG_FLAG" || e.target.display == "SONG_NOTE")
                {
                    _gvars.gameMain.activePanel.draw();
                }
            }

            // Songs Flags
            else if (e.target == legacySongsCheck)
            {
                e.target.checked = !e.target.checked;
                _gvars.activeUser.DISPLAY_LEGACY_SONGS = !_gvars.activeUser.DISPLAY_LEGACY_SONGS;
            }

            else if (e.target == explicitSongsCheck)
            {
                e.target.checked = !e.target.checked;
                _gvars.activeUser.DISPLAY_EXPLICIT_SONGS = !_gvars.activeUser.DISPLAY_EXPLICIT_SONGS;
            }

            else if (e.target == unrankedSongsCheck)
            {
                e.target.checked = !e.target.checked;
                _gvars.activeUser.DISPLAY_UNRANKED_SONGS = !_gvars.activeUser.DISPLAY_UNRANKED_SONGS;
            }

            parent.checkValidMods();
        }

        override public function changeHandler(e:Event):void
        {
            if (e.target == optionAccuracyBarFadeFactor)
            {
                _gvars.activeUser.accuracyBarFadeFactor = Math.round(optionAccuracyBarFadeFactor.slideValue * 100) / 100;
                textAccuracyBarFadeFactor.text = (_gvars.activeUser.accuracyBarFadeFactor * 100).toFixed(0) + "%";
            }

            if (e.target == optionJudgeSpeed)
            {
                _gvars.activeUser.judgeSpeed = (Math.round((optionJudgeSpeed.slideValue * 100) / 5) * 5) / 100; // Snap to 0.05 intervals.
                textJudgeSpeed.text = _gvars.activeUser.judgeSpeed.toFixed(2) + "x";
            }

            if (e.target == optionJudgeScale)
            {
                _gvars.activeUser.judgeScale = (Math.round((optionJudgeScale.slideValue * 100) / 5) * 5) / 100; // Snap to 0.05 intervals.
                textJudgeScale.text = _gvars.activeUser.judgeScale.toFixed(2) + "x";
            }

            if (e.target == optionReceptorSpeed)
            {
                _gvars.activeUser.receptorSpeed = (Math.round((optionReceptorSpeed.slideValue * 100) / 5) * 5) / 100; // Snap to 0.05 intervals.
                textReceptorSpeed.text = _gvars.activeUser.receptorSpeed.toFixed(2) + "x";
            }

            parent.checkValidMods();
        }

        private function e_legacyEngineMouseOver(e:Event):void
        {
            legacySongsCheck.addEventListener(MouseEvent.MOUSE_OUT, e_legacyEngineMouseOut);
            displayToolTip(legacySongsCheck.x, legacySongsCheck.y + 22, _lang.string("popup_legacy_songs"), "left");
        }

        private function e_legacyEngineMouseOut(e:Event):void
        {
            legacySongsCheck.removeEventListener(MouseEvent.MOUSE_OUT, e_legacyEngineMouseOut);
            hideTooltip();
        }

    }
}
