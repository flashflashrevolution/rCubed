package popups.replays
{

    import classes.ui.BoxButton;
    import classes.ui.ProgressBar;
    import classes.ui.Text;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import classes.replay.Replay;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.utils.getTimer;
    import flash.filesystem.File;
    import classes.SongInfo;
    import arc.ArcGlobals;
    import com.flashfla.utils.SpriteUtil;
    import flash.display.Bitmap;
    import classes.Language;

    public class ReplayHistoryTabLocal extends ReplayHistoryTabBase
    {
        private static var INITIAL_LOAD:Boolean = false;
        private static var REPLAYS:Vector.<Replay>;
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;

        private var btn_refresh:BoxButton;

        private var uiLock:Sprite;
        private var uiLockBG:Bitmap;
        private var loadingIndex:Text;
        private var loadingProgress:ProgressBar;
        private var loadingCancelButton:BoxButton;
        private var cancelRequested:Boolean = false;

        public function ReplayHistoryTabLocal(replayWindow:ReplayHistoryWindow):void
        {
            super(replayWindow);

            // UI Lock
            uiLock = new Sprite();
            var lockUIText:Text = new Text(uiLock, 0, 200, _lang.string("replay_loading_external"), 24);
            lockUIText.setAreaParams(780, 30, "center");

            loadingIndex = new Text(uiLock, 0, 340, "", 20);
            loadingIndex.setAreaParams(780, 30, "center");

            loadingProgress = new ProgressBar(uiLock, (Main.GAME_WIDTH - 450) / 2, 380, 450);

            loadingCancelButton = new BoxButton(uiLock, 390 - 40, 440, 80, 30, _lang.string("menu_cancel"), 12, clickHandler);
        }

        override public function get name():String
        {
            return "local";
        }

        override public function openTab():void
        {
            // Add UI Elements
            if (!btn_refresh)
            {
                btn_refresh = new BoxButton(null, 5, Main.GAME_HEIGHT - 35, 162, 29, _lang.string("menu_refresh"), 12, refreshReplays);
            }
            parent.addChild(btn_refresh);

            // Initial Load
            if (!INITIAL_LOAD)
            {
                if (!_gvars.file_replay_cache.cacheFound)
                    refreshReplays();
                else
                    loadCachedReplays();

                INITIAL_LOAD = true;
            }
        }

        override public function closeTab():void
        {
            parent.removeChild(btn_refresh);
        }

        override public function setValues():void
        {
            var render_list:Array = [];
            for each (var r:Replay in REPLAYS)
            {
                if (r.song == null)
                    continue;

                if (parent.searchText.length >= 1 && r.song.name.toLowerCase().indexOf(parent.searchText) == -1)
                    continue;

                render_list[render_list.length] = r;
            }
            parent.pane.setRenderList(render_list);
            parent.updateScrollPane();
        }

        private function loadCachedReplays():void
        {
            Logger.info(this, "Loading Cached Replays");
            REPLAYS = new <Replay>[];

            var idx:int = 0;
            var cache:Object = _gvars.file_replay_cache.cache;
            var TIME:Number = new Date().getTime();

            var r:Replay;
            var cacheObj:Object;

            for (var key:String in cache)
            {
                cacheObj = cache[key];

                r = new Replay(TIME + idx);
                r.filePath = key;

                r.song = new SongInfo();
                r.song.name = cacheObj["name"];

                r.score = cacheObj["score"];
                r.perfect = cacheObj["judge"][0];
                r.good = cacheObj["judge"][1];
                r.average = cacheObj["judge"][2];
                r.miss = cacheObj["judge"][3];
                r.boo = cacheObj["judge"][4];
                r.maxcombo = cacheObj["judge"][5];

                r.settings = {'songRate': cacheObj["rate"]};
                if (cacheObj["engine"] != null)
                {
                    var engine:Object = _avars.legacyEngine(cacheObj["engine"]);
                    if (!engine)
                        engine = {id: cacheObj["engine"]};

                    r.settings.arc_engine = {engineID: cacheObj["engine"]};

                    r.song.engine = engine;
                }

                REPLAYS[REPLAYS.length] = r;
            }

            setValues();
        }

        private function refreshReplays(e:MouseEvent = null):void
        {
            Logger.info(this, "Reloading External Replays");
            lockUI = true;

            _gvars.file_replay_cache.clear();
            REPLAYS = new <Replay>[];

            var loadTimer:Timer;
            var TIME:Number = new Date().getTime();

            // File Searching
            var dirQueue:Vector.<FileDirectoryQueue> = new <FileDirectoryQueue>[new FileDirectoryQueue(AirContext.getAppFile("replays"), 0)];
            var fileQueue:Vector.<File> = new <File>[];
            var activeDirQueue:FileDirectoryQueue;
            var maxDepth:int = 2;

            e_startFileSearch();

            function e_startFileSearch():void
            {
                loadingIndex.text = '';
                loadingProgress.update(0);

                loadTimer = new Timer(20, 1);
                loadTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_searchTimer);
                loadTimer.start();
            }

            function e_searchTimer(e:TimerEvent):void
            {
                var startTimer:Number = getTimer();
                var isDelay:Boolean = false;

                // File Loop
                var found:Array;
                var len:int;
                var file:File;
                var i:int;

                while (dirQueue.length > 0)
                {
                    activeDirQueue = dirQueue.pop();

                    found = activeDirQueue.dir.getDirectoryListing();
                    len = found.length;

                    for (i = 0; i < len; i++)
                    {
                        file = found[i];

                        if (file.isHidden || !file.exists)
                        {
                            continue;
                        }
                        else if (file.isDirectory)
                        {
                            if (activeDirQueue.level < maxDepth)
                            {
                                dirQueue.push(new FileDirectoryQueue(file, activeDirQueue.level + 1));
                            }
                        }
                        else
                        {
                            if (file.extension != null && file.extension.toLowerCase() == "txt")
                            {
                                fileQueue.push(file);
                            }
                        }
                    }

                    var endTimer:Number = getTimer();
                    if (endTimer - startTimer > 250)
                    {
                        isDelay = true;
                        break;
                    }
                }

                if (cancelRequested)
                {
                    dirQueue.length = 0;
                    fileQueue.length = 0;
                }

                loadingIndex.text = "#" + fileQueue.length;

                // Loaded All Files
                if (dirQueue.length == 0)
                {
                    loadTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_searchTimer);
                    e_startFileQueue();
                    return;
                }

                // Not Finished, Continue next frame.
                if (isDelay && dirQueue.length > 0)
                {
                    loadTimer.start();
                }
            }

            // File Loading
            var pathIndex:int;
            var pathTotal:int;

            function e_startFileQueue():void
            {
                if (fileQueue.length <= 0)
                {
                    lockUI = false;
                    setValues();
                    return;
                }

                pathIndex = 0;
                pathTotal = fileQueue.length;

                loadingIndex.text = pathIndex + " / " + pathTotal;
                loadingProgress.update(0);

                loadTimer = new Timer(20, 1);
                loadTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_parseTimer);
                loadTimer.start();
            }

            function e_parseTimer(e:TimerEvent):void
            {
                var r:Replay;
                var chartFile:File;
                var stringPath:String;
                var startTimer:Number = getTimer();
                var isDelay:Boolean = false;
                var cacheObj:Object;

                while (pathIndex < pathTotal)
                {
                    chartFile = fileQueue[pathIndex];
                    stringPath = chartFile.nativePath;

                    loadingIndex.text = pathIndex + " / " + pathTotal;

                    r = new Replay(TIME + pathIndex);

                    // Read File
                    var txt:String = AirContext.readFile(chartFile).toString();
                    r.parseEncode(txt, false);
                    r.fileReplay = true;
                    if (r.isValid())
                    {
                        r.loadSongInfo();
                        REPLAYS[REPLAYS.length] = r;

                        cacheObj = {'name': r.song.name,
                                'rate': r.settings.songRate,
                                'score': r.score,
                                'judge': [r.perfect, r.good, r.average, r.miss, r.boo, r.maxcombo]}

                        if (r.settings.arc_engine != null)
                            cacheObj["engine"] = r.song.engine.id;

                        _gvars.file_replay_cache.setValue(chartFile.parent.name + "/" + chartFile.name, cacheObj);
                    }

                    pathIndex++;

                    if (cancelRequested)
                    {
                        pathIndex = 0;
                        pathTotal = 0;
                        fileQueue.length = 0;
                        REPLAYS.length = 0;
                    }

                    var endTimer:Number = getTimer();
                    if (endTimer - startTimer > 250)
                    {
                        loadingProgress.update(pathIndex / pathTotal);
                        isDelay = true;
                        break;
                    }
                }

                // Loaded All Files
                if (pathIndex >= pathTotal)
                {
                    loadTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_parseTimer);
                    _gvars.file_replay_cache.save();
                    lockUI = false;

                    setValues();
                    return;
                }

                // Not Finished, Continue next frame.
                if (isDelay && pathIndex < pathTotal)
                {
                    loadTimer.start();
                }
            }
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (e.target == loadingCancelButton)
            {
                cancelRequested = true;
            }
        }

        public function set lockUI(val:Boolean):void
        {
            cancelRequested = false;
            if (val)
            {
                uiLockBG = SpriteUtil.getBitmapSprite(_gvars.gameMain.stage, 0.3);
                uiLock.addChildAt(uiLockBG, 0);
                parent.addChild(uiLock);
            }
            else
            {
                if (parent.contains(uiLock))
                {
                    uiLock.removeChildAt(0);
                    uiLockBG = null;
                    parent.removeChild(uiLock);
                }
            }
        }

        override public function prepareReplay(r:Replay):Replay
        {
            // Incomplete 
            if (r.filePath != null)
            {
                Logger.debug(this, "Loading Local replay: " + "replays/" + r.filePath);
                var txt:String = AirContext.readFile(AirContext.getAppFile("replays/" + r.filePath)).toString();

                if (txt != null && txt.length > 0)
                {
                    r.parseEncode(txt, false);
                    r.fileReplay = true;
                    if (r.isValid())
                    {
                        r.loadSongInfo();
                        return r;
                    }
                }

                return null;
            }

            return r;
        }
    }
}

import flash.filesystem.File;

internal class FileDirectoryQueue
{
    public var dir:File;
    public var level:int;

    public function FileDirectoryQueue(dir:File, level:int)
    {
        this.dir = dir;
        this.level = level;
    }
}
