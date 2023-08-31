package popups
{
    import assets.GameBackgroundColor;
    import classes.Language;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.SongQueueItem;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.Prompt;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.Text;
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

            var bgbox:Box = new Box(this, 20, 20, false, false);
            bgbox.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            bgbox.color = GameBackgroundColor.BG_POPUP;
            bgbox.normalAlpha = 0.5;
            bgbox.activeAlpha = 1;

            box = new Box(this, 20, 20, false, false);
            box.setSize(Main.GAME_WIDTH - 40, Main.GAME_HEIGHT - 40);
            box.activeAlpha = 0.4;

            var titleDisplay:Text = new Text(box, 10, 8, _lang.string("popup_queue_manager"), 20);
            titleDisplay.width = box.width - 10;

            menuMain = new BoxButton(box, box.width - 125 * 2 - 30, 8, 125, 25, _lang.string("options_queue_saved"), 12, clickHandler);
            menuMain.menu_select = TAB_MAIN;

            menuPregen = new BoxButton(box, box.width - menuMain.width - 15, 8, 125, 25, _lang.string("options_queue_premade"), 12, clickHandler);
            menuPregen.menu_select = TAB_PREGEN;

            //- content
            scrollpane = new ScrollPane(box, 10, 42, box.width - 45, 341, mouseWheelHandler);
            scrollpane.graphics.lineStyle(1, 0x64A4B8, 0.25, true);
            scrollpane.graphics.drawRect(0, 0, scrollpane.width - 1, scrollpane.height - 1);
            scrollbar = new ScrollBar(box, 10 + scrollpane.width, 42, 20, 341, null, null, scrollBarMoved);

            renderQueues();

            //- importBtn
            importBtn = new BoxButton(box, box.width - 180, box.height - 42, 79.5, 27, _lang.string("popup_queue_import"), 12, clickHandler);

            //- Close
            closeBtn = new BoxButton(box, box.width - 94.5, box.height - 42, 79.5, 27, _lang.string("menu_close"), 12, clickHandler);
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
            menuMain.dispose();
            menuPregen.dispose();
            importBtn.dispose();
            closeBtn.dispose();

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
                    var noSavedDisplay:Text = new Text(scrollpane.content, 10, 8, _lang.string("popup_queue_no_queues"));
                    noSavedDisplay.width = box.width - 10;
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
            scrollpane.scrollTo(scrollbar.scroll);
            scrollbar.draggerVisibility = (yOffset > scrollpane.height);
        }

        private function e_importSongQueue(songQueueJSON:String):void
        {
            var temp:SongQueueItem = SongQueueItem.fromString(songQueueJSON);
            if (temp.items.length > 0)
            {
                _gvars.playerUser.songQueues.push(temp);
                renderQueues();
            }
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == importBtn)
            {
                new Prompt(box.parent, 320, _lang.string("popup_queue_import_song_queue"), 100, "SUBMIT", e_importSongQueue);
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

                var _songInfo:SongInfo = _playlist.indexList[index];
                var _rank:Object = _gvars.activeUser.getLevelRank(_songInfo);
                var _access:int = _gvars.checkSongAccess(_songInfo);

                if (_access == GlobalVariables.SONG_ACCESS_PLAYABLE)
                {
                    var stats:int = GlobalVariables.getSongIconIndex(_songInfo, _rank);
                    if (!songlist[stats])
                    {
                        songlist[stats] = [];
                    }
                    songlist[stats].push(_songInfo.level);
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

import classes.Alert;
import classes.Language;
import classes.Playlist;
import classes.SongInfo;
import classes.SongQueueItem;
import classes.ui.Box;
import classes.ui.BoxButton;
import classes.ui.Prompt;
import classes.ui.Text;
import com.flashfla.utils.SystemUtil;
import com.flashfla.utils.TimeUtil;
import flash.display.Sprite;
import flash.events.MouseEvent;
import menu.MainMenu;
import menu.MenuSongSelection;
import popups.PopupQueueManager;

internal class QueueBox extends Sprite
{
    private var _gvars:GlobalVariables = GlobalVariables.instance;
    private var _lang:Language = Language.instance;
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
        box = new Box(this, 0, 0, false);
        box.setSize(690, (!longview ? 35 : queueItem.items.length * 20 + 30));

        // Add Song Names
        var totalTime:int = 0;
        for each (var songid:int in queueItem.items)
        {
            var songInfo:SongInfo = _playlist.playList[songid];
            if (songInfo)
            {
                if (longview)
                {
                    var access:int = _gvars.checkSongAccess(songInfo);
                    var songName:Text = new Text(box, 5, yOffset, " - " + songInfo.name + " [" + songInfo.time + "]", 12, access == GlobalVariables.SONG_ACCESS_PLAYABLE ? "#FFFFFF" : "#FF9797");
                    yOffset += 20;
                }
                totalTime += songInfo.time_secs;
            }
        }

        // Add Queue Names + Info
        var queueName:Text = new Text(box, 5, 5, queueItem.name + " [" + TimeUtil.convertToHHMMSS(totalTime) + "]", 14);

        if (!premade)
        {
            //- Copy Button
            copyBtn = new BoxButton(box, box.width - 75, 5, 70, 25, _lang.string("popup_queue_copy"));

            //- Delete Button
            deleteBtn = new BoxButton(box, copyBtn.x - 75, 5, 70, 25, _lang.string("popup_queue_delete"));

            //- Rename Button
            renameBtn = new BoxButton(box, deleteBtn.x - 75, 5, 70, 25, _lang.string("popup_queue_rename"));
        }

        //- PLAY Button
        playBtn = new BoxButton(box, (renameBtn ? renameBtn.x - 75 : box.width - 75), 5, 70, 25, _lang.string("popup_queue_play"));

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
        var queueString:String = this.queueItem.toString();
        var success:Boolean = SystemUtil.setClipboard(queueString);
        if (success)
        {
            Alert.add(_lang.string("clipboard_success"), 120, Alert.GREEN);
        }
        else
        {
            Alert.add(_lang.string("clipboard_failure"), 120, Alert.RED);
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
        var newSongQueue:Array = [];
        for each (var songid:int in queueItem.items)
        {
            var songInfo:SongInfo = _playlist.playList[songid];
            if (songInfo)
            {
                var access:int = _gvars.checkSongAccess(songInfo);
                if (access == GlobalVariables.SONG_ACCESS_PLAYABLE)
                {
                    newSongQueue.push(songInfo);
                }
            }
        }

        popup.removePopup();

        if (newSongQueue.length <= 0)
            return;

        _gvars.songQueue = newSongQueue;
        MenuSongSelection.options.queuePlaylist = newSongQueue;
        if (_gvars.gameMain.activePanel != null && _gvars.gameMain.activePanel is MainMenu)
        {
            var mmmenu:MainMenu = (_gvars.gameMain.activePanel as MainMenu);
            if (mmmenu.panel != null && (mmmenu.panel is MenuSongSelection))
            {
                var msmenu:MenuSongSelection = (mmmenu.panel as MenuSongSelection);
                msmenu.buildPlayList();
                msmenu.buildInfoBox();
            }
        }
    }

    private function e_renameQueue(queueName:String):void
    {
        queueItem.name = queueName;
        popup.renderQueues();
        _gvars.playerUser.save();
    }

    private function renameQueue():void
    {
        new Prompt(this.popup, 320, _lang.string("popup_queue_rename_no_caps"), 100, "RENAME", e_renameQueue);
    }

    public function dispose():void
    {
        //- Remove is already existed.
        if (box != null)
        {
            copyBtn.dispose();
            deleteBtn.dispose();
            playBtn.dispose();
            renameBtn.dispose();

            box.dispose();
            this.removeChild(box);
            box = null;
        }
    }
}
