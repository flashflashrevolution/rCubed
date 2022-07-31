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
            "AMAZING",
            "PERFECT",
            "RECEPTOR_ANIMATIONS",
            "JUDGE_ANIMATIONS"];

        private var gameMPUIArray:Array = ["MP_UI", "MP_PA", "MP_JUDGE", "MP_COMBO"];

        private var gameOtherArray:Array = ["GENRE_FLAG",
            "SONG_FLAG",
            "SONG_NOTE"];

        private var optionDisplays:Array;

        private var optionJudgeSpeed:BoxSlider;
        private var textJudgeSpeed:Text;

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
            container.graphics.lineTo(295, 405);

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

                yOff = drawSpecial(xOff, yOff, container, gameUIArray[i]);
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

                yOff = drawSpecial(xOff, yOff, container, gameMPUIArray[i]);
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
            yOff += 30;
        }

        private function drawSpecial(xOff:int, yOff:int, container:ScrollPaneContent, key:String):int
        {
            if (key == "JUDGE_ANIMATIONS")
            {
                new Text(container, xOff + 23, yOff, _lang.string("options_judge_speed"));
                yOff += 22;

                optionJudgeSpeed = new BoxSlider(container, xOff + 23, yOff + 3, 100, 10, changeHandler);
                optionJudgeSpeed.minValue = 0.25;
                optionJudgeSpeed.maxValue = 3;

                textJudgeSpeed = new Text(container, xOff + 128, yOff - 2);
                yOff += 20;
            }

            return yOff;
        }

        override public function setValues():void
        {
            for each (var item:BoxCheck in optionDisplays)
            {
                item.checked = (_gvars.activeUser["DISPLAY_" + item.display]);
            }

            optionJudgeSpeed.slideValue = _gvars.activeUser.judgeSpeed;
            textJudgeSpeed.text = _gvars.activeUser.judgeSpeed.toFixed(2) + "x";
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

            parent.checkValidMods();
        }

        override public function changeHandler(e:Event):void
        {
            if (e.target == optionJudgeSpeed)
            {
                _gvars.activeUser.judgeSpeed = (Math.round((optionJudgeSpeed.slideValue * 100) / 5) * 5) / 100; // Snap to 0.05 intervals.
                textJudgeSpeed.text = _gvars.activeUser.judgeSpeed.toFixed(2) + "x";
            }

            parent.checkValidMods();
        }
    }
}
