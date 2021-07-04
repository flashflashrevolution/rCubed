package popups
{
    import arc.ArcGlobals;
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.FileTracker;
    import classes.Language;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.replay.Replay;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.BoxText;
    import classes.ui.Prompt;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.Text;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.utils.getTimer;
    import menu.MenuPanel;

    public class PopupReplayHistory extends MenuPanel
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        private var EXTERNAL_REPLAYS:Object = {};
        private var EXTERNAL_REPLAYS_LIST:Array = [];
        private var INTERNAL_REPLAYS:Object = {"all": 0};
        private var INTERNAL_REPLAYS_LIST:Array = ["all"];
        private var DRAW_EXTERNAL:Boolean = false;

        private var ENGINE_EXTERNAL_ID:String = "";
        private var ENGINE_RECENT_ID:String = "all";

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var engine_list:Sprite;
        private var engine_list_mask:Sprite;
        private var engine_search:BoxText;
        private var searchDelay:Number = 0;

        private var engine_list_left:Sprite;
        private var engine_list_right:Sprite;

        private var scrollpane:ScrollPane;
        private var scrollbar:ScrollBar;

        private var titleDisplay:Text;
        private var itemDisplay:Text;
        private var sourceBtn:BoxButton;
        private var importBtn:BoxButton;
        private var closeBtn:BoxButton;

        private var loadNumberText:Text;

        private var FILE_TRACK:FileTracker;

        public function PopupReplayHistory(myParent:MenuPanel)
        {
            super(myParent);

            loadNumberText = new Text(null, 10, 165, "0/0");
            loadNumberText.setAreaParams(670, 20, "center");

            engine_list_left = new Sprite();
            engine_list_left.x = 12;
            engine_list_left.y = 48;
            engine_list_left.buttonMode = true;
            engine_list_left.useHandCursor = true;
            engine_list_left.graphics.lineStyle(1, 0xffffff, 0.85);
            engine_list_left.graphics.beginFill(0xffffff, 0.5);
            engine_list_left.graphics.moveTo(7, 0);
            engine_list_left.graphics.lineTo(7, 12);
            engine_list_left.graphics.lineTo(0, 6);
            engine_list_left.graphics.lineTo(7, 0);
            engine_list_left.graphics.endFill();
            engine_list_left.addEventListener(MouseEvent.CLICK, e_boxClickHandler);

            engine_list_right = new Sprite();
            engine_list_right.x = 121;
            engine_list_right.y = 48;
            engine_list_right.buttonMode = true;
            engine_list_right.useHandCursor = true;
            engine_list_right.graphics.lineStyle(1, 0xffffff, 0.85);
            engine_list_right.graphics.beginFill(0xffffff, 0.5);
            engine_list_right.graphics.moveTo(0, 0);
            engine_list_right.graphics.lineTo(8, 6);
            engine_list_right.graphics.lineTo(0, 13);
            engine_list_right.graphics.lineTo(0, 0);
            engine_list_right.graphics.endFill();
            engine_list_right.addEventListener(MouseEvent.CLICK, e_boxClickHandler);
        }

        override public function stageAdd():void
        {
            bmd = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(stage);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));
            bmp = new Bitmap(bmd);

            this.addChild(bmp);

            var bgbox:Box = new Box(this, 20, 20, false, false);
            bgbox.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;

            box = new Box(this, 20, 20, false, false);
            box.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            box.activeAlpha = 0.4;

            titleDisplay = new Text(box, 5, 8, _lang.string("popup_replay_history"), 20);
            titleDisplay.width = box.width - 10;
            titleDisplay.align = Text.CENTER;

            //- replay count / file size
            itemDisplay = new Text(box, 5, 8, _lang.string("popup_replay_count"), 14);
            itemDisplay.width = box.width - 10;
            itemDisplay.align = Text.RIGHT;
            itemDisplay.visible = false;

            //- replay search
            engine_search = new BoxText(box, 10, 10, 150, 20);
            engine_search.addEventListener(Event.CHANGE, e_searchChange);

            //- engine list
            engine_list_mask = new Sprite();
            engine_list_mask.graphics.beginFill(0xff0000, 1);
            engine_list_mask.graphics.drawRect(-1, -10, box.width - 53, 47);
            engine_list_mask.graphics.endFill();
            engine_list = new Sprite();
            engine_list.x = 10;
            engine_list.y = 40;
            engine_list.addEventListener(MouseEvent.CLICK, e_engineSourceClick);
            box.addChild(engine_list);
            box.addChild(engine_list_left);
            box.addChild(engine_list_right);
            engine_list_right.x = box.width - 25;
            engine_list_mask.x = 15;

            //- content
            scrollpane = new ScrollPane(box, 10, 72, box.width - 45, 311, mouseWheelHandler);
            scrollpane.graphics.lineStyle(1, 0x64A4B8, 0.25, true);
            scrollpane.graphics.drawRect(0, 0, scrollpane.width - 1, scrollpane.height - 1);
            scrollbar = new ScrollBar(box, 10 + scrollpane.width, 72, 20, 311, null, null, scrollBarMoved);

            //- importBtn
            importBtn = new BoxButton(box, box.width - 180, box.height - 42, 79.5, 27, _lang.string("popup_replay_import"), 12, e_boxClickHandler);

            //- Close
            closeBtn = new BoxButton(box, box.width - 94.5, box.height - 42, 79.5, 27, _lang.string("menu_close"), 12, e_boxClickHandler);

            //- Recent/External Swap
            sourceBtn = new BoxButton(box, 20, box.height - 42, 79.5, 27, _lang.string("popup_replay_external"), 12, e_boxClickHandler);

            //- Build Recent Engine List
            for each (var r:Replay in _gvars.replayHistory)
            {
                if (r.isValid())
                {
                    var engineID:String = (r.settings.arc_engine ? r.settings.arc_engine.engineID : Constant.BRAND_NAME_SHORT_LOWER);
                    if (INTERNAL_REPLAYS[engineID] == null)
                    {
                        INTERNAL_REPLAYS_LIST.push(engineID);
                        INTERNAL_REPLAYS[engineID] = 0;
                    }
                    INTERNAL_REPLAYS["all"]++;
                    INTERNAL_REPLAYS[engineID]++;
                }
            }

            renderReplays();
        }

        private function e_loadExternalQueue(e:Event):void
        {
            var sT:Number = getTimer();
            var eT:Number = sT;
            var loadCount:int = 0;
            var loadCap:int = Math.min(FILE_TRACK.file_paths.length, 100);
            while (loadCount < loadCap)
            {
                if (FILE_TRACK.file_paths.length <= 0)
                    break;

                eT = getTimer();
                if (eT - sT > 25) // 25ms, prevent UI freezing.
                    break;

                var txt:String = AirContext.readFile(AirContext.getAppFile(FILE_TRACK.file_paths.shift())).toString();
                var r:Replay = new Replay(new Date().getTime() + loadCount);
                r.parseEncode(txt, false);
                r.fileReplay = true;
                if (r.isValid())
                {
                    var engineID:String = (r.settings.arc_engine ? r.settings.arc_engine.engineID : Constant.BRAND_NAME_SHORT_LOWER);
                    if (EXTERNAL_REPLAYS[engineID] == null)
                    {
                        EXTERNAL_REPLAYS_LIST.push(engineID);
                        EXTERNAL_REPLAYS[engineID] = [];
                    }
                    EXTERNAL_REPLAYS[engineID].push(r);
                }
                loadCount++;
            }

            var fileRemaining:int = FILE_TRACK.file_paths.length;

            if (DRAW_EXTERNAL)
            {
                loadNumberText.text = ((FILE_TRACK.files - fileRemaining) + " / " + FILE_TRACK.files);
                scrollpane.content.graphics.clear();
                scrollpane.content.graphics.lineStyle(1, 0x64A4B8, 0.75, true);
                scrollpane.content.graphics.beginFill(0x35a535, 0);
                scrollpane.content.graphics.drawRect(10, 165, 670, 20);
                scrollpane.content.graphics.endFill();
                scrollpane.content.graphics.lineStyle(1, 0xffffff, 0);
                scrollpane.content.graphics.beginFill(0x35a535, 1);
                scrollpane.content.graphics.drawRect(10, 165, 670 * ((FILE_TRACK.files - fileRemaining) / FILE_TRACK.files), 20);
                scrollpane.content.graphics.endFill();
            }

            if (fileRemaining <= 0)
            {
                this.removeEventListener(Event.ENTER_FRAME, e_loadExternalQueue);
                EXTERNAL_REPLAYS_LIST.sort(Array.CASEINSENSITIVE);

                scrollpane.content.removeChild(loadNumberText);
            }

            if (DRAW_EXTERNAL && fileRemaining <= 0)
                renderReplays();
        }

        private function scrollBarMoved(e:Event):void
        {
            scrollpane.scrollTo(scrollbar.scroll);
        }

        private function mouseWheelHandler(e:MouseEvent):void
        {
            if (scrollbar.draggerVisibility)
            {
                var dist:Number = scrollbar.scroll + (scrollpane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
                scrollpane.scrollTo(dist);
                scrollbar.scrollTo(dist);
            }
        }

        override public function stageRemove():void
        {
            this.removeEventListener(Event.ENTER_FRAME, e_loadExternalQueue);
            this.removeEventListener(Event.ENTER_FRAME, e_searchDelay);
            EXTERNAL_REPLAYS = {};
            EXTERNAL_REPLAYS_LIST = [];

            scrollpane.clear();

            sourceBtn.dispose();
            importBtn.dispose();
            closeBtn.dispose();

            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        public function renderReplays():void
        {
            scrollbar.reset();
            scrollpane.clear();

            if (DRAW_EXTERNAL)
                drawExternalReplays();
            else
                drawReplayHistory();

            scrollpane.update();
            scrollpane.scrollTo(scrollbar.scroll, false);
            scrollbar.draggerVisibility = (scrollpane.content.height > scrollpane.height);
        }

        private function e_searchChange(e:Event):void
        {
            if (searchDelay == 0)
            {
                this.addEventListener(Event.ENTER_FRAME, e_searchDelay);
            }
            searchDelay = getTimer() + 400;
        }

        private function e_searchDelay(e:Event):void
        {
            if (getTimer() > searchDelay)
            {
                this.removeEventListener(Event.ENTER_FRAME, e_searchDelay);
                renderReplays();
                searchDelay = 0;
            }
        }

        private function e_engineSourceClick(e:MouseEvent):void
        {
            if (e.target is BoxButton)
            {
                if (DRAW_EXTERNAL)
                    ENGINE_EXTERNAL_ID = e.target.engine_id;
                else
                    ENGINE_RECENT_ID = e.target.engine_id;
                renderReplays();
            }
        }

        private function e_importReplay(replayString:String):void
        {
            var r:Replay = new Replay(new Date().getTime());
            r.parseEncode(replayString);
            if (r.isEdited)
                Alert.add(_lang.string("popup_replay_import_edited"), 180);
            if (r.isValid())
            {
                _gvars.replayHistory.unshift(r);
                var engineID:String = (r.settings.arc_engine ? r.settings.arc_engine.engineID : Constant.BRAND_NAME_SHORT_LOWER);
                if (INTERNAL_REPLAYS[engineID] == null)
                {
                    INTERNAL_REPLAYS_LIST.push(engineID);
                    INTERNAL_REPLAYS[engineID] = 0;
                }
                INTERNAL_REPLAYS["all"]++;
                INTERNAL_REPLAYS[engineID]++;
                renderReplays();
            }
            else
                Alert.add(_lang.string("popup_replay_import_invalid"));
        }

        private function e_boxClickHandler(e:MouseEvent):void
        {
            if (e.target == engine_list_left)
            {
                if (engine_list_left.alpha > 0.75)
                    engineListShift(1);
            }
            else if (e.target == engine_list_right)
            {
                if (engine_list_right.alpha > 0.75)
                    engineListShift(-1);
            }
            else if (e.target == sourceBtn)
            {
                DRAW_EXTERNAL = !DRAW_EXTERNAL;
                titleDisplay.text = _lang.string(DRAW_EXTERNAL ? "popup_replay_title_external" : "popup_replay_history");
                sourceBtn.text = _lang.string(DRAW_EXTERNAL ? "popup_replay_recent" : "popup_replay_external");
                itemDisplay.visible = DRAW_EXTERNAL;
                renderReplays();
            }
            else if (e.target == importBtn)
            {
                new Prompt(box.parent, 320, _lang.string("popup_replay_import_window_title"), 100, "IMPORT", e_importReplay);
            }
            //- Close
            else if (e.target == closeBtn)
            {
                removePopup();
                return;
            }
        }

        private function drawEngineList():void
        {
            var list:Array;
            var engineID:String;
            var selectedID:String;
            var r3Index:int;

            if (DRAW_EXTERNAL)
            {
                list = EXTERNAL_REPLAYS_LIST;
                if (ENGINE_EXTERNAL_ID == "" && EXTERNAL_REPLAYS_LIST.length > 0)
                    ENGINE_EXTERNAL_ID = EXTERNAL_REPLAYS_LIST[0];
                selectedID = ENGINE_EXTERNAL_ID;

                // Move R3 to the top.
                r3Index = -1;
                if ((r3Index = EXTERNAL_REPLAYS_LIST.indexOf(Constant.BRAND_NAME_SHORT_LOWER)) >= 1)
                {
                    EXTERNAL_REPLAYS_LIST.splice(r3Index, 1);
                    EXTERNAL_REPLAYS_LIST.unshift(Constant.BRAND_NAME_SHORT_LOWER);
                }
            }
            else
            {
                list = INTERNAL_REPLAYS_LIST;
                if (ENGINE_RECENT_ID == "" && INTERNAL_REPLAYS_LIST.length > 0)
                    ENGINE_RECENT_ID = INTERNAL_REPLAYS_LIST[0];
                selectedID = ENGINE_RECENT_ID;

                // Move R3 to the top.
                r3Index = -1;
                if ((r3Index = INTERNAL_REPLAYS_LIST.indexOf(Constant.BRAND_NAME_SHORT_LOWER)) >= 2)
                {
                    INTERNAL_REPLAYS_LIST.splice(r3Index, 1);
                    INTERNAL_REPLAYS_LIST.insertAt(1, Constant.BRAND_NAME_SHORT_LOWER);
                }
            }

            while (engine_list.numChildren > 0)
                engine_list.removeChildAt(0);

            var xOffset:int = 0;

            if (list.length > 5)
            {
                if (!engine_list.contains(engine_list_mask))
                {
                    engine_list.addChild(engine_list_mask);
                    engine_list.mask = engine_list_mask;
                }
                xOffset = 14;
            }
            else
            {
                if (engine_list.contains(engine_list_mask))
                {
                    engine_list.mask = null;
                    engine_list.removeChild(engine_list_mask);
                }
            }

            for (var i:int = 0; i < list.length; i++)
            {
                engineID = list[i];
                var engineBox:BoxButton = new BoxButton(engine_list, i * 138 + xOffset, 0, 133, 27, engineID.toUpperCase() + " (" + (DRAW_EXTERNAL ? EXTERNAL_REPLAYS[engineID].length : INTERNAL_REPLAYS[engineID]) + ")", 12);
                engineBox.engine_id = engineID;
                engineBox.alpha = engineID == selectedID ? 1 : 0.5;
            }

            updateEngineListArrows();
        }

        private function engineListShift(dir:int):void
        {
            for (var i:int = engine_list.numChildren - 1; i > 0; i--)
            {
                var chd:* = engine_list.getChildAt(i);
                if (chd is BoxButton)
                {
                    chd.x += 138 * dir;
                }
            }
            updateEngineListArrows();
        }

        private function updateEngineListArrows():void
        {
            if (engine_list.numChildren < 6)
            {
                engine_list_left.visible = engine_list_right.visible = false;
                return;
            }
            engine_list_left.visible = engine_list_right.visible = true;
            engine_list_left.alpha = engine_list.getChildAt(1).x < 0 ? 1 : 0.25;
            engine_list_right.alpha = engine_list.getChildAt(engine_list.numChildren - 1).x > engine_list_mask.width - 50 ? 1 : 0.25;
        }

        private function drawExternalReplays():void
        {
            if (FILE_TRACK == null)
            {
                FILE_TRACK = AirContext.getFileSize(AirContext.getAppFile("replays"), null, true);
                if (FILE_TRACK.file_paths.length > 0)
                {
                    this.addEventListener(Event.ENTER_FRAME, e_loadExternalQueue);
                }
            }

            itemDisplay.text = sprintf(_lang.string("popup_replay_count"), {"file_count": FILE_TRACK.files, "file_size": FILE_TRACK.size_human});

            if (FILE_TRACK.files > 0 && FILE_TRACK.file_paths.length > 0)
            {
                if (loadNumberText.parent == null)
                    scrollpane.content.addChild(loadNumberText);
                return;
            }

            drawEngineList();

            // Display
            var yOffset:int = 0;
            var sI:ReplayBox;
            var sX:int = 0;
            var song:SongInfo;
            var searchText:String = engine_search.text.toLowerCase();

            for each (var r:Replay in EXTERNAL_REPLAYS[ENGINE_EXTERNAL_ID])
            {
                song = r.settings.arc_engine ? ArcGlobals.instance.legacyDecode(r.settings.arc_engine) : Playlist.instanceCanon.getSongInfo(r.level);

                if (song == null)
                    continue;

                if (searchText.length >= 3 && song.name.toLowerCase().indexOf(searchText) == -1)
                    continue;

                sI = new ReplayBox(this, r, song);
                sI.y = yOffset;
                sI.index = sX;
                scrollpane.content.addChild(sI);
                var boxHeight:Number = (sI.height / 2);
                yOffset += sI.height + 5;
                sX++;
            }
        }

        private function drawReplayHistory():void
        {
            if (loadNumberText.parent != null)
            {
                scrollpane.graphics.clear();
                scrollpane.content.removeChild(loadNumberText);
            }

            drawEngineList();

            var yOffset:int = 0;
            var sI:ReplayBox;
            var sX:int = 0;
            var songInfo:SongInfo;
            var searchText:String = engine_search.text.toLowerCase();

            for each (var r:Replay in _gvars.replayHistory)
            {
                var engineID:String = (r.settings.arc_engine ? r.settings.arc_engine.engineID : Constant.BRAND_NAME_SHORT_LOWER);
                if (ENGINE_RECENT_ID != "all" && ENGINE_RECENT_ID != engineID)
                    continue;

                songInfo = r.settings.arc_engine ? ArcGlobals.instance.legacyDecode(r.settings.arc_engine) : Playlist.instanceCanon.getSongInfo(r.level);

                if (songInfo == null)
                    continue;

                if (searchText.length >= 3 && songInfo.name.toLowerCase().indexOf(searchText) == -1)
                    continue;

                sI = new ReplayBox(this, r, songInfo);
                sI.y = yOffset;
                sI.index = sX;
                scrollpane.content.addChild(sI);
                yOffset += sI.height + 5;
                sX++;
            }
        }
    }
}

import classes.Alert;
import classes.Language;
import classes.SongInfo;
import classes.replay.Replay;
import classes.ui.Box;
import classes.ui.BoxButton;
import classes.ui.Text;
import com.flashfla.utils.NumberUtil;
import com.flashfla.utils.SystemUtil;
import com.flashfla.utils.sprintf;
import flash.display.Sprite;
import flash.events.MouseEvent;
import game.GameOptions;
import popups.PopupReplayHistory;

internal class ReplayBox extends Sprite
{
    private var _gvars:GlobalVariables = GlobalVariables.instance;
    private var _lang:Language = Language.instance;

    //- Song Details
    private var nameText:Text;
    private var scoreText:Text;
    private var resultsText:Text;
    private var copyBtn:BoxButton;
    private var deleteBtn:BoxButton;
    private var replay:Replay;
    private var songInfo:SongInfo;
    public var index:Number;
    public var box:Box;
    public var popup:PopupReplayHistory;

    public function ReplayBox(p:PopupReplayHistory, r:Replay, s:SongInfo):void
    {
        this.popup = p;
        this.replay = r;
        this.songInfo = s;

        //- Make Display
        box = new Box(this, 0, 0, false);
        box.setSize(690, 52);
        if (replay.isEdited)
            box.color = 0xff0000;

        //- Name
        nameText = new Text(box, 5, 0, (replay.user && replay.user.siteId != _gvars.playerUser.siteId && replay.user.name ? replay.user.name + " - " : "") + (songInfo["engine"] && !replay.fileReplay ? songInfo["engine"]["name"] + ": " : "") + songInfo["name"], 14);
        nameText.setAreaParams(525, 27);
        nameText.mouseEnabled = false;

        //- Score
        scoreText = new Text(box, box.width - 217, 0, sprintf(_lang.string("popup_replay_score"), {"score": NumberUtil.numberFormat(r.score)}), 14);
        scoreText.setAreaParams(213, 27, "right");
        scoreText.mouseEnabled = false;

        //- Results
        resultsText = new Text(box, 5, 27, r.perfect + " - " + r.good + " - " + r.average + " - " + r.miss + " - " + r.boo + " - " + r.maxcombo, 12);
        resultsText.setAreaParams(350, 27);
        resultsText.mouseEnabled = false;

        //- Copy Button
        copyBtn = new BoxButton(box, box.width - 75, 27, 70, 20, _lang.string("popup_replay_copy"));

        //- Delete Button
        deleteBtn = new BoxButton((!r.fileReplay) ? box : null, copyBtn.x - 75, copyBtn.y, 70, 20, _lang.string("popup_replay_delete"));

        this.buttonMode = true;
        this.useHandCursor = true;
        this.mouseChildren = true;
        this.addEventListener(MouseEvent.CLICK, clickEvent);
    }

    private function clickEvent(e:MouseEvent):void
    {
        if (e.target == copyBtn)
            copyReplay();
        else if (e.target == deleteBtn)
            deleteReplay();
        else
            playReplay();
    }

    private function copyReplay():void
    {
        var replayString:String = this.replay.getEncode();
        var success:Boolean = SystemUtil.setClipboard(replayString);
        if (success)
        {
            Alert.add(_lang.string("clipboard_success"), 120, Alert.GREEN);
        }
        else
        {
            Alert.add(_lang.string("clipboard_failure"), 120, Alert.RED);
        }
    }

    private function deleteReplay():void
    {
        _gvars.replayHistory.splice(_gvars.replayHistory.indexOf(replay), 1);
        popup.renderReplays();
    }

    private function playReplay():void
    {
        if (songInfo == null)
        {
            Alert.add(_lang.string("popup_replay_missing_song_data"));
            return;
        }
        if (!replay.user.isLoaded())
            replay.user.loadUser(replay.user.siteId);

        _gvars.options = new GameOptions();
        _gvars.options.isolation = false;
        _gvars.options.replay = replay;
        _gvars.options.loadPreview = true;
        _gvars.options.fillFromReplay();
        _gvars.options.fillFromArcGlobals();

        _gvars.songResults.length = 0;
        _gvars.songQueue = [songInfo];

        _gvars.gameMain.removePopup();

        _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
    }

    public function dispose():void
    {
        //- Remove is already existed.
        if (box != null)
        {
            nameText.dispose();
            box.removeChild(nameText);
            nameText = null;
            scoreText.dispose();
            box.removeChild(scoreText);
            scoreText = null;
            resultsText.dispose();
            box.removeChild(resultsText);
            resultsText = null;

            copyBtn.dispose();
            deleteBtn.dispose();

            box.dispose();
            this.removeChild(box);
            box = null;
        }
    }

    override public function get height():Number
    {
        return 52;
    }
}
