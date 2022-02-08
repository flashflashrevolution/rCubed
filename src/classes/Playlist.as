package classes
{
    import arc.ArcGlobals;
    import classes.chart.parse.ChartFFRLegacy;
    import classes.SiteUrl;
    import com.flashfla.utils.ArrayUtil;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import menu.MainMenu;
    import menu.MenuSongSelection;

    public class Playlist extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:Playlist = null;
        private static var _instanceCanon:Playlist = null;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;
        private var _loader:URLLoader;
        private var _isLoaded:Boolean = false;
        private var _isLoading:Boolean = false;
        private var _loadError:Boolean = false;

        ///- Public Locals
        public var generatedQueues:Array;
        public var genreList:Array;
        public var playList:Array;
        public var indexList:Vector.<SongInfo>;
        public var engine:Object;

        ///- Constructor
        public function Playlist()
        {

        }

        public static function clearCanon():void
        {
            _instanceCanon = null;
        }

        public static function get instanceCanon():Playlist
        {
            return _instanceCanon;
        }

        public static function get instance():Playlist
        {
            if (_instance == null)
                _instance = new Playlist();
            return _instance;
        }

        public function isLoaded():Boolean
        {
            return _isLoaded && !_loadError;
        }

        public function isError():Boolean
        {
            return _loadError;
        }

        ///- Playlist Loading
        public function load():void
        {
            // Kill old Loading Stream
            if (_loader && _isLoading)
            {
                removeLoaderListeners();
                _loader.close();
            }

            // Load New
            var time:Number = new Date().getTime();
            _isLoaded = false;
            _loadError = false;
            _loader = new URLLoader();
            addLoaderListeners();

            if (ArcGlobals.instance.configLegacy)
            {
                var url:String = ArcGlobals.instance.configLegacy.playlistURL;
                engine = ArcGlobals.instance.configLegacy;
                _loader.load(new URLRequest(url + (url.indexOf("?") == -1 ? "?d=" + time : "&d=" + time)));
                _isLoading = true;
            }
            else if (_instanceCanon != null)
            {
                engine = null;
                this._isLoaded = _instanceCanon._isLoaded;
                this._loadError = _instanceCanon._loadError;
                genreList = _instanceCanon.genreList;
                playList = _instanceCanon.playList;
                indexList = _instanceCanon.indexList;
                generatedQueues = _instanceCanon.generatedQueues;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
            }
            else
            {
                engine = null;
                var req:URLRequest = new URLRequest(SiteUrl.SITE_PLAYLIST_URL + "?d=" + time);
                var requestVars:URLVariables = new URLVariables();
                Constant.addDefaultRequestVariables(requestVars);
                requestVars.session = _gvars.userSession;
                req.data = requestVars;
                req.method = URLRequestMethod.POST;
                _loader.load(req);
                _isLoading = true;
            }
        }

        private function playlistLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            var data:Object;
            var legacy:Boolean = ArcGlobals.instance.configLegacy;
            try
            {
                if (legacy)
                    data = ChartFFRLegacy.parsePlaylist(e.target.data);
                else
                {
                    data = JSON.parse(e.target.data);
                    _gvars.TOTAL_PUBLIC_SONGS = 0;
                }
            }
            catch (e:Error)
            {
                _loadError = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
                return;
            }
            generatedQueues = [];
            genreList = [];
            playList = [];
            indexList = new <SongInfo>[];

            if (_instanceCanon == null && !legacy)
            {
                _instanceCanon = new Playlist();
                _instanceCanon._isLoaded = true;
                _instanceCanon.genreList = genreList;
                _instanceCanon.playList = playList;
                _instanceCanon.indexList = indexList;
                _instanceCanon.generatedQueues = generatedQueues;
            }

            for each (var dynamicSongInfo:Object in data)
            {
                var songInfo:SongInfo;

                if (dynamicSongInfo is SongInfo)
                {
                    songInfo = dynamicSongInfo as SongInfo;

                    if (genreList[songInfo.genre] == undefined)
                    {
                        genreList[songInfo.genre] = [];
                        generatedQueues[songInfo.genre] = [];
                    }
                }
                else
                {
                    var genre:int = dynamicSongInfo.genre;
                    if (genreList[genre] == undefined)
                    {
                        genreList[genre] = [];
                        generatedQueues[genre] = [];
                    }

                    // Important to note that the dynamic fields aren't all exactly the same name
                    var newSongInfo:SongInfo = new SongInfo();
                    newSongInfo.author = dynamicSongInfo.author;
                    newSongInfo.author_url = dynamicSongInfo.authorURL;
                    newSongInfo.credits = dynamicSongInfo.credits;
                    newSongInfo.difficulty = dynamicSongInfo.difficulty;
                    newSongInfo.genre = dynamicSongInfo.genre;
                    newSongInfo.level = dynamicSongInfo.level;
                    newSongInfo.min_nps = dynamicSongInfo.min_nps;
                    newSongInfo.max_nps = dynamicSongInfo.max_nps;
                    newSongInfo.name = dynamicSongInfo.name;
                    newSongInfo.note_count = dynamicSongInfo.arrows;
                    newSongInfo.order = dynamicSongInfo.order;
                    newSongInfo.play_hash = dynamicSongInfo.playhash;
                    newSongInfo.prerelease = dynamicSongInfo.prerelease;
                    newSongInfo.preview_hash = dynamicSongInfo.previewhash;
                    newSongInfo.price = dynamicSongInfo.price;
                    newSongInfo.release_date = dynamicSongInfo.releasedate;
                    newSongInfo.song_rating = dynamicSongInfo.song_rating;
                    newSongInfo.stepauthor = dynamicSongInfo.stepauthor;
                    newSongInfo.stepauthor_url = dynamicSongInfo.stepauthorURL;
                    newSongInfo.style = dynamicSongInfo.style;
                    newSongInfo.time = dynamicSongInfo.time;

                    songInfo = newSongInfo;
                }

                // Song Time
                if (songInfo.time == null)
                    songInfo.time = "0:00";

                // Note Count
                if (isNaN(Number(songInfo.note_count)))
                    songInfo.note_count = 0;

                // Extra Info
                songInfo.index = genreList[songInfo.genre].length;
                songInfo.time_secs = (Number(songInfo.time.split(":")[0]) * 60) + Number(songInfo.time.split(":")[1]);

                // Author with URL
                if (songInfo.author_url != null && songInfo.author_url.length > 7)
                    songInfo.author_html = "<a href=\"" + songInfo.author_url + "\">" + songInfo.author + "</a>";
                else
                    songInfo.author_html = songInfo.author;

                // Multiple Step Authors
                if (songInfo.stepauthor != null && songInfo.stepauthor.indexOf(" & ") !== false)
                {
                    var stepAuthors:Array = songInfo.stepauthor.split(" & ");
                    songInfo.stepauthor_html = "<a href=\"" + SiteUrl.prefix + "profile/" + escape(stepAuthors[0]) + "\">" + stepAuthors[0] + "</a>";

                    for (var i:int = 1; i < stepAuthors.length; i++)
                        songInfo.stepauthor_html += " & <a href=\"" + SiteUrl.prefix + "profile/" + escape(stepAuthors[i]) + "\">" + stepAuthors[i] + "</a>";
                }
                else
                    songInfo.stepauthor_html = "<a href=\"" + SiteUrl.prefix + "profile/" + escape(songInfo.stepauthor) + "\">" + songInfo.stepauthor + "</a>";

                // Song Price
                if (isNaN(Number(songInfo.price)))
                    songInfo.price = -1;

                // Secret Credits
                if (isNaN(Number(songInfo.credits)))
                    songInfo.credits = -1;

                // Max Score Totals
                songInfo.score_total = songInfo.note_count * 1550;
                songInfo.score_raw = songInfo.note_count * 50;

                // Legacy Sync
                if (!legacy && isNaN(songInfo.sync))
                    songInfo.sync = oldOffsets(songInfo.level);

                // Add to lists
                playList[songInfo.level] = songInfo;
                indexList.push(songInfo);
                genreList[songInfo.genre].push(songInfo);
                generatedQueues[songInfo.genre].push(songInfo.level);
                    //_gvars.songQueue.push(songData);
            }
            indexList.sort(compareSongLevel);
            _isLoaded = true;
            _loadError = false;
            this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
        }

        private function compareSongLevel(songInfo1:SongInfo, songInfo2:SongInfo):Number
        {
            if (songInfo1.level < songInfo2.level)
                return -1;
            else if (songInfo1.level > songInfo2.level)
                return 1;
            else
                return 0;
        }

        private function playlistLoadError(e:ErrorEvent = null):void
        {
            Logger.error(this, "Load Failure: " + Logger.event_error(e));
            removeLoaderListeners();
            _loadError = true;
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, playlistLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, playlistLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, playlistLoadError);
        }

        private function removeLoaderListeners():void
        {
            _isLoading = false;
            _loader.removeEventListener(Event.COMPLETE, playlistLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, playlistLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, playlistLoadError);
        }

        public function getSongInfo(genre:int, index:int = -1):SongInfo
        {
            // Returns the indexed song for the All genre
            if (genre <= -1 && index >= 0 && index < indexList.length && indexList[index] != null)
                return indexList[index];

            // If a index is set, use the genre list to get the correct song.
            else if (index >= 0 && genreList[genre] != null && genreList[genre][index] != null)
                return genreList[genre][index];

            // Return the song from the playlist, using the levelid as the default.
            else if (playList[genre] != null)
                return playList[genre];

            return null;
        }

        public function updateSongAccess():void
        {
            var songType:int = 0;
            for (var i:int = 0; i < indexList.length; i++)
            {
                songType = 0;

                if (indexList[i].engine == null && _gvars.TOKENS[indexList[i].level] != null)
                    songType = 1;
                if (indexList[i].price > 0)
                    songType = 2;
                if (indexList[i].credits > 0)
                    songType = 3;

                indexList[i].access = _gvars.checkSongAccess(indexList[i]);
                indexList[i].song_type = songType;
            }
        }

        public function updatePublicSongsCount():void
        {
            var s:Site = Site.instance;
            _gvars.TOTAL_SONGS = indexList.length;
            _gvars.TOTAL_PUBLIC_SONGS = indexList.filter(function(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
            {
                return !ArrayUtil.in_array([item.genre], _gvars.NONPUBLIC_GENRES)
            }).length;
        }

        public function engineChangeHandler(e:Event):void
        {
            removeEventListener(GlobalVariables.LOAD_COMPLETE, engineChangeHandler);
            removeEventListener(GlobalVariables.LOAD_ERROR, engineChangeHandler);
            switch (e.type)
            {
                case GlobalVariables.LOAD_ERROR:
                    ArcGlobals.instance.configLegacy = null;
                    load();
                    Alert.add(_lang.string("error_loading_playlist"));
                    break;
                case GlobalVariables.LOAD_COMPLETE:
                    if (_gvars.gameMain.activePanel is MainMenu)
                    {
                        var mainmenu:MainMenu = _gvars.gameMain.activePanel as MainMenu;
                        if (mainmenu != null && mainmenu._MenuSingleplayer != null)
                        {
                            var reload:Boolean = false;
                            if (mainmenu.panel == mainmenu._MenuSingleplayer)
                                reload = true;
                            mainmenu._MenuSingleplayer = null;
                            if (reload)
                            {
                                MenuSongSelection.options.pageNumber = 0;
                                MenuSongSelection.options.scroll_position = 0;
                                mainmenu.switchTo(MainMenu.MENU_SONGSELECTION);
                            }
                            _gvars.removeSongFiles();
                        }
                    }
                    break;
            }
        }

        private function oldOffsets(lvlid:int):int
        {
            switch (lvlid)
            {
                case 87:
                case 88:
                    return -10;
                case 68:
                case 28:
                case 25:
                case 24:
                case 21:
                case 20:
                    return 0;
                case 37:
                    return 6;
                case 23:
                    return -2;
                case 22:
                    return 3;
                case 19:
                    return -4;
                case 17:
                    return 1;
                case 1883:
                    return -21;
                default:
                    return lvlid <= 29 ? -6 : 0;
            }
        }
    }
}
