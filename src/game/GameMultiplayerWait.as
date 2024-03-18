package game
{
    import assets.results.MPWaitBackground;
    import classes.Language;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCFFRResultsWait;
    import classes.mp.commands.MPCFFRScoreUpdate;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.mode.ffr.MPMatchFFRUser;
    import classes.mp.room.MPRoomFFR;
    import classes.score.ScoreHandler;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import game.results.GameResultBackground;
    import menu.MenuPanel;

    public class GameMultiplayerWait extends MenuPanel
    {
        private static const _gvars:GlobalVariables = GlobalVariables.instance;
        private static const _lang:Language = Language.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;
        private static const _score:ScoreHandler = ScoreHandler.instance;

        public var userResult:GameScoreResult;
        public var textWaiting:Text;

        public var startTime:Number = 0;
        public var chartLength:Number = 0;
        public var updateTimer:Timer;

        public var background:GameResultBackground;
        public var resultsDisplay:MPWaitBackground;
        public var throbber:Throbber;

        public var gotoResults:BoxButton;
        public var userDisplay:UserDisplayGroup;

        public function GameMultiplayerWait(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            // Get Local Results
            if (_gvars.songResults.length > 0)
            {
                userResult = _gvars.songResults[_gvars.songResults.length - 1];

                // Update Judge Offset
                updateJudgeOffset(userResult);

                // Send User Score
                _score.sendScore(userResult);
                _score.saveLocalReplay(userResult);

                // Clear Scores
                _gvars.songResults.length = 0;
            }

            return true;
        }

        override public function stageAdd():void
        {
            _mp.addEventListener(MPEvent.SOCKET_DISCONNECT, e_onMPDestroy);
            _mp.addEventListener(MPEvent.SOCKET_ERROR, e_onMPDestroy);
            _mp.addEventListener(MPEvent.ROOM_LEAVE_OK, e_onMPDestroy);
            _mp.addEventListener(MPEvent.ROOM_DELETE_OK, e_onMPDestroy);

            // Background
            background = new GameResultBackground();
            addChild(background);

            resultsDisplay = new MPWaitBackground();
            addChild(resultsDisplay);

            textWaiting = new Text(this, 20, 10, _lang.string("mp_room_ffr_match_wait"), 16, "#E2FEFF");
            textWaiting.setAreaParams(Main.GAME_WIDTH - 10, 26, "center");

            if (_mp.GAME_ROOM is MPRoomFFR)
            {
                const ffrRoom:MPRoomFFR = _mp.GAME_ROOM as MPRoomFFR;

                ffrRoom.lastMatchScorePersonal = userResult;

                _mp.addEventListener(MPEvent.FFR_MATCH_END, e_onFFRResults);

                // Final Score
                _mp.sendCommand(new MPCFFRScoreUpdate(ffrRoom, userResult.score, userResult.amazing, userResult.perfect, userResult.good, userResult.average, userResult.miss, userResult.boo, userResult.combo, userResult.max_combo));

                // Set to Waiting
                _mp.sendCommand(new MPCFFRResultsWait(ffrRoom));

                gotoResults = new BoxButton(this, 22, 428, 732, 40, _lang.string("mp_room_ffr_match_wait_skip"), 12, e_skipToResults); // TODO Language

                // Figure out waiting time.
                var lowestRate:Number = Number.POSITIVE_INFINITY;
                for each (var user:MPMatchFFRUser in ffrRoom.activeMatch.users)
                    if (user.rate < lowestRate)
                        lowestRate = user.rate;

                chartLength = Math.ceil(userResult.song.chart.Notes[userResult.song.chart.Notes.length - 1].time) * 1000;
                startTime = ffrRoom.activeMatch.startTime + 1500;

                var eclipsedTime:Number = getTimer() - startTime;
                var remainingTime:Number = Math.ceil(chartLength / lowestRate) - eclipsedTime;

                if (usersStillPlaying() > 0 && remainingTime >= 3)
                {
                    userDisplay = new UserDisplayGroup(this, ffrRoom);
                    userDisplay.x = 34;
                    userDisplay.y = 60;
                    addChild(userDisplay);

                    _mp.addEventListener(MPEvent.FFR_GAME_STATE, e_gameState);

                    updateTimer = new Timer(1000);
                    updateTimer.addEventListener(TimerEvent.TIMER, e_timerCountdown);
                    updateTimer.start();
                }
                else
                {
                    throbber = new Throbber(64, 64);
                    throbber.x = Main.GAME_WIDTH / 2 - 32;
                    throbber.y = Main.GAME_HEIGHT / 2 - 32;
                    throbber.start();
                    addChild(throbber);
                    gotoResults.enabled = false;
                }
            }
        }

        override public function stageRemove():void
        {
            _mp.removeEventListener(MPEvent.SOCKET_DISCONNECT, e_onMPDestroy);
            _mp.removeEventListener(MPEvent.SOCKET_ERROR, e_onMPDestroy);
            _mp.removeEventListener(MPEvent.ROOM_LEAVE_OK, e_onMPDestroy);
            _mp.removeEventListener(MPEvent.ROOM_DELETE_OK, e_onMPDestroy);

            if (updateTimer)
                updateTimer.stop();

            if (throbber)
                throbber.stop();

            if (_mp.GAME_ROOM is MPRoomFFR)
            {
                _mp.removeEventListener(MPEvent.FFR_GAME_STATE, e_gameState);
                _mp.removeEventListener(MPEvent.FFR_MATCH_END, e_onFFRResults);
            }
        }

        private function usersStillPlaying():Number
        {
            const ffrRoom:MPRoomFFR = _mp.GAME_ROOM as MPRoomFFR;

            var count:Number = 0;

            for each (var player:MPMatchFFRUser in ffrRoom.activeMatch.users)
            {
                if (player.user != _mp.currentUser && ffrRoom.getPlayerState(player.user) == "game")
                {
                    count++;
                }
            }

            return count;
        }

        private function e_timerCountdown(e:TimerEvent):void
        {
            userDisplay.update();
        }

        private function e_skipToResults(e:MouseEvent):void
        {
            const ffrRoom:MPRoomFFR = _mp.GAME_ROOM as MPRoomFFR;
            ffrRoom.lastMatchIndex = -2;
            switchTo(GameMenu.GAME_MP_RESULTS);
        }

        private function e_gameState(e:MPRoomEvent):void
        {
            if (e.room === _mp.GAME_ROOM)
            {
                userDisplay.update();
            }
        }

        private function e_onFFRResults(e:MPRoomEvent):void
        {
            switchTo(GameMenu.GAME_MP_RESULTS);
        }

        private function e_onMPDestroy(e:MPEvent):void
        {
            switchTo(Main.GAME_MENU_PANEL);
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
    }
}

import classes.ImageCache;
import classes.mp.Multiplayer;
import classes.mp.mode.ffr.MPMatchFFRUser;
import classes.mp.room.MPRoomFFR;
import classes.ui.ScrollBar;
import classes.ui.ScrollPane;
import classes.ui.Text;
import com.flashfla.utils.TimeUtil;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.utils.getTimer;
import game.GameMultiplayerWait;
import classes.Language;

internal class UserDisplayGroup extends Sprite
{
    public var panel:GameMultiplayerWait;
    public var room:MPRoomFFR;
    public var displays:Array = [];

    public var pane:ScrollPane;
    private var scrollbar:ScrollBar;

    public function UserDisplayGroup(panel:GameMultiplayerWait, room:MPRoomFFR):void
    {
        this.panel = panel;
        this.room = room;

        // Chat Log
        pane = new ScrollPane(this, 0, 0, 710, 349, e_mouseWheelHandler);
        scrollbar = new ScrollBar(this, 719, 0, 15, 349, null, null, e_scrollbarUpdater);

        for each (var player:MPMatchFFRUser in room.activeMatch.users)
        {
            var display:UserDisplay = new UserDisplay(panel, room, player);
            pane.content.addChild(display);
            displays.push(display);
        }

        scrollbar.draggerVisibility = displays.length > 12;

        position();
        update();
    }

    public function position():void
    {
        displays.sortOn(["weight", "name"], [Array.DESCENDING | Array.NUMERIC, Array.CASEINSENSITIVE]);

        var total:int = displays.length;
        var rowMax:int = 6;
        var rowIndex:int = 0;
        var startX:int = 0;
        var startY:int = (total <= rowMax * 2) ? (80 * (1 - Math.max(0, Math.floor(total / rowMax))) + 20) : 0;

        for (var i:int = 0; i < total; i++)
        {
            var display:UserDisplay = displays[i];

            if ((i % rowMax) == 0)
            {
                startX = (pane.width / 2) - (Math.min(rowMax, total - i) * 60);
                rowIndex = 0;
            }

            display.x = startX + (rowIndex * 120) + 4;
            display.y = Math.floor(i / rowMax) * 160 + startY;
            rowIndex++;
        }

        pane.update();
    }

    public function update():void
    {
        for each (var display:UserDisplay in displays)
        {
            display.update();
        }
    }

    /**
     * Mouse Wheel Handler for the Chat Log Pane.
     * Moves the scroll pane based on the scroll delta direction.
     * @param e
     */
    private function e_mouseWheelHandler(e:MouseEvent):void
    {
        // Sanity
        if (!scrollbar.draggerVisibility)
            return;

        // Scroll
        const newScrollPosition:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
        pane.scrollTo(newScrollPosition);
        scrollbar.scrollTo(newScrollPosition);
    }

    private function e_scrollbarUpdater(e:Event):void
    {
        pane.scrollTo(e.target.scroll);
    }
}

internal class UserDisplay extends Sprite
{
    private static const _lang:Language = Language.instance;

    public var panel:GameMultiplayerWait;
    public var room:MPRoomFFR;
    public var player:MPMatchFFRUser;

    public var textName:Text;
    public var textState:Text;
    public var avatar:Sprite;

    public function UserDisplay(panel:GameMultiplayerWait, room:MPRoomFFR, player:MPMatchFFRUser):void
    {
        this.panel = panel;
        this.player = player;
        this.room = room;

        this.graphics.beginFill(0xffffff, 0.15);
        this.graphics.drawRect(0, 0, 110, 150);
        this.graphics.endFill();

        textName = new Text(this, 5, 110, player.user.userLabelHTML);
        textName.setAreaParams(100, 22, "center");

        textState = new Text(this, 5, 127, player.user.userLabelHTML, 11, "#CBCBCB");
        textState.setAreaParams(100, 22, "center");

        avatar = ImageCache.getImage(player.user.avatarURL, ImageCache.ALIGN_MIDDLE, 100, 100);
        avatar.x = 55;
        avatar.y = 55;
        addChild(avatar);
    }

    public function update():void
    {
        if (room.getPlayerState(player.user) != "game")
            textState.text = _lang.string("mp_room_ffr_match_wait_finished");
        else
            textState.text = TimeUtil.convertToHMSS(remainingTime / 1000);

        this.alpha = player.alive ? 1 : 0.5;
    }

    public function get remainingTime():Number
    {
        return Math.max(0, Math.ceil(panel.chartLength / player.rate) - (getTimer() - panel.startTime));
    }

    override public function get name():String
    {
        return player.user.name;
    }

    public function get weight():Number
    {
        if (room.getPlayerState(player.user) == "game")
            return remainingTime;

        return 0;
    }
}
