package game
{
    import assets.menu.icons.fa.iconPhoto;
    import assets.menu.icons.fa.iconVideo;
    import classes.Language;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCFFRGameStateChange;
    import classes.mp.mode.ffr.MPMatchResultsFFR;
    import classes.mp.room.MPRoomFFR;
    import classes.score.ScoreHandler;
    import classes.score.ScoreHandlerEvent;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;
    import flash.utils.getTimer;
    import game.results.GameResultBackground;
    import game.results.GameResultFFRView;
    import game.results.GameResultSingleView;
    import menu.MenuPanel;
    import popups.PopupHighscores;

    public class GameResultsMP extends MenuPanel
    {
        private static const _gvars:GlobalVariables = GlobalVariables.instance;
        private static const _lang:Language = Language.instance;
        private static const _score:ScoreHandler = ScoreHandler.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;

        // Multiplayer
        private var room:MPRoomFFR;

        // Results
        private var userResult:GameScoreResult;
        private var resultIndex:int = 0;
        private var result:GameScoreResult;

        private var matchResults:MPMatchResultsFFR;

        private var background:GameResultBackground;
        private var singleResult:GameResultSingleView;
        private var overviewResult:GameResultFFRView;

        // Title Bar
        private var navSaveReplay:BoxIcon;
        private var navScreenShot:BoxIcon;

        // Game Result
        private var navBack:BoxButton;

        // Menu Bar
        private var navOptions:BoxButton;
        private var navHighscores:BoxButton;
        private var navMenu:BoxButton;

        public function GameResultsMP(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            // Get MP Results
            room = _mp.GAME_ROOM as MPRoomFFR;
            if (room.lastMatchIndex == -1)
                matchResults = room.lastMatch;
            else
                matchResults = room.lastMatchHistory[room.lastMatchIndex];

            // Get Local Results
            if (_gvars.songResults.length > 0 && room.lastMatchIndex == -1)
            {
                userResult = _gvars.songResults[0];

                // Update Judge Offset
                updateJudgeOffset(userResult);

                // Send User Score
                _score.addEventListener(ScoreHandlerEvent.SUCCESS, e_onScoreResult);
                _score.addEventListener(ScoreHandlerEvent.FAILURE, e_onScoreResult);
                _score.sendScore(userResult);
                _score.saveLocalReplay(userResult);

                // Clear Scores
                _gvars.songResults.length = 0;

                // Replace MP Result with Personal Result
                for (var i:int = 0; i < matchResults.users.length; i++)
                {
                    var result:GameScoreResult = matchResults.users[i].score;

                    if (userResult.compare(result))
                    {
                        matchResults.users[i].score = userResult;
                        break;
                    }
                }
            }

            return true;
        }

        //******************************************************************************************//
        // Panel Stage Functions
        //******************************************************************************************//

        override public function stageAdd():void
        {
            // Background
            background = new GameResultBackground();
            addChild(background);

            // Background Noise
            var noiseSource:BitmapData = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x00000000);
            noiseSource.perlinNoise(Main.GAME_WIDTH, Main.GAME_HEIGHT, 12, getTimer(), true, false, 7, true);
            var noiseImage:Bitmap = new Bitmap(noiseSource);
            noiseImage.alpha = 0.15;
            background.addChild(noiseImage);

            overviewResult = new GameResultFFRView(room, matchResults, e_onScoreClick);
            addChild(overviewResult);

            singleResult = new GameResultSingleView();
            addChild(singleResult);

            // Main Navigation Buttons
            var buttonMenu:Sprite = new Sprite();
            var buttonMenuItems:Array = [];
            buttonMenu.x = 22;
            buttonMenu.y = 428;
            this.addChild(buttonMenu);

            navOptions = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_options"), 17, eventHandler);
            buttonMenuItems.push(navOptions);

            navHighscores = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_highscores"), 17, eventHandler);
            buttonMenuItems.push(navHighscores);

            navMenu = new BoxButton(buttonMenu, 0, 0, 170, 40, _lang.string("game_results_menu_exit_menu"), 17, eventHandler);
            buttonMenuItems.push(navMenu);

            var BUTTON_GAP:int = 11;
            var BUTTON_WIDTH:int = (735 - (Math.max(0, (buttonMenuItems.length - 1)) * BUTTON_GAP)) / buttonMenuItems.length;
            for (var bx:int = 0; bx < buttonMenuItems.length; bx++)
            {
                buttonMenuItems[bx].width = BUTTON_WIDTH;
                buttonMenuItems[bx].x = BUTTON_WIDTH * bx + BUTTON_GAP * bx;
            }

            // Song Results Buttons
            navScreenShot = new BoxIcon(this, 522, 6, 32, 32, new iconPhoto(), eventHandler);
            navScreenShot.setIconColor("#E2FEFF");
            navScreenShot.setHoverText(_lang.string("game_results_queue_save_screenshot_clipboard_hint"), "bottom");

            navSaveReplay = new BoxIcon(this, 485, 6, 32, 32, new iconVideo(), eventHandler);
            navSaveReplay.setIconColor("#E2FEFF");
            navSaveReplay.setHoverText(_lang.string("game_results_queue_save_replay"), "bottom");

            // Song Results
            navBack = new BoxButton(this, 18, 62, 90, 32, _lang.string("game_results_mp_back"), 12, eventHandler);

            // Display Game Result
            displayGameResult(-1);

            _gvars.gameMain.displayPopupQueue();

            // Add keyboard navigation
            stage.addEventListener(KeyboardEvent.KEY_DOWN, eventHandler);

            // Add Mouse Move for graphs
            stage.addEventListener(MouseEvent.MOUSE_MOVE, e_mouseMove);

            // Return to Multiplayer Menu
            Flags.VALUES[Flags.MP_MENU_RETURN] = true;
        }

        override public function stageRemove():void
        {
            _mp.sendCommand(new MPCFFRGameStateChange(room, "menu"));

            // Remove Score Events
            _score.removeEventListener(ScoreHandlerEvent.SUCCESS, e_onScoreResult);
            _score.removeEventListener(ScoreHandlerEvent.FAILURE, e_onScoreResult);

            // Remove keyboard navigation
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, eventHandler);

            // Remove Mouse Move for graphs
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, e_mouseMove);

            super.stageRemove();
        }

        private function e_mouseMove(e:MouseEvent):void
        {
            if (singleResult && singleResult.visible)
                singleResult.e_graphHover(e);
        }

        private function e_onScoreClick(index:Number):void
        {
            displayGameResult(index);
        }

        private function e_onScoreResult(e:ScoreHandlerEvent):void
        {
            if (singleResult && singleResult.visible)
                singleResult.onScoreResult(e);

            // Display Popup Queue
            _gvars.gameMain.displayPopupQueue();
        }

        //******************************************************************************************//
        // Results Display Logic
        //******************************************************************************************//

        public function displayGameResult(gameIndex:int):void
        {
            // Set Index
            resultIndex = gameIndex;

            // Score Overview
            if (gameIndex == -1)
            {
                navSaveReplay.enabled = false;
                overviewResult.visible = true;
                singleResult.visible = false;
                navBack.visible = false;
            }

            // Single Score
            else
            {
                overviewResult.visible = false;
                singleResult.visible = true;
                navBack.visible = true;

                result = matchResults.users[resultIndex].score;

                // Save Replay Button
                navSaveReplay.enabled = _score.canSendScore(result, true, false, true, true);

                // Update
                singleResult.update(result);
            }

            // Highscores
            navHighscores.enabled = matchResults.songInfo && !matchResults.songInfo.engine;
        }

        //******************************************************************************************//
        // Helper Functions
        //******************************************************************************************//

        /**
         * Handles Auto Judge Offset options by changing the judge offset and saving
         * the user settings. This is called when scores are saved successfully.
         * @param result GameScoreResult
         */
        private function updateJudgeOffset(result:GameScoreResult):void
        {
            if (_gvars.activeUser.AUTO_JUDGE_OFFSET && // Auto Judge Offset enabled
                (result.amazing + result.perfect + result.good + result.average >= 50) && // Accuracy data is reliable
                result.accuracy !== 0)
            {
                _gvars.activeUser.JUDGE_OFFSET = Number(result.accuracy_frames.toFixed(3));
                // Save settings
                _gvars.activeUser.saveLocal();
                _gvars.activeUser.save();
            }
        }

        //******************************************************************************************//
        // Event Handlers
        //******************************************************************************************//

        /**
         * Handles all UI events, both mouse and keyboard.
         * @param e
         */
        private function eventHandler(e:* = null):void
        {
            var target:DisplayObject = e.target;

            // Don't do anything with popups open.
            if (_gvars.gameMain.current_popup != null)
                return;

            // Handle Key events and click in the same function
            if (e.type == "keyDown")
            {
                target = null;
                var keyCode:int = e.keyCode;
                if ((keyCode == _gvars.playerUser.keyLeft || keyCode == Keyboard.LEFT) && navBack.visible)
                {
                    target = navBack;
                }
                else if (keyCode == _gvars.playerUser.keyQuit)
                {
                    target = navMenu;
                    stage.removeEventListener(KeyboardEvent.KEY_DOWN, eventHandler);
                }
            }


            if (!target)
                return;

            // Based on target
            if (target == navSaveReplay)
            {
                if (result.user.siteId == _gvars.activeUser.siteId)
                {
                    _score.saveServerReplay(result);
                }
            }

            else if (target == navScreenShot)
            {
                navScreenShot.purgeHoverSprite();
                if (e.ctrlKey)
                {
                    _gvars.saveScreenshotToClipboard()
                }
                else
                {
                    var ext:String = "";
                    if (resultIndex >= 0)
                    {
                        ext = result.screenshot_path;
                    }
                    _gvars.takeScreenShot(ext);
                }
            }

            else if (target == navBack)
            {
                displayGameResult(-1);
            }

            else if (target == navOptions)
            {
                addPopup(Main.POPUP_OPTIONS);
            }

            else if (target == navHighscores)
            {
                addPopup(new PopupHighscores(this, matchResults.songInfo));
            }

            else if (target == navMenu)
            {
                switchTo(Main.GAME_MENU_PANEL);
            }
        }
    }
}
