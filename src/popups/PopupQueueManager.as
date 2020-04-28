package popups
{
    import arc.mp.MultiplayerPrompt;
    import assets.GameBackgroundColor;
    import classes.Box;
    import classes.BoxButton;
    import classes.Language;
    import classes.Playlist;
    import classes.replay.Replay;
    import classes.SongQueueItem;
    import classes.Text;
    import com.flashfla.components.ScrollBar;
    import com.flashfla.components.ScrollPane;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import menu.MenuPanel;

    public class PopupQueueManager extends MenuPanel
    {
        private const TAB_MAIN:int = 0;
        private const TAB_PREGEN:int = 1;

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _playlist:Playlist = Playlist.instanceCanon;

        private var CURRENT_TAB:int = TAB_MAIN;

        private static var STAT_LIST:Array;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var scrollpane:ScrollPane;
        private var scrollbar:ScrollBar;

        private var menuMain:BoxButton;
        private var menuPregen:BoxButton;
        private var importBtn:BoxButton;
        private var closeBtn:BoxButton;

        public function PopupQueueManager(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function stageAdd():void
        {
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

            var titleDisplay:Text = new Text(_lang.string("popup_queue_manager"), 20);
            titleDisplay.x = 10;
            titleDisplay.y = 8;
            titleDisplay.width = box.width - 10;
            box.addChild(titleDisplay);

            menuMain = new BoxButton(125, 25, _lang.string("options_queue_saved"));
            menuMain.x = box.width - menuMain.width * 2 - 30;
            menuMain.y = 8;
            menuMain.menu_select = TAB_MAIN;
            menuMain.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(menuMain);

            menuPregen = new BoxButton(125, 25, _lang.string("options_queue_premade"));
            menuPregen.x = box.width - menuMain.width - 15;
            menuPregen.y = 8;
            menuPregen.menu_select = TAB_PREGEN;
            menuPregen.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(menuPregen);

            //- content
            scrollpane = new ScrollPane(box.width - 45, 341);
            scrollpane.x = 10;
            scrollpane.y = 42;
            scrollpane.graphics.lineStyle(1, 0x64A4B8, 0.25, true);
            scrollpane.graphics.drawRect(0, 0, scrollpane.width - 1, scrollpane.height - 1);
            scrollpane.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
            box.addChild(scrollpane);
            scrollbar = new ScrollBar(20, 341);
            scrollbar.x = 10 + scrollpane.width;
            scrollbar.y = 42;
            scrollbar.addEventListener(Event.CHANGE, scrollBarMoved);
            box.addChild(scrollbar);

            renderQueues();

            //- importBtn
            importBtn = new BoxButton(79.5, 27, "IMPORT");
            importBtn.x = box.width - 180;
            importBtn.y = box.height - 42;
            importBtn.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(importBtn);

            //- Close
            closeBtn = new BoxButton(79.5, 27, "CLOSE");
            closeBtn.x = box.width - 94.5;
            closeBtn.y = box.height - 42;
            closeBtn.addEventListener(MouseEvent.CLICK, clickHandler);
            box.addChild(closeBtn);
        }

        private function scrollBarMoved(e:Event):void
        {
            scrollpane.scrollTo(scrollbar.scroll);
        }

        private function mouseWheelHandler(e:MouseEvent):void
        {
            var dist:Number = scrollbar.scroll + (scrollpane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            scrollpane.scrollTo(dist);
            scrollbar.scrollTo(dist);
        }

        override public function stageRemove():void
        {
            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        public function renderQueues():void
        {
            var yOffset:int = 0;
            var sI:QueueBox;
            var sX:int = 0;

            scrollbar.reset();
            scrollpane.clear();

            if (CURRENT_TAB == TAB_MAIN)
            {
                // Display Custom User Queues
                if (_gvars.playerUser.songQueues.length > 0)
                {
                    for each (var sqi:SongQueueItem in _gvars.playerUser.songQueues)
                    {
                        if (sqi.items.length > 0)
                        {
                            sI = new QueueBox(this, sqi);
                            sI.y = yOffset;
                            sI.index = sX;
                            scrollpane.content.addChild(sI);
                            yOffset += sI.height + 5;
                            sX += 1;
                        }
                        else
                        {
                            _gvars.playerUser.songQueues.splice(_gvars.playerUser.songQueues.indexOf(sqi), 1);
                        }
                    }
                }
                else
                {
                    var noSavedDisplay:Text = new Text(_lang.string("popup_queue_no_queues"));
                    noSavedDisplay.x = 10;
                    noSavedDisplay.y = 8;
                    noSavedDisplay.width = box.width - 10;
                    scrollpane.content.addChild(noSavedDisplay);
                }
            }
            else if (CURRENT_TAB == TAB_PREGEN)
            {
                genResultBasedQueues();

                // Display Premade Genre Queues
                for (var curGenre:String in _playlist.generatedQueues)
                {
                    sI = new QueueBox(this, new SongQueueItem(_lang.string("genre_" + (int(curGenre) - 1)), _playlist.generatedQueues[curGenre]), false, true);
                    sI.y = yOffset;
                    sI.index = sX;
                    scrollpane.content.addChild(sI);
                    yOffset += sI.height + 5;
                    sX += 1;
                }

                // Display Premade Stats queues
                for (var stat:String in STAT_LIST)
                {
                    sI = new QueueBox(this, STAT_LIST[stat], false, true);
                    sI.y = yOffset;
                    sI.index = sX;
                    scrollpane.content.addChild(sI);
                    yOffset += sI.height + 5;
                    sX += 1;
                }
            }
            scrollpane.update();
            scrollpane.scrollTo(scrollbar.scroll, false);
            scrollbar.draggerVisibility = (yOffset > scrollpane.height);
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == importBtn)
            {
                var prompt:MultiplayerPrompt = new MultiplayerPrompt(box.parent, "Import Song Queue");
                prompt.move(Main.GAME_WIDTH / 2 - prompt.width / 2, Main.GAME_HEIGHT / 2 - prompt.height / 2);
                prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
                {
                    var temp:SongQueueItem = SongQueueItem.fromString(subevent.params.value);
                    if (temp.items.length > 0)
                    {
                        _gvars.playerUser.songQueues.push(temp);
                        renderQueues();
                    }
                });
            }
            else if (e.target == menuPregen)
            {
                CURRENT_TAB = TAB_PREGEN;
                renderQueues();
                return;
            }
            else if (e.target == menuMain)
            {
                CURRENT_TAB = TAB_MAIN;
                renderQueues();
                return;
            }
            //- Close
            if (e.target == closeBtn)
            {
                removePopup();
                return;
            }
        }

        private function genResultBasedQueues():void
        {
            var songlist:Array = [];
            STAT_LIST = [];
            for (var index:String in _playlist.indexList)
            {

                var _song:Object = _playlist.indexList[index];
                var _rank:Object = _gvars.activeUser.getLevelRank(_song);
                var _access:int = _gvars.checkSongAccess(_song);

                if (_access == GlobalVariables.SONG_ACCESS_PLAYABLE)
                {
                    var stats:int = GlobalVariables.getSongIconIndex(_song, _rank);
                    if (!songlist[stats])
                    {
                        songlist[stats] = [];
                    }
                    songlist[stats].push(_song.level);
                }
            }
            for (var rank:String in songlist)
            {
                var name:String = GlobalVariables.SONG_ICON_TEXT[rank];
                STAT_LIST.push(new SongQueueItem((name == "" ? "PLAYED" : name), songlist[rank]));
            }
        }
    }
}

import arc.mp.MultiplayerPrompt;
import classes.Box;
import classes.BoxButton;
import classes.Playlist;
import classes.SongQueueItem;
import classes.Text;
import com.flashfla.utils.TimeUtil;
import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.system.System;
import menu.MainMenu;
import menu.MenuSongSelection;
import popups.PopupQueueManager;

internal class QueueBox extends Sprite
{
    private var _gvars:GlobalVariables = GlobalVariables.instance;
    private var _playlist:Playlist = Playlist.instanceCanon;

    //- Song Details
    public var box:Box;
    public var index:int;
    private var copyBtn:BoxButton;
    private var deleteBtn:BoxButton;
    private var playBtn:BoxButton;
    private var renameBtn:BoxButton;
    private var queueItem:SongQueueItem;
    private var popup:PopupQueueManager;

    public function QueueBox(p:PopupQueueManager, qi:SongQueueItem, longview:Boolean = true, premade:Boolean = false):void
    {
        this.popup = p;
        this.queueItem = qi;

        //- Make Display
        var yOffset:int = 25;

        // Draw Box
        box = new Box(690, (!longview ? 35 : queueItem.items.length * 20 + 30), false);
        this.addChild(box);

        // Add Song Names
        var totalTime:int = 0;
        for each (var songid:int in queueItem.items)
        {
            var songData:Object = _playlist.playList[songid];
            if (songData)
            {
                if (longview)
                {
                    var access:int = _gvars.checkSongAccess(songData);
                    var songName:Text = new Text(" - " + songData["name"] + " [" + songData["time"] + "]", 12, access == GlobalVariables.SONG_ACCESS_PLAYABLE ? "#FFFFFF" : "#FF9797");
                    songName.x = 5;
                    songName.y = yOffset;
                    box.addChild(songName);
                    yOffset += 20;
                }
                totalTime += songData["timeSecs"];
            }
        }

        // Add Queue Names + Info
        var queueName:Text = new Text(queueItem.name + " [" + TimeUtil.convertToHHMMSS(totalTime) + "]", 14);
        queueName.x = 5;
        queueName.y = 5;
        box.addChild(queueName);

        if (!premade)
        {
            //- Copy Button
            copyBtn = new BoxButton(70, 25, "COPY");
            copyBtn.x = box.width - 75;
            copyBtn.y = 5;
            box.addChild(copyBtn);

            //- Delete Button
            deleteBtn = new BoxButton(70, 25, "DELETE");
            deleteBtn.x = copyBtn.x - 75;
            deleteBtn.y = 5;
            box.addChild(deleteBtn);

            //- Rename Button
            renameBtn = new BoxButton(70, 25, "RENAME");
            renameBtn.x = deleteBtn.x - 75;
            renameBtn.y = 5;
            box.addChild(renameBtn);
        }

        //- PLAY Button
        playBtn = new BoxButton(70, 25, "PLAY");
        playBtn.x = (renameBtn ? renameBtn.x - 75 : box.width - 75);
        playBtn.y = 5;
        box.addChild(playBtn);

        this.addEventListener(MouseEvent.CLICK, clickEvent);
    }

    private function clickEvent(e:MouseEvent):void
    {
        if (e.target == copyBtn)
            copyQueue();
        else if (e.target == deleteBtn)
            deleteQueue();
        else if (e.target == playBtn)
            playQueue();
        else if (e.target == renameBtn)
            renameQueue();
    }

    private function copyQueue():void
    {
        try
        {
            System.setClipboard(this.queueItem.toString());
            Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, this.queueItem.toString());
        }
        catch (e:Error)
        {
        }
    }

    private function deleteQueue():void
    {
        _gvars.playerUser.songQueues.splice(_gvars.playerUser.songQueues.indexOf(this.queueItem), 1);
        popup.renderQueues();
        _gvars.playerUser.save();
    }

    private function playQueue():void
    {
        _gvars.songQueue = [];
        for each (var songid:int in queueItem.items)
        {
            var songData:Object = _playlist.playList[songid];
            if (songData)
            {
                var access:int = _gvars.checkSongAccess(songData);
                if (access == GlobalVariables.SONG_ACCESS_PLAYABLE)
                {
                    _gvars.songQueue.push(songData);
                }
            }
        }

        popup.removePopup();
        var panel:MenuSongSelection = ((_gvars.gameMain.activePanel as MainMenu).panel as MenuSongSelection);
        panel.buildPlayList();
        panel.buildInfoTab();
    }

    private function renameQueue():void
    {
        var prompt:MultiplayerPrompt = new MultiplayerPrompt(this.popup, "Rename");
        prompt.move(Main.GAME_WIDTH / 2 - prompt.width / 2, Main.GAME_HEIGHT / 2 - prompt.height / 2);
        prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
        {
            queueItem.name = subevent.params.value;
            popup.renderQueues();
            _gvars.playerUser.save();
        });
    }

    public function dispose():void
    {
        //- Remove is already existed.
        if (box != null)
        {
            box.dispose();
            this.removeChild(box);
            box = null;
        }
    }
}
