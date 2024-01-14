package popups
{
    import assets.menu.icons.fa.iconClose;
    import assets.menu.icons.fa.iconFolder;
    import assets.menu.icons.fa.iconUpLevel;
    import classes.Alert;
    import classes.Language;
    import classes.chart.parse.ExternalChartBase;
    import classes.mp.Multiplayer;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.BoxText;
    import classes.ui.Text;
    import com.flashfla.utils.sprintf;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.filesystem.File;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import flash.text.TextFormat;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import menu.FileLoader;
    import menu.MainMenu;
    import menu.MenuPanel;
    import popups.filebrowser.FileBrowserDifficultyItem;
    import popups.filebrowser.FileBrowserFilter;
    import popups.filebrowser.FileBrowserItem;
    import popups.filebrowser.FileBrowserList;
    import popups.filebrowser.FileFolder;
    import popups.filebrowser.FileFolderItem;

    public class PopupFileBrowser extends MenuPanel
    {
        private static const _gvars:GlobalVariables = GlobalVariables.instance;
        private static const _lang:Language = Language.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;

        public var lc:LoaderContext = new LoaderContext();

        public static var rootFolder:File;
        public static var lastSelectedIndex:int = 0;
        public static var listFilter:FileBrowserFilter = new FileBrowserFilter();

        public static var pathList:Vector.<String>;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;
        private var dividers:Sprite;

        private var upFolder:BoxIcon;
        private var displayFolderPath:Text;
        private var selectFolder:BoxIcon;
        private var closeWindow:BoxIcon;

        private var searchInput:BoxText;
        private var searchPlaceholder:Text;

        private var lastSelectedItem:FileBrowserItem;
        private var songBrowser:FileBrowserList;
        private var songDetails:Sprite;
        private var songDetailsWidth:Number = 0;
        private var songDifficulties:Array = [];

        private var _isLocked:Boolean = false;
        private var uiLock:Sprite;
        private var loadingPathIndex:Text;
        private var loadingPathFolder:Text;
        private var loadingPathSong:Text;
        private var loadingCancelButton:BoxButton;
        private var cancelRequested:Boolean = false;

        public function PopupFileBrowser(myParent:MenuPanel)
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

            var bgbox:Box = new Box(this, -1, -1, false, false);
            bgbox.setSize(Main.GAME_WIDTH + 2, Main.GAME_HEIGHT + 2);
            bgbox.color = 0x000000;
            bgbox.normalAlpha = 0.7;
            bgbox.activeAlpha = 1;

            box = new Box(this, -1, -1, false, false);
            box.setSize(Main.GAME_WIDTH + 2, Main.GAME_HEIGHT + 2);
            box.activeAlpha = 0.5;

            dividers = new Sprite();
            dividers.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            box.addChild(dividers);

            // Top Bar Item
            closeWindow = new BoxIcon(box, box.width - 32, 6, 27, 27, new iconClose(), clickHandler);
            selectFolder = new BoxIcon(box, closeWindow.x - 32, 6, 27, 27, new iconFolder(), clickHandler);

            displayFolderPath = new Text(box, 40, 6, _lang.string("file_loader_no_folder_selected"));
            displayFolderPath.setAreaParams(selectFolder.x - displayFolderPath.x - 5, 27);
            displayFolderPath.mouseEnabled = true;
            displayFolderPath.useHandCursor = true;
            displayFolderPath.buttonMode = true;
            displayFolderPath.addEventListener(MouseEvent.CLICK, clickHandler);

            dividers.graphics.beginFill(0x000000, 0.2);
            dividers.graphics.drawRect(displayFolderPath.x - 2, displayFolderPath.y, displayFolderPath.width + 2, displayFolderPath.height);
            dividers.graphics.endFill();

            upFolder = new BoxIcon(box, 6, 6, 27, 27, new iconUpLevel(), clickHandler);

            // Song List
            songBrowser = new FileBrowserList(box, 6, 39, listFilter);
            songBrowser.addEventListener(MouseEvent.CLICK, e_songListClick);
            songBrowser.activeIndex = lastSelectedIndex;

            songDetails = new Sprite();
            songDetails.x = 511;
            songDetails.y = 39;
            songDetailsWidth = box.width - 37 - songDetails.x;
            box.addChild(songDetails);

            // Search
            searchPlaceholder = new Text(box, 13, box.height - 29, _lang.string("file_loader_search"));
            searchPlaceholder.alpha = 0.4;
            searchPlaceholder.visible = listFilter.term.length == 0;
            searchInput = new BoxText(box, 11, box.height - 32, 490, 25, new TextFormat(Constant.TEXT_FORMAT_UNICODE.font, 12, 0xFFFFFF));
            searchInput.text = listFilter.term;
            searchInput.addEventListener(Event.CHANGE, e_searchChange);

            dividers.graphics.beginFill(0x000000, 0.2);
            dividers.graphics.drawRect(songDetails.x, songDetails.y, songDetailsWidth, box.height - 44);
            dividers.graphics.endFill();

            dividers.graphics.beginFill(0x000000, 0.2);
            dividers.graphics.drawRect(box.width - 32, 39, closeWindow.width, box.height - 44);
            dividers.graphics.endFill();

            dividers.graphics.beginFill(0x000000, 0.2);
            dividers.graphics.drawRect(6, box.height - 37, 500, 45);
            dividers.graphics.endFill();

            // UI Lock
            uiLock = new Sprite();
            uiLock.graphics.lineStyle(0, 0, 0);
            uiLock.graphics.beginFill(0x000000, 0.7);
            uiLock.graphics.drawRect(0, 0, 780, 480);
            uiLock.graphics.endFill();

            var lockUIText:Text = new Text(uiLock, 0, 200, _lang.string("file_loader_loading_files"), 24);
            lockUIText.setAreaParams(780, 30, "center");

            loadingPathIndex = new Text(uiLock, 0, 340, "", 20);
            loadingPathIndex.setAreaParams(780, 30, "center");
            loadingPathFolder = new Text(uiLock, 0, 371, "", 22);
            loadingPathFolder.setAreaParams(780, 30, "center");
            loadingPathSong = new Text(uiLock, 0, 400, "", 18);
            loadingPathSong.setAreaParams(780, 30, "center");

            loadingCancelButton = new BoxButton(uiLock, 390 - 40, 440, 80, 30, _lang.string("menu_cancel"), 12, clickHandler);

            if (rootFolder != null && pathList == null)
                refreshFolder();
            else if (rootFolder != null && pathList != null)
            {
                displayFolderPath.text = rootFolder.nativePath;
                buildFileList();
            }
        }

        override public function stageRemove():void
        {
            closeWindow.dispose();
            box.dispose();
            this.removeChild(box);
            this.removeChild(bmp);
            bmd = null;
            bmp = null;
            box = null;
        }

        public function buildFileList():void
        {
            var renderList:Array = [];
            var cacheValue:Object;

            // List Building
            var path:String;
            var endOfFolder:Number;
            var arLen:Number = pathList.length;
            for (var i:int = 0; i < arLen; i++)
            {
                cacheValue = FileLoader.cache.getValue(pathList[i]);
                path = pathList[i];
                endOfFolder = path.lastIndexOf(File.separator) + 1;
                renderList[i] = new FileFolder(path.substr(0, endOfFolder), path.substr(endOfFolder), cacheValue["ext"], new FileFolderItem(pathList[i], cacheValue));
            }

            // Folder Merging
            var elm1:FileFolder;
            var elm2:FileFolder;
            var n:int;
            renderList.sortOn(["folder", "ext"], [Array.CASEINSENSITIVE, Array.CASEINSENSITIVE]);
            for (i = 0; i < arLen - 1; i++)
            {
                elm1 = renderList[i];
                for (n = i + 1; n < arLen; n++)
                {
                    elm2 = renderList[n];
                    if (elm1.folder == elm2.folder && elm1.ext == elm2.ext)
                    {
                        while (elm2.data.length > 0)
                            elm1.data.push(elm2.data.pop());

                        renderList.removeAt(n);
                        n--;
                        arLen--;
                    }
                    else
                        break;
                }
            }

            // Sorting
            for (i = 0; i < arLen; i++)
            {
                elm1 = renderList[i];
                elm1.author = elm1.data[0].info.author;
                elm1.name = elm1.data[0].info.name;
                elm1.banner = elm1.data[0].info.banner;
            }
            renderList.sortOn(["name", "author"], [Array.CASEINSENSITIVE, Array.CASEINSENSITIVE]);

            // Display
            songBrowser.setRenderList(renderList);

            // Set Active Item
            if (renderList.length > 0)
                selectedItem(songBrowser.findSongButtonByIndex(lastSelectedIndex));
        }

        private function dirSelected(e:Event):void
        {
            if (stage)
                stage.focus = null;
            rootFolder = e.target as File;
            refreshFolder();
        }

        private function clickHandler(e:MouseEvent):void
        {
            if (stage)
                stage.focus = null;
            if (e.target == upFolder)
            {
                if (rootFolder != null)
                {
                    rootFolder = rootFolder.parent;
                    refreshFolder();
                }
            }
            if (e.target == selectFolder || e.target == displayFolderPath)
            {
                var tempFolder:File = new File();
                tempFolder.addEventListener(Event.SELECT, dirSelected);
                tempFolder.browseForDirectory(_lang.stringSimple("file_loader_select_a_directory"));
            }
            if (e.target == loadingCancelButton)
            {
                cancelRequested = true;
            }
            //- Close
            if (e.target == closeWindow)
            {
                removePopup();
                return;
            }
        }

        private function refreshFolder():void
        {
            if (rootFolder == null)
                return;

            lastSelectedIndex = 0;
            lastSelectedItem = null;

            pathList = new <String>[];

            displayFolderPath.text = rootFolder.nativePath;

            lockUI = true;

            var loadTimer:Timer;

            // File Searching
            var dirQueue:Vector.<FileDirectoryQueue> = new <FileDirectoryQueue>[new FileDirectoryQueue(rootFolder, 0)];
            var fileQueue:Vector.<File> = new <File>[];
            var activeDirQueue:FileDirectoryQueue;
            var maxDepth:int = 2;
            var validExt:Array = ExternalChartBase.VALID_CHART_EXTENSIONS;

            e_startFileSearch();

            function e_startFileSearch():void
            {
                loadingPathIndex.text = _lang.string("file_loader_scanning");
                loadingPathFolder.text = '';
                loadingPathSong.text = '';

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
                                dirQueue.push(new FileDirectoryQueue(file, activeDirQueue.level + 1));
                        }
                        else
                        {
                            if (file.extension != null && validExt.indexOf(file.extension.toLowerCase()) != -1)
                                fileQueue.push(file);
                        }
                    }

                    var endTimer:Number = getTimer();
                    if (endTimer - startTimer > 200)
                    {
                        isDelay = true;
                        break;
                    }
                }

                if (cancelRequested)
                {
                    dirQueue.length = 0;
                    fileQueue.length = 0;
                    pathList.length = 0;
                }

                loadingPathIndex.text = sprintf(_lang.string("file_loader_found_files"), {files: fileQueue.length});

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
                    buildFileList();
                    return;
                }

                pathIndex = 0;
                pathTotal = fileQueue.length;

                loadingPathIndex.text = pathIndex + " / " + pathTotal;
                loadingPathFolder.text = '';
                loadingPathSong.text = '';

                loadTimer = new Timer(20, 1);
                loadTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_parseTimer);
                loadTimer.start();
            }

            function e_parseTimer(e:TimerEvent):void
            {
                var emb:ExternalChartBase;
                var chartFile:File;
                var stringPath:String;
                var startTimer:Number = getTimer();
                var isDelay:Boolean = false;
                var cacheObj:Object;

                while (pathIndex < pathTotal)
                {
                    chartFile = fileQueue[pathIndex];
                    stringPath = chartFile.nativePath;
                    if ((cacheObj = FileLoader.cache.getValue(stringPath)) != null)
                    {
                        if (cacheObj.valid == 1)
                            pathList.push(stringPath);
                    }
                    else
                    {
                        loadingPathIndex.text = pathIndex + " / " + pathTotal;

                        if (chartFile.parent.parent.nativePath == rootFolder.nativePath)
                        {
                            loadingPathFolder.text = chartFile.parent.name;
                            loadingPathSong.text = '';
                        }
                        else
                        {
                            loadingPathFolder.text = chartFile.parent.parent.name;
                            loadingPathSong.text = chartFile.parent.name;
                        }

                        cacheObj = {"valid": 0}
                        emb = new ExternalChartBase();
                        if (emb.load(chartFile, true))
                        {
                            var chartData:Object = emb.getInfo();
                            var chartCharts:Array = emb.getAllCharts();

                            cacheObj = {"valid": 1,
                                    "name": chartData['name'],
                                    "author": chartData['author'],
                                    "stepauthor": chartData['stepauthor'],
                                    "difficulty": chartData['difficulty'],
                                    "music": chartData['music'],
                                    "banner": chartData['banner'],
                                    "background": chartData['background'],
                                    "ext": chartData['ext'],
                                    "chart": [],
                                    "id": emb.ID}

                            for (var i:int = 0; i < chartCharts.length; i++)
                            {
                                var difficultyData:Object = chartCharts[i];
                                cacheObj['chart'][i] = {"class": difficultyData['class'],
                                        "class_color": difficultyData['class_color'],
                                        "desc": difficultyData['desc'],
                                        "difficulty": difficultyData['difficulty'],
                                        "type": difficultyData['type'],
                                        "time_sec": Number(difficultyData['time_sec'].toFixed(2)),
                                        "nps": Number(difficultyData['nps'].toFixed(2)),
                                        "arrows": difficultyData['arrows'],
                                        "holds": difficultyData['holds'],
                                        "mines": difficultyData['mines']};
                            }
                        }

                        FileLoader.cache.setValue(stringPath, cacheObj);

                        if (cacheObj.valid == 1)
                            pathList.push(stringPath);
                    }
                    pathIndex++;

                    if (cancelRequested)
                    {
                        pathIndex = 0;
                        pathTotal = 0;
                        dirQueue.length = 0;
                        fileQueue.length = 0;
                        pathList.length = 0;
                    }

                    var endTimer:Number = getTimer();
                    if (endTimer - startTimer > 200)
                    {
                        isDelay = true;
                        break;
                    }
                }

                // Loaded All Files
                if (pathIndex >= pathTotal)
                {
                    loadTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_parseTimer);
                    FileLoader.cache.save();
                    lockUI = false;

                    buildFileList();
                    return;
                }

                // Not Finished, Continue next frame.
                if (isDelay && pathIndex < pathTotal)
                {
                    loadTimer.start();
                }
            }
        }

        private function selectedItem(item:FileBrowserItem):void
        {
            if (item == null)
                return;

            if (lastSelectedItem != null)
                lastSelectedItem.highlight = false;

            item.highlight = true;
            setInfoBox(item.songData);
            lastSelectedIndex = item.index;
            lastSelectedItem = item;
            songBrowser.activeIndex = item.index;
        }

        private function e_searchChange(e:Event):void
        {
            if (_isLocked)
                return;

            listFilter.term = searchInput.text;
            searchPlaceholder.visible = searchInput.text.length == 0;
            songBrowser.updateList();
            selectedItem(songBrowser.findSongButtonByIndex(lastSelectedIndex));
        }

        private function e_songListClick(e:MouseEvent):void
        {
            if (e.target is FileBrowserItem)
            {
                selectedItem(e.target as FileBrowserItem);
            }
        }

        public function setInfoBox(info:FileFolder):void
        {
            songDetails.removeChildren();
            songDifficulties.length = 0;

            var infoTitle:Text;
            var infoDetails:Text;
            var tY:int = 83;

            // Create Holder Sprite
            var sr:Sprite = drawInfoBannerSprite(0, 0.3);
            sr.x = 10;
            sr.y = 10;
            songDetails.addChild(sr);

            // Mask
            var srm:Sprite = drawInfoBannerSprite(0, 1);
            sr.addChild(srm);
            sr.mask = srm;

            // Border
            var srb:Sprite = drawInfoBannerSprite(0.35, 0);
            srb.x = 10;
            srb.y = 10;
            songDetails.addChild(srb);

            // Banner
            if (info.banner != "")
            {
                // Check Extension
                var bannerExt:String = info.banner.substr(info.banner.lastIndexOf(".") + 1).toLowerCase();
                if (bannerExt == "jpg" || bannerExt == "png" || bannerExt == "gif" || bannerExt == "jpeg")
                {
                    var path:String = "file:///" + info.folder + info.banner;
                    var imageLoader:Loader = new Loader();
                    imageLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_bannerLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, e_bannerLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_bannerLoaded);
                    imageLoader.load(new URLRequest(path), lc);

                    function e_bannerLoaded(e:Event):void
                    {
                        // Position Loaded Banner Image
                        if (e.type == Event.COMPLETE && e.target != null && ((e.target as LoaderInfo).content) != null)
                        {
                            var bmp:Bitmap = ((e.target as LoaderInfo).content) as Bitmap;
                            bmp.smoothing = true;
                            bmp.pixelSnapping = "always";
                            sr.addChildAt(bmp, 1);

                            var imageScale:Number = 214 / bmp.width;

                            bmp.scaleX = bmp.scaleY = imageScale;

                            if (bmp.height < 70)
                            {
                                bmp.scaleX = bmp.scaleY = 1;
                                imageScale = 70 / bmp.height;
                                bmp.scaleX = bmp.scaleY = imageScale;
                                bmp.x = -((bmp.width - 214) / 2);
                            }
                            else
                                bmp.y = -((bmp.height - 70) / 2);
                        }
                    }
                }
            }

            // Reload File
            var reloadCache:BoxButton = new BoxButton(songDetails, 209, 3, 22, 22, "R", 12, e_reloadCache);

            // Print Song Info
            var infoDisplay:Array = [[info['data'][0]['info']['name'], 14], [info['data'][0]['info']['author'], 12]];
            for (var item:String in infoDisplay)
            {
                // Info Display
                infoDetails = new Text(songDetails, 5, tY, infoDisplay[item][0], infoDisplay[item][1]);
                infoDetails.setAreaParams(songDetailsWidth - 10, 23, "center");
                tY += 23;
            }

            // Build UI
            var sources:Vector.<FileFolderItem> = info.data;
            for (var s:int = 0; s < sources.length; s++)
            {
                var charts:Array = sources[s].info.chart;
                for (var i:int = 0; i < charts.length; i++)
                {
                    var chartSelectButton:FileBrowserDifficultyItem = new FileBrowserDifficultyItem(i, sources[s]);
                    chartSelectButton.addEventListener(MouseEvent.CLICK, e_difficultySelect, false, 0, true);
                    songDetails.addChild(chartSelectButton);
                    songDifficulties.push(chartSelectButton);
                }
            }

            songDifficulties.sortOn("sorting_key", Array.NUMERIC);

            // Place UI
            tY = 0;
            for (i = songDifficulties.length - 1; i >= 0; i--)
            {
                songDifficulties[i].x = 9;
                songDifficulties[i].y = 405 - tY;
                tY += 30;
            }
        }

        public function drawInfoBannerSprite(border:Number, bg:Number):Sprite
        {
            var srm:Sprite = new Sprite();
            srm.graphics.lineStyle(2, 0xffffff, border, true);
            srm.graphics.beginFill(0, bg);
            srm.graphics.drawRoundRect(0, 0, 215, 70, 25, 25);
            srm.graphics.endFill();
            return srm;
        }

        private function e_difficultySelect(e:MouseEvent):void
        {
            var tar:FileBrowserDifficultyItem = e.target as FileBrowserDifficultyItem;
            var info:FileFolderItem = tar.cache_info;
            var id:int = tar.chart_id;

            Flags.VALUES[Flags.FILE_LOADER_OPEN] = true;

            removePopup();

            FileLoader.loadLocalFile(info.loc, id);
        }

        private function e_reloadCache(e:Event):void
        {
            var chartFile:File;
            var emb:ExternalChartBase;
            var cacheObj:Object;

            var file:FileFolder = lastSelectedItem.songData;
            var fileList:Vector.<FileFolderItem> = file.data;
            for each (var chartItem:FileFolderItem in fileList)
            {
                chartFile = new File(chartItem.loc);
                cacheObj = {"valid": 0};
                emb = new ExternalChartBase();
                if (emb.load(chartFile, true))
                {
                    var chartData:Object = emb.getInfo();
                    var chartCharts:Array = emb.getAllCharts();

                    cacheObj = {"valid": 1,
                            "name": chartData['name'],
                            "author": chartData['author'],
                            "stepauthor": chartData['stepauthor'],
                            "difficulty": chartData['difficulty'],
                            "music": chartData['music'],
                            "banner": chartData['banner'],
                            "background": chartData['background'],
                            "ext": chartData['ext'],
                            "chart": [],
                            "id": emb.ID}

                    for (var i:int = 0; i < chartCharts.length; i++)
                    {
                        var difficultyData:Object = chartCharts[i];
                        cacheObj['chart'][i] = {"class": difficultyData['class'],
                                "class_color": difficultyData['class_color'],
                                "desc": difficultyData['desc'],
                                "difficulty": difficultyData['difficulty'],
                                "type": difficultyData['type'],
                                "time_sec": Number(difficultyData['time_sec'].toFixed(2)),
                                "nps": Number(difficultyData['nps'].toFixed(2)),
                                "arrows": difficultyData['arrows'],
                                "holds": difficultyData['holds'],
                                "mines": difficultyData['mines']};
                    }
                }

                FileLoader.cache.setValue(chartItem.loc, cacheObj);
            }
            FileLoader.cache.save();
            Alert.add(_lang.string("file_loader_reloaded_file"));
            buildFileList();
        }

        public function set lockUI(val:Boolean):void
        {
            _isLocked = val;
            cancelRequested = false;
            if (val)
            {
                this.addChild(uiLock);
            }
            else
            {
                if (this.contains(uiLock))
                {
                    this.removeChild(uiLock);
                }
            }
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
