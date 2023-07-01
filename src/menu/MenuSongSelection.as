package menu
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerSingleton;
    import assets.GameBackgroundColor;
    import assets.menu.GenreSelection;
    import assets.menu.ScrollBackground;
    import assets.menu.ScrollDragger;
    import assets.menu.SongSelectionBackground;
    import assets.menu.icons.fa.iconGear;
    import assets.menu.icons.fa.iconLeft;
    import assets.menu.icons.fa.iconList;
    import assets.menu.icons.fa.iconRight;
    import assets.menu.icons.fa.iconTrophy;
    import classes.Alert;
    import classes.Language;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.SongPlayerBytes;
    import classes.SongPreview;
    import classes.SongQueueItem;
    import classes.User;
    import classes.chart.Song;
    import classes.ui.BoxButton;
    import classes.ui.BoxIcon;
    import classes.ui.BoxText;
    import classes.ui.Prompt;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.StarSelector;
    import classes.ui.Text;
    import classes.ui.Throbber;
    import com.bit101.components.ComboBox;
    import com.bit101.components.PushButton;
    import com.flashfla.net.WebRequest;
    import com.flashfla.utils.ArrayUtil;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.TimeUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.Keyboard;
    import game.GameOptions;
    import menu.MenuSongSelectionOptions;
    import popups.PopupHighscores;
    import popups.PopupQueueManager;
    import popups.PopupSongNotes;
    import game.SkillRating;

    public class MenuSongSelection extends MenuPanel
    {
        public static const ITEM_PER_PAGE:int = 500;

        public static const PLAYLIST_QUEUE:int = -3;
        public static const PLAYLIST_SEARCH:int = -2;
        public static const PLAYLIST_ALL:int = -1;

        public static const TAB_PLAYLIST:int = 0;
        public static const TAB_SEARCH:int = 1;
        public static const TAB_QUEUE:int = 2;
        public static const TAB_HIGHSCORES:int = 3;

        public static const GENRE_GENRES:int = 0;
        public static const GENRE_DIFFICULTIES:int = 1;
        public static const GENRE_SONGFLAGS:int = 2;
        public static const GENRE_MODES:int = 2;

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _lang:Language = Language.instance;
        private var _playlist:Playlist = Playlist.instance;
        private var _mp:MultiplayerSingleton = MultiplayerSingleton.getInstance();

        private var SORT_VALUE_CACHE:Object = {};

        private var genreDisplay:Sprite;
        private var genreItems:Vector.<Text> = new <Text>[];
        private var genreListFlags:Array = [];

        private var GENRE_MODE_TEXT:Text;
        private var genre_mode_prev:iconLeft;
        private var genre_mode_next:iconRight;
        private var SELECTED_GENRE_BACKGROUND:Sprite;

        private var background:SongSelectionBackground;
        private var scrollbar:ScrollBar;
        private var pane:ScrollPane;
        private var pane_filter_text:Text;

        private var genreLength:int;
        private var songItems:Vector.<SongItem> = new <SongItem>[];

        private var optionsBox:Sprite;
        private var infoBox:Sprite;
        private var pages:Sprite;
        private var songList:Array;

        private var GENRE_MODE:int = GENRE_DIFFICULTIES;

        // Info Page
        private var searchBox:BoxText;
        private var searchTypeBox:ComboBox;
        private var sortTypeBox:ComboBox;
        private var sortOrderBox:ComboBox;
        private var sortIgnoreChange:Boolean = false;

        private static var purchasedWebRequests:Vector.<WebRequest> = new <WebRequest>[];

        public static var options:MenuSongSelectionOptions = new MenuSongSelectionOptions();

        private var songItemContextMenu:ContextMenu;
        private var songItemRemoveQueueContext:ContextMenuItem;

        public static var previewMusic:SongPlayerBytes;

        ///- Constructor
        public function MenuSongSelection(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            Flags.VALUES[Flags.ENABLE_GLOBAL_POPUPS] = true;

            // Load Default Alt Engine
            if (_avars.legacyDefaultEngine && !Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD])
            {
                _avars.configLegacy = _avars.legacyDefaultEngine;
                _playlist.addEventListener(GlobalVariables.LOAD_COMPLETE, _playlist.engineChangeHandler);
                _playlist.addEventListener(GlobalVariables.LOAD_ERROR, e_defaultEngineLoadFail);
                _playlist.load();

                Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD_SKIP] = true;

                var loadTextEngine:Text = new Text(this, 0, Main.GAME_HEIGHT / 2 - 15, _lang.string("song_selection_load_default_engine"));
                loadTextEngine.setAreaParams(Main.GAME_WIDTH, 30, Text.CENTER);
            }

            Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD] = true;

            if (Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD_SKIP])
                return true;

            //- Add Background
            background = new SongSelectionBackground();
            background.x = 145;
            background.y = 52;
            background.visible = LocalOptions.getVariable("menu_show_song_selection_background", true);
            this.addChild(background);

            GENRE_MODE = LocalStore.getVariable("genre_mode", GENRE_DIFFICULTIES);

            draw();

            // Re-Open File Browser
            if (Flags.VALUES[Flags.FILE_LOADER_OPEN])
            {
                Flags.VALUES[Flags.FILE_LOADER_OPEN] = false;
                switchTo(MainMenu.MENU_LOCAL);
            }

            return true;
        }

        override public function dispose():void
        {
            var i:uint = 0;

            genreItems = null;
            songItems = null;

            if (genreDisplay)
            {
                genreDisplay.removeEventListener(MouseEvent.CLICK, genreClick);
                genre_mode_prev.removeEventListener(MouseEvent.CLICK, clickHandler);
                genre_mode_next.removeEventListener(MouseEvent.CLICK, clickHandler);
            }

            if (pane)
            {
                pane.removeEventListener(MouseEvent.CLICK, songItemClicked);
                pane.dispose();
                pane = null;
            }

            if (pane_filter_text)
            {
                pane_filter_text.dispose();
                pane_filter_text = null;
            }

            if (pages)
            {
                pages.removeEventListener(MouseEvent.CLICK, pageClicked);
            }

            if (searchBox)
            {
                searchBox.dispose();
                searchBox = null;
            }
            super.dispose();
        }

        override public function draw():void
        {
            // Menu Music Context Menu
            var songItemContextMenuItem:ContextMenuItem;

            songItemContextMenu = new ContextMenu();
            songItemContextMenuItem = new ContextMenuItem(_lang.stringSimple("song_selection_context_menu_music"));
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_setAsMenuMusicContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            songItemContextMenuItem = new ContextMenuItem(_lang.stringSimple("song_selection_context_song_preview"), true);
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_listenToSongPreviewContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            songItemContextMenuItem = new ContextMenuItem(_lang.stringSimple("song_selection_context_chart_preview"));
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_playChartPreviewContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            songItemContextMenuItem = new ContextMenuItem(_lang.stringSimple("song_selection_context_song_options"));
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_songOptionsContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            songItemRemoveQueueContext = new ContextMenuItem(_lang.stringSimple("song_selection_context_remove_from_queue"), true);
            songItemRemoveQueueContext.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_removeFromQueueContextSelect);
            songItemContextMenu.customItems.push(songItemRemoveQueueContext);

            //- Build Genre Holder
            if (genreDisplay == null)
            {
                genreDisplay = new Sprite();
                genreDisplay.x = 5;
                genreDisplay.y = 135;
                genreDisplay.addEventListener(MouseEvent.CLICK, genreClick, false, 0, true);
                this.addChild(genreDisplay);

                this.graphics.lineStyle(1, 0xffffff, 0.5);
                this.graphics.moveTo(22, 133);
                this.graphics.lineTo(121, 133);

                SELECTED_GENRE_BACKGROUND = new GenreSelection();

                GENRE_MODE_TEXT = new Text(this, 17, 106, _lang.string("genre_mode_" + GENRE_SONGFLAGS));
                GENRE_MODE_TEXT.align = Text.CENTER;
                GENRE_MODE_TEXT.width = 109;
                GENRE_MODE_TEXT.fontSize = 16;

                genre_mode_prev = new iconLeft();
                genre_mode_prev.x = 16;
                genre_mode_prev.y = 119;
                genre_mode_prev.scaleX = genre_mode_prev.scaleY = 0.22;
                genre_mode_prev.buttonMode = true;
                genre_mode_prev.useHandCursor = true;
                genre_mode_prev.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                this.addChild(genre_mode_prev);

                genre_mode_next = new iconRight();
                genre_mode_next.x = 127;
                genre_mode_next.y = 119;
                genre_mode_next.scaleX = genre_mode_next.scaleY = 0.22;
                genre_mode_next.buttonMode = true;
                genre_mode_next.useHandCursor = true;
                genre_mode_next.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                this.addChild(genre_mode_next);
            }

            //- Add Info Box Tabs
            if (optionsBox != null)
            {
                for (var i:int = 0; i < optionsBox.numChildren; ++i)
                {
                    optionsBox.getChildAt(i).removeEventListener(MouseEvent.CLICK, clickHandler, false);
                }
                optionsBox.removeChildren();
            }

            optionsBox = new Sprite();
            optionsBox.x = 559; // 155
            optionsBox.y = 64;
            this.addChild(optionsBox);

            var optionsTexts:Array = [[_lang.string("song_selection_menu_search"), "search"], [_lang.string("song_selection_search"), "queue"]]
            for (i = 0; i < optionsTexts.length; i++)
            {
                var optionActionBox:BoxButton = new BoxButton(optionsBox, (i * 88.5), 0, 85.5, 27, optionsTexts[i][0], 11, clickHandler);
                optionActionBox.action = optionsTexts[i][1];
            }

            //- Add Song Info Box
            if (infoBox == null)
            {
                infoBox = new Sprite();
                infoBox.graphics.lineStyle(1, 0xFFFFFF, 0.35, false);
                infoBox.graphics.beginFill(0xFFFFFF, 0.1);
                infoBox.graphics.drawRect(0, 0, 174, 320);
                infoBox.graphics.endFill();
                infoBox.x = 559; // 155
                infoBox.y = 94;
                this.addChild(infoBox);
            }

            //- Add ScrollPane
            if (pane == null)
            {
                pane = new ScrollPane(this, 155, 64, 401, 351, mouseWheelHandler);
                pane.graphics.lineStyle(1, 0xFFFFFF, 0.35, false);
                pane.graphics.moveTo(0.2, -0.5);
                pane.graphics.lineTo(399, -0.5);
                pane.graphics.moveTo(0.2, 351.5);
                pane.graphics.lineTo(399, 351.5);
                pane.addEventListener(MouseEvent.CLICK, songItemClicked, false, 0, true);
            }

            if (pane_filter_text == null)
            {
                pane_filter_text = new Text(this, 155, 64, "");
                pane_filter_text.setAreaParams(401, 351, "center");
                pane_filter_text.visible = false;
            }

            //- Add ScrollBar
            if (scrollbar == null)
            {
                scrollbar = new ScrollBar(this, 744, 81, 21, 325, new ScrollDragger(), new ScrollBackground(), scrollBarMoved);
            }

            //- Build Content
            buildGenreList();
            buildPlayList();
            buildInfoBox();
        }

        override public function stageAdd():void
        {
            if (Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD_SKIP])
            {
                delete Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD_SKIP];
                return;
            }

            //- Add Listeners
            if (stage)
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler, false, 0, true);
        }

        override public function stageRemove():void
        {
            //- Remove Listeners
            if (stage)
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
        }

        /**
         * Called when an Alt Engine fails to load as the default displayed engine.
         * Reloads the song selection panel.
         * @param e
         */
        private function e_defaultEngineLoadFail(e:Event):void
        {
            _playlist.removeEventListener(GlobalVariables.LOAD_ERROR, e_defaultEngineLoadFail);
            _playlist.engineChangeHandler(e);
            switchTo(MainMenu.MENU_SONGSELECTION, true);
        }

        //******************************************************************************************//
        // Genre Sidebar Logic
        //******************************************************************************************//

        /**
         * Builds the array for flag colors if applicable.
         */
        public function buildGenreListFlags():void
        {
            if (!_gvars.activeUser.DISPLAY_GENRE_FLAG)
                return;

            genreListFlags = [];

            var i:int;

            //- Build Genre List
            var totalGenres:int = getTotalGenres();

            var genre_index:int;
            for (genre_index = -1; genre_index < totalGenres; ++genre_index)
            {

                if (genre_index == PLAYLIST_ALL)
                {
                    songList = [];

                    var len:int = _playlist.indexList.length;
                    for (i = 0; i < len; i++)
                        songList[i] = _playlist.indexList[i];
                }
                else
                {
                    // We already know the flag.
                    if (GENRE_MODE == GENRE_SONGFLAGS)
                    {
                        genreListFlags[genre_index] = (genre_index >= 2 ? GlobalVariables.SONG_ICON_COLOR[genre_index] : null);
                    }
                    else if (GENRE_MODE == GENRE_DIFFICULTIES)
                    {
                        // Difficulty Filter
                        if (genre_index == _gvars.DIFFICULTY_RANGES.length - 1)
                        {
                            songList = getFilteredSongInfoArrayFromVec(_playlist.indexList, function(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
                            {
                                return item.difficulty <= 0 || item.difficulty >= _gvars.DIFFICULTY_RANGES[genre_index][0];
                            });
                        }
                        else
                        {
                            songList = getFilteredSongInfoArrayFromVec(_playlist.indexList, function(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
                            {
                                return item.difficulty >= _gvars.DIFFICULTY_RANGES[genre_index][0] && item.difficulty <= _gvars.DIFFICULTY_RANGES[genre_index][1];
                            });
                        }
                    }
                    else
                    {
                        songList = _playlist.genreList[genre_index + 1];
                    }
                }

                if (songList != null)
                {
                    var best_flag:int = 8; // 8 = AAA
                    for (i = 0; i < songList.length; i++)
                    {
                        var song_flag:int = GlobalVariables.getSongIconIndex(songList[i], _gvars.activeUser.getLevelRank(songList[i]));

                        if (song_flag == GlobalVariables.SONG_ICON_FC_STAR)
                            song_flag = GlobalVariables.SONG_ICON_FC;

                        if (song_flag < best_flag)
                        {
                            best_flag = song_flag;
                            if (song_flag <= 1)
                                break;
                        }
                    }
                    genreListFlags[genre_index] = (best_flag >= 2 ? GlobalVariables.SONG_ICON_COLOR[best_flag] : null);
                    songList = null;
                }
            }
        }

        /**
         * General builder for the Genre left sidebar display.
         */
        public function buildGenreList():void
        {
            // Reset
            genreDisplay.removeChildren();
            genreItems.length = 0;
            genreDisplay.addChild(SELECTED_GENRE_BACKGROUND);

            // Build Genre Flag Array
            buildGenreListFlags();

            // Set Genre Text
            GENRE_MODE_TEXT.text = _lang.string("genre_mode_" + GENRE_MODE);

            //- Build Genre List
            var totalGenres:int = getTotalGenres();

            var genre_index:int;
            var position_index:int = -1;

            for (genre_index = -1; genre_index < totalGenres; ++genre_index)
            {
                // If displaying genres, and Legacy Genre isn't displayed, skip it.
                if (GENRE_MODE == GENRE_GENRES)
                {
                    if (!_gvars.activeUser.DISPLAY_LEGACY_SONGS && !_playlist.engine && genre_index == (Constant.LEGACY_GENRE - 1))
                    {
                        continue;
                    }
                    position_index++;
                }
                else
                {
                    position_index = genre_index + 1;
                }

                // Flag Color
                var genre_flag:String = genreListFlags[genre_index];
                var genre_text:String = getGenreText(genre_index);

                if (genre_flag != null && _gvars.activeUser.DISPLAY_GENRE_FLAG)
                    genre_text = "<font color=\"" + genre_flag + "\">•</font> " + genre_text;

                // Build Label
                var songGenre:Text = new Text(genreDisplay, 0, 0, genre_text, 14);
                songGenre.height = 22.6;
                songGenre.width = 130.75;
                songGenre.mouseEnabled = true;
                songGenre.useHandCursor = true;
                songGenre.buttonMode = true;
                songGenre.index = genre_index;
                songGenre.position = position_index;
                genreItems.push(songGenre);
            }

            updateGenreList();
        }

        /**
         * Updates genre position, font size, and selection background.
         */
        private function updateGenreList():void
        {
            // Remove Selected Genre Background
            SELECTED_GENRE_BACKGROUND.visible = false;

            var totalGenres:int = genreItems.length;
            var gap:Number = Math.min(23, Math.ceil(337 / (totalGenres + 1)));

            for (var g:int = 0; g < totalGenres; g++)
            {
                genreItems[g].y = gap * genreItems[g].position;

                // Set Selected Background
                if (options.activeGenre == genreItems[g].index)
                {
                    genreItems[g].fontSize = 18;
                    SELECTED_GENRE_BACKGROUND.y = genreItems[g].y - 2;
                    SELECTED_GENRE_BACKGROUND.visible = true;
                }
                else
                    genreItems[g].fontSize = 14;
            }
        }

        /**
         * Get the text to display for the Genre Button
         * @param gindex Genre Index
         * @return Genre Display Text
         */
        private function getGenreText(gindex:int):String
        {
            if (GENRE_MODE == GENRE_GENRES || gindex == PLAYLIST_ALL)
                return _lang.string("genre_" + gindex);

            if (GENRE_MODE == GENRE_DIFFICULTIES)
                return _lang.string("difficulty_title_" + gindex);

            if (gindex == 1)
                return _lang.string("song_selection_played");

            return GlobalVariables.SONG_ICON_TEXT[gindex];
        }

        /**
         * Get the total genres to display depending on the GENRE_MODE.
         * @return Genre Count
         */
        private function getTotalGenres():int
        {
            switch (GENRE_MODE)
            {
                case GENRE_DIFFICULTIES:
                    return _gvars.DIFFICULTY_RANGES.length;
                case GENRE_SONGFLAGS:
                    return GlobalVariables.SONG_ICON_TEXT.length;
                default:
                    return (!_gvars.activeUser.DISPLAY_LEGACY_SONGS && !_playlist.engine) ? _gvars.TOTAL_GENRES - 1 : _gvars.TOTAL_GENRES;
            }
        }

        /**
         * Called from the genre display when a genre is clicked.
         * This sets the active genre to the item clicked, resets
         * most of the display parameters and rebuilds the display.
         */
        private function genreClick(e:Event = null):void
        {
            if (e.target.index != null && options.activeGenre != e.target.index)
            {
                options.infoTab = TAB_PLAYLIST;
                options.isFilter = false;
                options.activeGenre = e.target.index;
                options.activeIndex = -1;
                options.activeSongId = -1;
                options.pageNumber = 0;
                options.scroll_position = 0;

                resetFilterOptions();

                updateGenreList()
                buildPlayList();
                buildInfoBox();
            }
            stage.focus = stage;
        }

        //******************************************************************************************//
        // Song Playlist / Item Logic
        //******************************************************************************************//
        /**
         * Generates a valid song list given the applied terms such as genre, search and filters.
         * Is also responsible for displaying the results in the scroll pane.
         */
        public function buildPlayList():void
        {
            //- Clear out/reset pane items and pages.
            songItems.length = 0;

            scrollbar.reset();
            pane.clear();
            pane_filter_text.visible = false;

            //- Init Variables
            var doPageSlice:Boolean = false;
            var i:uint;
            var yOffset:int = 0;
            var songInfo:SongInfo;
            var sI:SongItem;

            var sourceListLength:int = 0;

            //- Set Song array based on selected genre
            // DM_QUEUE
            if (options.activeGenre == PLAYLIST_QUEUE)
            {
                _gvars.songQueue = options.queuePlaylist;
                songList = _gvars.songQueue;
                sourceListLength = _gvars.songQueue.length;
                genreLength = _gvars.songQueue.length;
                doPageSlice = true;
            }

            // DM_SEARCH
            else if (options.activeGenre == PLAYLIST_SEARCH)
            {
                // Doing search, build array based on case-insensitive match
                if (options.isFilter)
                {
                    songList = getFilteredSongInfoArrayFromVec(_playlist.indexList, filterSongListOptionsFilter);
                    sourceListLength = songList.length;
                    genreLength = songList.length;
                    doPageSlice = true;
                }
            }

            // DM_ALL
            else if (options.activeGenre == PLAYLIST_ALL)
            {
                songList = [];
                var len:int = _playlist.indexList.length;
                for (i = 0; i < len; i++)
                    songList[i] = _playlist.indexList[i];

                // Song List Filters
                sourceListLength = songList.length;
                songList = filterSongListFlags(songList);
                songList = filterSongListUser(songList);

                // List Length and Slice into pages.
                genreLength = songList.length;
                doPageSlice = true;
            }

            // STANDARD_DISPLAY
            else
            {
                if (GENRE_MODE == GENRE_DIFFICULTIES)
                {
                    // Difficulty Filter
                    if (options.activeGenre == _gvars.DIFFICULTY_RANGES.length - 1)
                    {
                        songList = getFilteredSongInfoArrayFromVec(_playlist.indexList, filterSongListDifficultyMax);
                    }
                    else
                    {
                        songList = getFilteredSongInfoArrayFromVec(_playlist.indexList, filterSongListDifficultyRange);
                    }

                    // Song List Filters
                    sourceListLength = songList.length;
                    songList = filterSongListFlags(songList);
                    songList = filterSongListUser(songList);

                    // Sort and get List Length
                    songList.sortOn(["access", "difficulty", "name"], [Array.NUMERIC, Array.NUMERIC, Array.CASEINSENSITIVE]);
                    genreLength = songList.length;
                }
                else if (GENRE_MODE == GENRE_SONGFLAGS)
                {
                    // Song Flag Filter
                    songList = getFilteredSongInfoArrayFromVec(_playlist.indexList, filterSongListSongFlags);

                    // Song List Filters
                    sourceListLength = songList.length;
                    songList = filterSongListFlags(songList);
                    songList = filterSongListUser(songList);

                    // Sort, List Length, and Slice into pages.
                    songList.sortOn(["access", "difficulty", "name"], [Array.NUMERIC, Array.NUMERIC, Array.CASEINSENSITIVE]);
                    genreLength = songList.length;
                    doPageSlice = true;
                }
                else
                {
                    songList = _playlist.genreList[options.activeGenre + 1];
                    genreLength = songList ? songList.length : 0;
                    sourceListLength = genreLength;
                }
            }

            songItemRemoveQueueContext.visible = options.activeGenre == PLAYLIST_QUEUE;

            // User Filter
            if (songList != null && songList.length > 0)
            {
                if (options.activeGenre != PLAYLIST_ALL && options.infoTab != TAB_QUEUE)
                {
                    sourceListLength = Math.max(sourceListLength, songList.length);
                    songList = filterSongListUser(songList);
                    genreLength = songList.length;
                }
            }

            // Sorting
            if (options.last_sort_type != null)
            {
                SORT_VALUE_CACHE = {};

                var sortOrder:uint = options.last_sort_order == "desc" ? Array.DESCENDING : 0;
                switch (options.last_sort_type)
                {
                    case "name":
                    case "author":
                    case "stepauthor":
                    case "style":
                        songList.sortOn(["access", options.last_sort_type], [Array.NUMERIC, Array.CASEINSENSITIVE | sortOrder]);
                        break;

                    case "time_secs":
                    case "level":
                    case "note_count":
                    case "difficulty":
                    case "max_nps":
                        songList.sortOn(["access", options.last_sort_type], [Array.NUMERIC, Array.NUMERIC | sortOrder]);
                        break;

                    case "rank":
                        songList.sort(sortByRank, Array.NUMERIC | sortOrder);
                        break;

                    case "raw_goods":
                        songList.sort(sortByRawGoods, Array.NUMERIC | sortOrder);
                        break;

                    default:
                        break;
                }
            }

            // Page Splicing
            if (doPageSlice)
            {
                songList = songList.slice(options.pageNumber * ITEM_PER_PAGE, (options.pageNumber + 1) * ITEM_PER_PAGE);
            }

            //- Pages
            drawPages();

            // Error Messages
            if (songList == null)
            {
                pane_filter_text.visible = true;
                pane_filter_text.text = _lang.string("song_selection_filter_null_error");
            }
            else if (songList != null && songList.length == 0)
            {
                pane_filter_text.visible = true;
                if (options.activeGenre == PLAYLIST_SEARCH)
                    pane_filter_text.text = _lang.string("song_selection_filter_no_results_found");
                else if (sourceListLength > 0)
                    pane_filter_text.text = sprintf(_lang.string("song_selection_filter_no_results_hidden"), {"items": sourceListLength});
                else
                    pane_filter_text.text = _lang.string("song_selection_filter_no_results");
            }

            //- Sanity
            if (songList == null || songList.length <= 0)
            {
                options.activeIndex = -1;
                options.activeSongId = -1;
                return;
            }

            //- Build Playlist
            for (var sX:int = 0; sX < songList.length; sX++)
            {
                songInfo = songList[sX];
                sI = new SongItem();
                sI.setData(songInfo, _gvars.activeUser.getLevelRank(songInfo));
                sI.noteEnabled = _gvars.activeUser.DISPLAY_SONG_NOTE;
                sI.setContextMenu(songItemContextMenu);
                sI.y = yOffset;
                sI.index = sX;
                songItems.push(sI);
                pane.content.addChild(sI);
                yOffset += sI.height + 2;
            }

            // Scroll Position
            pane.scrollTo(options.scroll_position);
            scrollbar.scrollTo(options.scroll_position);

            scrollbar.draggerVisibility = (yOffset > pane.height);

            //- Update Selected Index
            // Find and select last active song id.
            var hasSelected:Boolean = false;
            for (sX = 0; sX < songList.length; sX++)
            {
                songInfo = songList[sX];
                if (options.activeSongId == songInfo.level)
                {
                    setActiveIndex(sX, -1, false, false);
                    hasSelected = true;
                    break;
                }
            }

            // No active valid song found, clear saved actives.
            if (!hasSelected)
            {
                options.activeIndex = -1;
                options.activeSongId = -1;
            }

            // No song selected, select the first in the list if valid.
            if (options.activeIndex == -1)
            {
                setActiveIndex(0, -1, false, false);
            }
        }

        private function getSongRank(song:SongInfo, activeUser:User):uint
        {
            var songRank:uint = SORT_VALUE_CACHE[song.level];
            if (songRank)
            {
                return songRank;
            }

            var songLevelRank:Object = activeUser.getLevelRank(song);
            if (songLevelRank == null)
            {
                songRank = 1000000000;
            }
            else
            {
                songRank = songLevelRank.rank;
            }

            SORT_VALUE_CACHE[song.level] = songRank;

            return songRank;
        }

        private function sortByRank(songA:SongInfo, songB:SongInfo):int
        {
            var songARank:uint = getSongRank(songA, _gvars.activeUser);
            var songBRank:uint = getSongRank(songB, _gvars.activeUser);

            if (songA.access !== songB.access)
            {
                return songA.access < songB.access ? -1 : 1;
            }

            if (songARank === songBRank)
            {
                return songA.level < songB.level ? -1 : 1;
            }

            return songARank < songBRank ? -1 : 1;
        }

        private function getSongRawGoods(song:SongInfo, activeUser:User):Number
        {
            var songRawGoods:Number = SORT_VALUE_CACHE[song.level];
            if (songRawGoods)
            {
                return songRawGoods;
            }

            var songLevelRank:Object = activeUser.getLevelRank(song);

            if (songLevelRank == null)
            {
                songRawGoods = 2000000;
            }
            else
            {
                var rawGoods:Number = songLevelRank.good + (songLevelRank.average * 1.8) + (songLevelRank.miss * 2.4) + (songLevelRank.boo * 0.2);
                var notesPlayed:uint = songLevelRank.perfect + songLevelRank.good + songLevelRank.average + songLevelRank.miss;
                var noteCount:uint = song.note_count || songLevelRank.arrows;

                if (notesPlayed < noteCount)
                {
                    var implicitMisses:uint = noteCount - notesPlayed;
                    songRawGoods = 1000000 + rawGoods + implicitMisses * 2.4;
                }
                else
                {
                    songRawGoods = rawGoods;
                }
            }

            SORT_VALUE_CACHE[song.level] = songRawGoods;

            return songRawGoods;
        }

        private function sortByRawGoods(songA:SongInfo, songB:SongInfo):int
        {
            var songARawGoods:Number = getSongRawGoods(songA, _gvars.activeUser);
            var songBRawGoods:Number = getSongRawGoods(songB, _gvars.activeUser);

            if (songA.access !== songB.access)
            {
                return songA.access < songB.access ? -1 : 1;
            }

            if (songARawGoods === songBRawGoods)
            {
                return songA.level < songB.level ? -1 : 1;
            }

            return songARawGoods < songBRawGoods ? -1 : 1;
        }


        /**
         * Filters the `_playlist.indexList` vector of SongInfo into an Array given a specific filter function.
         */
        private function getFilteredSongInfoArrayFromVec(vec:Vector.<SongInfo>, filter:Function):Array
        {
            var filteredArray:Array = [];

            var filteredSongInfos:Vector.<SongInfo>;
            filteredSongInfos = _playlist.indexList.filter(filter);

            for each (var songInfo:SongInfo in filteredSongInfos)
                filteredArray.push(songInfo);

            return filteredArray;
        }

        /**
         * Vector filter for difficulty ranges. This one handles everything at and above the top range and the special case for difficulty 0.
         */
        private function filterSongListDifficultyMax(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
        {
            return item.difficulty <= 0 || item.difficulty >= _gvars.DIFFICULTY_RANGES[options.activeGenre][0];
        }

        /**
         * Vector filter for difficulty ranges. This one handles the range between two difficulty points.
         */
        private function filterSongListDifficultyRange(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
        {
            return item.difficulty >= _gvars.DIFFICULTY_RANGES[options.activeGenre][0] && item.difficulty <= _gvars.DIFFICULTY_RANGES[options.activeGenre][1];
        }

        /**
         * Array filter for song flags.
         */
        private function filterSongListSongFlags(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
        {
            return GlobalVariables.getSongIconIndex(item, _gvars.activeUser.getLevelRank(item)) == options.activeGenre;
        }

        /**
         * Array filter for options.filter
         */
        private function filterSongListOptionsFilter(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
        {
            return options.filter(item);
        }

        /**
         * Process the legacy filter on the given song list if enabled.
         * @param songList Song List Array for Song objects to filter.
         */
        private function filterSongListFlags(songList:Array):Array
        {
            if (!_gvars.activeUser.DISPLAY_LEGACY_SONGS)
                songList = songList.filter(filterSongListLegacyFilter);

            if (!_gvars.activeUser.DISPLAY_EXPLICIT_SONGS)
                songList = songList.filter(filterSongListExplicitFilter);

            if (!_gvars.activeUser.DISPLAY_UNRANKED_SONGS)
                songList = songList.filter(filterSongListUnrankedFilter);

            return songList;
        }

        /**
         * Legacy Array filter for filterSongListFlags.
         */
        private function filterSongListLegacyFilter(item:SongInfo, index:int, array:Array):Boolean
        {
            return !item.is_legacy;
        }

        /**
         * Explicit Array filter for filterSongListFlags.
         */
        private function filterSongListExplicitFilter(item:SongInfo, index:int, array:Array):Boolean
        {
            return !item.is_explicit;
        }

        /**
         * Unranked Array filter for filterSongListFlags.
         */
        private function filterSongListUnrankedFilter(item:SongInfo, index:int, array:Array):Boolean
        {
            return !item.is_unranked;
        }

        /**
         * Process the user filter on the given song list if enabled.
         * @param songList Song List Array for Song objects to filter.
         */
        private function filterSongListUser(songList:Array):Array
        {
            if (_gvars.activeFilter != null)
                songList = songList.filter(filterSongListUserFilter);

            return songList;
        }

        /**
         * Array filter for filterSongListUser.
         */
        private function filterSongListUserFilter(item:SongInfo, index:int, array:Array):Boolean
        {
            return _gvars.activeFilter.process(item, _gvars.activeUser);
        }

        /**
         * Selects and highlights a Song Item in the playlist for the given index.
         * @param index New Index
         * @param last Last Selected Index, if not -1, unhighlights the given index.
         * @param doScroll Scrolls to the song item when true.
         * @param mpUpdate Send update to multiplayer for selection. Only send for user selection events.
         */
        public function setActiveIndex(index:int, last:int, doScroll:Boolean = false, mpUpdate:Boolean = true):void
        {
            // No need to do anything if nothing changed, or nothing to select
            if (index == last)
                return;

            // Reset on invalid index.
            if (songItems.length <= 0 || index < 0 || index >= songItems.length)
            {
                options.activeIndex = -1;
                options.activeSongId = -1;
                return;
            }

            // Set Index
            options.activeIndex = index;

            // "All" uses pages of ITEM_PER_PAGE, so the index will be higher then ITEM_PER_PAGE on other pages. Take care of it.
            if (options.activeGenre <= -1)
            {
                index %= ITEM_PER_PAGE;
                last %= ITEM_PER_PAGE;
            }

            // Set Song
            options.activeSongId = songItems[index].level;

            // Set Active Highlights
            songItems[index].active = true;
            if (last >= 0 && last < songItems.length)
            {
                songItems[last].highlight = false;
                songItems[last].active = false;
            }

            // Scroll when doScroll is set.
            if (doScroll && scrollbar.draggerVisibility)
            {
                var scrollVal:Number = (((songItems[index].y / pane.content.height) > 0.5) ? ((songItems[index].y + songItems[index].height) / pane.content.height) : ((songItems[index].y) / pane.content.height));
                options.scroll_position = scrollVal;
                pane.scrollTo(scrollVal);
                scrollbar.scrollTo(scrollVal);
            }

            // Update Multiplayer Selection
            if (mpUpdate && options.activeSongId != -1)
            {
                var songInfo:SongInfo = _playlist.getSongInfo(options.activeSongId);
                _mp.gameplayPicking(songInfo);
            }
        }

        /**
         * Called from the playlist scroll pane when a song item is clicked.
         * When a new song is selected, sets the active index and draws the info box for the new song information.
         * If the same item is clicked twice, begins loading of the song.
         * @param e
         */
        private function songItemClicked(e:Event = null):void
        {
            if (e.target is SongItem)
            {
                var tarSongItem:SongItem = (e.target as SongItem);
                if (tarSongItem.index != options.activeIndex)
                {
                    options.infoTab = TAB_PLAYLIST;
                    setActiveIndex(tarSongItem.index, options.activeIndex);
                    buildInfoBox();
                }
                else
                {
                    if (!tarSongItem.isLocked && options.infoTab == TAB_PLAYLIST)
                    {
                        if (_mp.gameplayHasOpponent())
                            multiplayerLoad(tarSongItem.level);
                        else
                            playSong(tarSongItem.level);
                    }
                    else
                    {
                        options.infoTab = TAB_PLAYLIST;
                        buildInfoBox();
                    }
                }
            }
        }

        /**
         * Song Item Context Menu: Display the Song Notes popup for the interacted Song Item.
         * @param e
         */
        private function e_songOptionsContextSelect(e:ContextMenuEvent):void
        {
            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            var songInfo:SongInfo = _playlist.getSongInfo(songItem.level);

            if (songInfo != null)
                _gvars.gameMain.addPopup(new PopupSongNotes(this, songInfo));
        }

        /**
         * Song Item Context Menu: Sets the interacted song as the current menu music.
         * This handles loading the music in the background if not already loaded,
         * or sets the music from the already loaded copy if available.
         * @param e
         */
        private function e_setAsMenuMusicContextSelect(e:ContextMenuEvent):void
        {
            _gvars.options = new GameOptions();
            _gvars.options.fill();
            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            var songInfo:SongInfo = _playlist.getSongInfo(songItem.level);
            if (songInfo != null)
            {
                var song:Song = _gvars.getSongFile(songInfo);
                if (song.isLoaded)
                {
                    writeMenuMusicBytes(song);
                    playMenuMusicSong(song);
                }
                else
                {
                    Alert.add(sprintf(_lang.string("song_selection_load_music_for"), {"name": songInfo.name}), 90);
                    song.addEventListener(Event.COMPLETE, e_menuMusicConvertSongLoad);
                }
            }
        }

        /**
         * Song Item Context Menu: Plays the chart preview of the selected song.
         */
        private function e_playChartPreviewContextSelect(e:ContextMenuEvent):void
        {
            _gvars.options = new GameOptions();
            _gvars.options.fill();
            _gvars.options.replay = new SongPreview(0);

            if (!_gvars.options.replay.isLoaded)
            {
                (_gvars.options.replay as SongPreview).setupSongPreview((e.contextMenuOwner as SongItem).songInfo);
            }

            if (_gvars.options.replay.isLoaded)
            {
                // Setup Vars
                _gvars.songQueue = [];
                _gvars.songQueue.push(Playlist.instance.getSongInfo(_gvars.options.replay.level));

                // Switch to game
                Alert.add(_lang.string("song_selection_load_play_chart_preview"));
                switchTo(Main.GAME_PLAY_PANEL);
            }
        }

        /**
         * Song Item Context Menu: Same as for setting a song as the current menu music,
         * but for playing a song preview instead.
         * @param e
         */
        private function e_listenToSongPreviewContextSelect(e:ContextMenuEvent):void
        {
            _gvars.options = new GameOptions();
            _gvars.options.fill();

            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            var songInfo:SongInfo = _playlist.getSongInfo(songItem.level);
            if (songInfo != null)
            {
                var song:Song = _gvars.getSongFile(songInfo);
                if (song.isLoaded)
                {
                    playSongPreview(song);
                }
                else
                {
                    Alert.add(sprintf(_lang.string("song_selection_load_music_for"), {"name": songInfo.name}), 90);
                    song.addEventListener(Event.COMPLETE, e_songPreviewConvertSongLoad);
                }
            }
        }

        /**
         * Song Item Context Menu: Removes the interacted with Song Item from the Song Queue.
         * @param e
         */
        private function e_removeFromQueueContextSelect(e:ContextMenuEvent):void
        {
            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            _gvars.songQueue.removeAt(songItem.index);
            saveQueuePlaylist();

            buildPlayList();
            buildInfoBox();
        }

        /**
         * Save the queue playlist into the song selection menu options.
         */
        private function saveQueuePlaylist():void
        {
            options.queuePlaylist = _gvars.songQueue;
        }

        /**
         * Updates the displayed song note for the given level.
         * @param level
         */
        public function updateSongItemNote(level:int):void
        {
            for (var i:int = 0; i < songItems.length; i++)
            {
                if (options.activeSongId == songItems[i].level)
                {
                    songItems[i].updateOrShow();
                    if (options.infoTab == TAB_PLAYLIST)
                        buildInfoBox();
                    break;
                }
            }
        }


        //******************************************************************************************//
        // Info Box Logic
        //******************************************************************************************//

        /**
         * General builder for the Info Box.
         */
        public function buildInfoBox():void
        {
            // Deselect Buttons
            for (var bti:int = 0; bti < optionsBox.numChildren; bti++)
                optionsBox.getChildAt(bti).alpha = 0.75;

            // Get Song Details
            var songInfo:SongInfo = _playlist.getSongInfo(options.activeSongId);

            //- Cleanup old Info Box
            infoBox.removeChildren();

            //- Sanity
            if (songInfo == null && options.infoTab != TAB_QUEUE && options.infoTab != TAB_SEARCH)
                return;

            //- Build Info Box
            // Song Search
            if (options.infoTab == TAB_SEARCH)
                buildInfoBoxSearch();

            // Playlist Queue
            else if (options.infoTab == TAB_QUEUE)
                buildInfoBoxQueue();

            // Song Ranks
            else if (options.infoTab == TAB_HIGHSCORES)
                buildInfoBoxHighscores(songInfo);

            // Song Details
            else
                buildInfoBoxSongDetails(songInfo);

            // Action Buttons for Songs
            if (options.infoTab == TAB_PLAYLIST || options.infoTab == TAB_HIGHSCORES)
                buildInfoBoxSongActionButtons(songInfo);

            // For search, set focus on search box:
            if (options.infoTab == TAB_SEARCH)
                stage.focus = searchBox.field;
        }

        /**
         * Builds Search Display for the InfoBox.
         */
        public function buildInfoBoxSearch():void
        {
            sortIgnoreChange = true;

            // Highlight Tab Button
            optionsBox.getChildAt(0).alpha = 1;

            // Search Box
            if (searchBox == null)
                searchBox = new BoxText(null, 5, 5, 164, 27);

            infoBox.addChild(searchBox);

            // Search Type
            var searchTypeBoxItems:Array = [{label: _lang.stringSimple("song_selection_search_song_name"), data: "name"},
                {label: _lang.stringSimple("song_selection_search_author"), data: "author"},
                {label: _lang.stringSimple("song_selection_search_stepauthor"), data: "stepauthor"},
                {label: _lang.stringSimple("song_selection_search_style"), data: "style"}];

            if (searchTypeBox != null)
                searchTypeBox.removeEventListener(Event.SELECT, searchTypeSelect);

            searchTypeBox = new ComboBox(null, 5, 37, "", searchTypeBoxItems);
            searchTypeBox.setSize(164, 25);
            searchTypeBox.fontSize = 11;
            searchTypeBox.addEventListener(Event.SELECT, searchTypeSelect);
            infoBox.addChild(searchTypeBox);

            var searchBtn:BoxButton = new BoxButton(infoBox, 5, 67, 164, 27, _lang.string("song_selection_search_panel_search"), 12, clickHandler);
            searchBtn.action = "doSearch";

            // Order Type
            new Text(infoBox, 5, 137, _lang.string("song_selection_sort"), 14, "#DDDDDD");

            //- data tag should match tag names in SongInfo
            var sortTypeBoxItems:Array = [{label: _lang.stringSimple("song_selection_search_default"), data: null},
                {label: _lang.stringSimple("song_selection_search_song_name"), data: "name"},
                {label: _lang.stringSimple("song_selection_search_author"), data: "author"},
                {label: _lang.stringSimple("song_selection_search_stepauthor"), data: "stepauthor"},
                {label: _lang.stringSimple("song_selection_search_style"), data: "style"},
                {label: _lang.stringSimple("song_selection_search_difficulty"), data: "difficulty"},
                {label: _lang.stringSimple("song_selection_search_length"), data: "time_secs"},
                {label: _lang.stringSimple("song_selection_search_note_count"), data: "note_count"},
                {label: _lang.stringSimple("song_selection_search_nps"), data: "max_nps"},
                {label: _lang.stringSimple("song_selection_search_id"), data: "level"},
                {label: _lang.stringSimple("song_selection_search_rank"), data: "rank"},
                {label: _lang.stringSimple("song_selection_search_raw_goods"), data: "raw_goods"}];

            if (sortTypeBox != null)
                sortTypeBox.removeEventListener(Event.SELECT, sortTypeSelect);

            sortTypeBox = new ComboBox(null, 5, 162, "", sortTypeBoxItems);
            sortTypeBox.setSize(164, 25);
            sortTypeBox.fontSize = 11;
            sortTypeBox.numVisibleItems = sortTypeBoxItems.length;
            sortTypeBox.addEventListener(Event.SELECT, sortTypeSelect);
            infoBox.addChild(sortTypeBox);

            var sortOrderBoxItems:Array = [{label: _lang.stringSimple("song_selection_sort_asc"), data: "asc"},
                {label: _lang.stringSimple("song_selection_sort_desc"), data: "desc"}];

            if (sortOrderBox != null)
                sortOrderBox.removeEventListener(Event.SELECT, sortOrderSelect);

            sortOrderBox = new ComboBox(null, 5, 188, "", sortOrderBoxItems);
            sortOrderBox.setSize(164, 25);
            sortOrderBox.fontSize = 11;
            sortOrderBox.addEventListener(Event.SELECT, sortOrderSelect);
            infoBox.addChild(sortOrderBox);

            // Random Song
            var randomButton:BoxButton = new BoxButton(infoBox, 5, 288, 164, 27, _lang.string("song_selection_filter_panel_random"), 12, clickHandler);
            randomButton.action = "doFilterRandom";

            // Save Search Parameters
            if (options.last_search_text != null)
            {
                searchBox.text = options.last_search_text;
                searchBox.field.setSelection(searchBox.field.length, searchBox.field.length);
                options.last_search_text = null;
            }

            // Saved Search Type
            if (options.last_search_type != null)
                searchTypeBox.selectedItemByData = options.last_search_type;

            else if (searchTypeBox.selectedIndex == -1)
                searchTypeBox.selectedIndex = 0;

            // Saved Sort Type
            if (options.last_sort_type != null)
                sortTypeBox.selectedItemByData = options.last_sort_type;

            else if (sortTypeBox.selectedIndex == -1)
                sortTypeBox.selectedIndex = 0;

            // Saved Sort Order
            if (options.last_sort_order != null)
                sortOrderBox.selectedItemByData = options.last_sort_order;

            else if (sortOrderBox.selectedIndex == -1)
                sortOrderBox.selectedIndex = 0;

            sortIgnoreChange = false;
        }

        /**
         * Builds the Queue Information Display for the InfoBox.
         */
        public function buildInfoBoxQueue():void
        {
            var infoTitle:Text;
            var infoDetails:Text;
            var tY:int = 0;

            // Highlight Tab Button
            optionsBox.getChildAt(1).alpha = 1;

            // Get Song Length
            var songTotalLength:int = 0;
            for (var qS:String in _gvars.songQueue)
            {
                songTotalLength += (_gvars.songQueue[qS] as SongInfo).time_secs;
            }

            infoTitle = new Text(infoBox, 5, tY, _lang.string("song_selection_queue_panel_title"), 14, "#DDDDDD");
            infoTitle.width = 164;
            tY += 32;

            var queueDisplay:Array = [[_lang.string("song_selection_queue_panel_total_songs"), NumberUtil.numberFormat(_gvars.songQueue.length)], [_lang.string("song_selection_queue_panel_total_length"), TimeUtil.convertToHHMMSS(songTotalLength)]];

            for (var queueItem:String in queueDisplay)
            {
                // Info Title
                infoTitle = new Text(infoBox, 5, tY, queueDisplay[queueItem][0], 14, "#DDDDDD");
                infoTitle.width = 164;
                tY += 16;

                // Info Display
                infoDetails = new Text(infoBox, 5, tY, queueDisplay[queueItem][1]);
                infoDetails.width = 164;
                tY += 23;
            }

            var isQueueNotEmpty:Boolean = (options.queuePlaylist.length > 0);
            var isQueueNotAlone:Boolean = (options.queuePlaylist.length > 1);

            // Actions
            var songQueuePlay:BoxButton = new BoxButton(infoBox, 5, 160, 164, 27, _lang.string("song_selection_queue_panel_play"), 12, clickHandler);
            songQueuePlay.action = "playQueue";
            songQueuePlay.enabled = isQueueNotEmpty;

            var songQueuePlayFromHere:BoxButton = new BoxButton(infoBox, 5, 192, 164, 27, _lang.string("song_selection_queue_panel_play_from_here"), 12, clickHandler);
            songQueuePlayFromHere.action = "playQueueFromHere";
            songQueuePlayFromHere.enabled = isQueueNotAlone;

            var songQueueRandomizer:BoxButton = new BoxButton(infoBox, 5, 224, 164, 27, _lang.string("song_selection_queue_panel_randomize"), 12, clickHandler);
            songQueueRandomizer.action = "queueRandomize";
            songQueueRandomizer.enabled = isQueueNotAlone;

            var songQueueManager:BoxButton = new BoxButton(infoBox, 5, 256, 164, 27, _lang.string("song_selection_queue_panel_manager"), 12, clickHandler);
            songQueueManager.action = "queueManager";

            var songQueueSave:BoxButton = new BoxButton(infoBox, 5, 288, 79.5, 27, _lang.string("song_selection_queue_panel_save"), 12, clickHandler);
            songQueueSave.action = "queueSave";
            songQueueSave.enabled = isQueueNotEmpty;

            var songQueueClear:BoxButton = new BoxButton(infoBox, 89.5, 288, 79.5, 27, _lang.string("song_selection_queue_panel_clear"), 12, clickHandler);
            songQueueClear.action = "clearQueue";
            songQueueClear.enabled = isQueueNotEmpty;
        }

        /**
         * Builds the Highscore Display for the InfoBox for the given song.
         */
        public function buildInfoBoxHighscores(songInfo:SongInfo):void
        {
            var infoTitle:Text;
            var infoDetails:Text;
            var infoPAHover:HoverPABox;
            var tY:int = 0;

            infoTitle = new Text(infoBox, 5, tY, _lang.string("song_selection_song_panel_highscores"), 14, "#DDDDDD");
            infoTitle.width = 164;

            // Refresh button
            var refreshBtn:BoxButton = new BoxButton(infoBox, infoBox.width - 19 - 2, 2, 19, 19, "R", 12, refreshHighscoresClick);
            var openBtn:BoxButton = new BoxButton(infoBox, refreshBtn.x - 19 - 2, 2, 19, 19, "O", 12, openHighscoresClick);
            openBtn.songInfo = songInfo;

            var infoRanks:Object = _gvars.activeUser.getLevelRank(songInfo) || {};
            var highscores:Object = _gvars.getHighscores(songInfo.level);
            if (highscores && highscores["1"]) // Check for rank 1 entry.
            {
                var lastRank:int = 0;
                var lastScore:Number = Number.MAX_VALUE;
                tY = 21;
                for (var r:int = 1; r <= 5; r++)
                {
                    if (highscores[r])
                    {
                        var username:String = highscores[r]['username'];
                        var score:Number = highscores[r]['score'];
                        var isMyPB:Boolean = (!_gvars.activeUser.isGuest) && (_gvars.activeUser.name == username);

                        if (score < lastScore)
                        {
                            lastScore = score;
                            lastRank = r;
                        }

                        infoPAHover = new HoverPABox(5, tY, highscores[r]['av']);

                        // Username
                        infoTitle = new Text(infoBox, 5, tY, "<font color=\"#CCCCCC\">#" + lastRank + ":</font> " + username, 14);
                        infoTitle.width = 164;
                        infoTitle.fontColor = isMyPB ? "#D9FF9E" : "#FFFFFF";
                        tY += 16;

                        // Rank
                        infoDetails = new Text(infoBox, 5, tY, NumberUtil.numberFormat(score), 12);
                        infoDetails.width = 164;
                        infoDetails.fontColor = isMyPB ? "#B8D8B3" : "#DDDDDD";
                        tY += 23;

                        // PA Hover Box
                        infoBox.addChild(infoPAHover);
                    }
                }

                infoPAHover = new HoverPABox(5, tY, infoRanks.results);

                // Username
                infoTitle = new Text(infoBox, 5, tY, "#" + infoRanks.rank + ": " + _gvars.activeUser.name, 14, "#D9FF9E");
                infoTitle.width = 164;
                tY += 16;

                // Rank
                infoDetails = new Text(infoBox, 5, tY, NumberUtil.numberFormat(infoRanks.rawscore), 12, "#B8D8B3");
                infoDetails.width = 164;
                tY += 23;

                // PA Hover Box
                infoBox.addChild(infoPAHover);
            }
            else
            {
                var throbber:Throbber = new Throbber();
                throbber.x = 75;
                throbber.y = 122;
                infoBox.addChild(throbber);
                throbber.start();

                _gvars.addEventListener(GlobalVariables.HIGHSCORES_LOAD_COMPLETE, highscoresLoaded);
                _gvars.loadHighscores(songInfo.level);
            }
        }

        /**
         * Builds the Song Details and Information Display for the InfoBox for the given song.
         */
        public function buildInfoBoxSongDetails(songInfo:SongInfo):void
        {
            var infoTitle:Text;
            var infoDetails:Text;
            var infoPAHover:HoverPABox;
            var tY:int = 0;

            var infoRanks:Object = _gvars.activeUser.getLevelRank(songInfo) || {};
            var infoDisplay:Array = [["song", songInfo.name],
                ["author", songInfo.author],
                ["stepfile", songInfo.stepauthor],
                ["length", (songInfo.note_count > 0 ? sprintf(_lang.string("song_selection_song_panel_length_value"), {"time": songInfo.time, "note_count": songInfo.note_count}) : songInfo.time)],
                ["style", songInfo.style],
                ["best", (infoRanks.score > 0 ? "\n" + NumberUtil.numberFormat(infoRanks.score) + "\n" + infoRanks.results : _lang.string("song_selection_song_panel_unplayed"))]];

            // Get User Star Rating
            var starRating:Number = _gvars.playerUser.getSongRating(songInfo);
            if (starRating > 0)
            {
                var ratingDisplay:StarSelector = new StarSelector(infoBox, 109, 5, false);
                ratingDisplay.value = starRating;
                ratingDisplay.scaleX = ratingDisplay.scaleY = 0.4;
                ratingDisplay.alpha = 0.8;
                ratingDisplay.outline = false;
                ratingDisplay.addBackgroundStars();
            }

            // Print Song Info
            for (var item:String in infoDisplay)
            {
                // Info Title
                infoTitle = new Text(infoBox, 5, tY, _lang.string("song_selection_song_panel_" + infoDisplay[item][0]), 14, "#DDDDDD");
                infoTitle.width = 164;
                tY += 16;

                // Info Display
                infoDetails = new Text(infoBox, 5, tY, infoDisplay[item][1] || "");
                infoDetails.width = 164;
                tY += 23;

                if (infoDisplay[item][0] == "best" && infoRanks.results != null)
                {
                    // Get raw goods value to display in the hover
                    var rawGoods:String = NumberUtil.numberFormat(SkillRating.getRawGoods(infoRanks), 1, true);

                    // Get song % played
                    var songPercentageString:String = Math.min(100, Math.max(0, ((infoRanks.perfect + infoRanks.good + infoRanks.average + infoRanks.miss) / songInfo.note_count * 100))).toFixed(2);

                    if (songPercentageString != "0.00")
                    {
                        //Construct the display string (could do this in one go but man it's a long line lol)
                        var hoverString:String = _lang.string("song_selection_song_panel_rghover" + (songPercentageString != "100.00" ? "_unfinished" : ""));

                        // Add raw goods Hover Box
                        infoPAHover = new HoverPABox(5, tY, sprintf(hoverString, {"raw": rawGoods, "percent": songPercentageString}));
                        infoBox.addChild(infoPAHover);
                    }
                }
            }
        }

        /**
         * Add the buttons for Adding to Queue, Highscores, and Play
         */
        public function buildInfoBoxSongActionButtons(songInfo:SongInfo):void
        {
            var accessLevel:int = _gvars.checkSongAccess(songInfo);
            var isCanonEngine:Boolean = !songInfo.engine;
            if (accessLevel == GlobalVariables.SONG_ACCESS_PLAYABLE)
            {
                var buttonWidth:int = isCanonEngine ? 51.5 : 79.5;

                //- Make Display
                var songQueueButton:BoxIcon = new BoxIcon(infoBox, 5, 256, buttonWidth, 27, new iconList(), songQueueClick);
                songQueueButton.level = songInfo.level;
                songQueueButton.setHoverText(_lang.string("song_selection_song_panel_hover_queue"));

                if (isCanonEngine)
                {
                    var songHighscoresButton:BoxIcon = new BoxIcon(infoBox, 5 + buttonWidth + 5, 256, buttonWidth + 1, 27, new iconTrophy(), clickHandler);
                    songHighscoresButton.level = songInfo.level;
                    songHighscoresButton.action = "highscores";
                    songHighscoresButton.setHoverText((options.infoTab == TAB_HIGHSCORES ? _lang.string("song_selection_song_panel_hover_info") : _lang.string("song_selection_song_panel_hover_scores")));
                }

                var songOptionsButton:BoxIcon = new BoxIcon(infoBox, 5 + buttonWidth + 6 + (isCanonEngine ? (buttonWidth + 5) : 0), 256, buttonWidth, 27, new iconGear(), clickHandler);
                songOptionsButton.level = songInfo.level;
                songOptionsButton.action = "songOptions";
                songOptionsButton.setHoverText(_lang.string("song_selection_song_panel_hover_song_options"));

                buttonWidth = 164;
                if (_mp.gameplayCanPick())
                {
                    buttonWidth = 79.5;
                    var songLoadButton:BoxButton = new BoxButton(infoBox, 89.5, 288, 79.5, 27, _lang.string("song_selection_song_panel_mp_load"), 14, songLoadClick);
                    songLoadButton.level = songInfo.level;
                }
                var songStartButton:BoxButton = new BoxButton(infoBox, 5, 288, buttonWidth, 27, _lang.string("song_selection_song_panel_play"), 14, songStartClick);
                songStartButton.level = songInfo.level;
            }
            else
            {
                if (isCanonEngine)
                {
                    var song_price:Number = songInfo.price;
                    if (!isNaN(song_price) && song_price > 0)
                    {
                        var hasEnoughCredits:Boolean = (_gvars.activeUser.credits >= song_price);

                        var purchasedSongButtonLocked:BoxButton = new BoxButton(infoBox, 5, 256, 164, 27, sprintf(_lang.string("song_selection_song_panel_purchase"), {"song_price": song_price}), 12, clickHandler);
                        purchasedSongButtonLocked.song_details = songInfo;
                        purchasedSongButtonLocked.action = "purchase";
                        purchasedSongButtonLocked.enabled = hasEnoughCredits;

                        // Check for existing purchased web request
                        if (purchasedSongButtonLocked.enabled)
                        {
                            for each (var request:WebRequest in purchasedWebRequests)
                            {
                                if (request.level == songInfo.level)
                                {
                                    purchasedSongButtonLocked.enabled = false;
                                    break;
                                }
                            }
                        }

                        // Display message if not enough credits
                        if (!hasEnoughCredits)
                        {
                            var infoPAHover:HoverPABox = new HoverPABox(5, 256, sprintf(_lang.string("song_selection_song_panel_purchase_not_enough"), {"credits": _gvars.activeUser.credits, "price": song_price}));
                            infoPAHover.delay = 50;
                            infoBox.addChild(infoPAHover);
                        }
                    }

                    var songHighscoresButtonLocked:BoxButton = new BoxButton(infoBox, 5, 288, 164, 27, (options.infoTab == TAB_HIGHSCORES ? _lang.string("song_selection_song_panel_info") : _lang.string("song_selection_song_panel_scores")), 12, clickHandler);
                    songHighscoresButtonLocked.level = songInfo.level;
                    songHighscoresButtonLocked.action = "highscores";
                }
            }
        }

        /**
         * Called from Info Box: Adds the active song into the song queue.
         */
        private function songQueueClick(e:Event):void
        {
            Alert.add(sprintf(_lang.string("song_selection_add_to_queue"), {song_name: _playlist.getSongInfo(e.target.level).name}), 90);
            _gvars.songQueue.push(_playlist.getSongInfo(e.target.level));
            saveQueuePlaylist();
            if (options.activeGenre == PLAYLIST_QUEUE)
                buildPlayList();
        }

        /**
         * Called from Info Box: Attempts to begin play of the active song.
         * @param e
         */
        private function songStartClick(e:Event):void
        {
            playSong(e.target.level);
        }

        /**
         * Called from Info Box: Attempts to load a song for multiplayer gameplay.
         * @param e
         */
        private function songLoadClick(e:Event):void
        {
            multiplayerLoad(e.target.level);
        }

        /**
         * Updates the selected multiplayer song and begins loading the song.
         * It also alerts multiplayer to watch for the other players load status to begin gameplay.
         * @param level Level ID of song to load.
         */
        private function multiplayerLoad(level:int):void
        {
            if (level < 0)
                return;

            _mp.gameplayPicking(_playlist.getSongInfo(level));
            _mp.gameplayLoading();
            switchTo(MainMenu.MENU_MULTIPLAYER);
        }

        /**
         * Reset the song queue and adds the provided level to the queue and starts the queue.
         * @param level Level ID to add.
         */
        private function playSong(level:int):void
        {
            if (level < 0)
                return;

            _gvars.songQueue = [];
            var songInfo:SongInfo = _playlist.getSongInfo(level);
            if (songInfo != null)
            {
                _gvars.songQueue.push(songInfo);
                playQueue();
            }
        }

        /**
         * Begins the current queue, while filtering out unplayable songs to prevent issues.
         */
        private function playQueue(queueIndex:int = 0):void
        {
            if (queueIndex < 0)
                return;

            if (queueIndex != 0)
                _gvars.songQueue = _gvars.songQueue.slice(queueIndex);

            _gvars.songQueue = _gvars.songQueue.filter(function(item:SongInfo, index:int, array:Array):Boolean
            {
                return (_gvars.checkSongAccess(item) == GlobalVariables.SONG_ACCESS_PLAYABLE);
            });

            if (_gvars.songQueue.length <= 0)
                return;

            saveSearchTextAndType();

            _gvars.options = new GameOptions();
            _gvars.options.fill();
            switchTo(Main.GAME_PLAY_PANEL);
        }

        /**
         * Does a song search for a matching term on the selected type.
         * Known types are "name", "author", "stepauthor", "style".
         * @param name Search Term
         */
        private function doSearch(search_term:String):void
        {
            var searchTypeParam:String = searchTypeBox.selectedItem["data"];
            options.activeGenre = PLAYLIST_SEARCH;
            options.activeSongId = -1;
            options.activeIndex = -1;
            options.pageNumber = 0;
            options.isFilter = true;
            options.filter = function(songInfo:SongInfo):Boolean
            {
                return songInfo[searchTypeParam].toLowerCase().indexOf(search_term.toLowerCase()) > -1;
            };
            options.scroll_position = 0;

            updateGenreList()
            buildPlayList();
        }

        private function searchTypeSelect(e:Event):void
        {
            options.last_search_type = e.target.selectedItem["data"];
        }

        private function sortTypeSelect(e:Event):void
        {
            if (sortIgnoreChange)
                return;

            options.last_sort_type = e.target.selectedItem["data"];
            buildPlayList();
        }

        private function sortOrderSelect(e:Event):void
        {
            if (sortIgnoreChange)
                return;

            options.last_sort_order = e.target.selectedItem["data"];
            buildPlayList();
        }

        /**
         * Does a specific search for a selected song from a multiplayer lobby.
         * It will use a song object first to make level ids first, and if none
         * given, will look for an exact match on the song name instead.
         * @param songName Song Name
         * @param songInfo SongInfo Object
         */
        public function multiplayerSelect(songName:String, songInfo:SongInfo):void
        {
            saveSearchTextAndType();
            options.activeGenre = PLAYLIST_SEARCH;
            options.activeSongId = (songInfo != null && songInfo.level) ? songInfo.level : -1;
            options.pageNumber = 0;
            options.isFilter = true;
            if (songInfo)
                options.filter = function(_songInfo:SongInfo):Boolean
                {
                    return _songInfo.level == songInfo.level;
                };
            else
                options.filter = function(_songInfo:SongInfo):Boolean
                {
                    return _songInfo.name == songName;
                };
            options.infoTab = TAB_PLAYLIST;
            updateGenreList()
            buildPlayList();
            buildInfoBox();

            for (var i:int = 0; i < songItems.length; i++)
            {
                if (songItems[i].level == options.activeSongId)
                    setActiveIndex(i, -1, true);
            }
        }

        /**
         * Called from Info Box: Clears the loaded highscores entries to allow reloading from the server.
         */
        private function refreshHighscoresClick(e:Event):void
        {
            _gvars.clearHighscores();
            _gvars.activeUser.loadLevelRanks();
            buildInfoBox();
        }

        /**
         * Called from Info Box: Open highscores popup for the song.
         */
        private function openHighscoresClick(e:Event):void
        {
            addPopup(new PopupHighscores(this, e.target.songInfo));
        }

        /**
         * Callback function for when highscores are loaded.
         * @param e unused
         */
        private function highscoresLoaded(e:Event):void
        {
            _gvars.removeEventListener(GlobalVariables.HIGHSCORES_LOAD_COMPLETE, highscoresLoaded);
            buildInfoBox();
        }

        /**
         * Swaps the display between Queue and Playlist
         */
        public function swapToQueue(selectToken:Boolean = true):void
        {
            if (selectToken || options.activeGenre != PLAYLIST_QUEUE)
            {
                options.pageNumber = 0;
                options.activeIndex = -1;
                options.activeSongId = -1;
                options.scroll_position = 0;
            }
            options.activeGenre = (options.infoTab == TAB_QUEUE ? PLAYLIST_QUEUE : 0);
            updateGenreList()
            buildPlayList();
            buildInfoBox();
        }

        /**
         * Resets the filter options.
         */
        private function resetFilterOptions():void
        {
            options.filter = null;
            options.isFilter = false;
        }

        /**
         * Save the search text and type.
         */
        private function saveSearchTextAndType():void
        {
            if (searchBox != null)
                options.last_search_text = searchBox.text;
            if (searchTypeBox != null)
                options.last_search_type = searchTypeBox.selectedItem["data"];
        }

        //******************************************************************************************//
        // Page Related Logic
        //******************************************************************************************//

        /**
         * Draws a series of clickable boxes to provided pagnation to the song selection list.
         * If the current genre is ALL, it then provides pages that are split into chunks.
         */
        public function drawPages():void
        {
            if (pages == null)
            {
                pages = new Sprite();
                pages.addEventListener(MouseEvent.CLICK, pageClicked, false, 0, true);
                this.addChild(pages);
            }

            pages.removeChildren();

            var isBigPage:Boolean = (options.activeGenre <= -1 || GENRE_MODE == GENRE_SONGFLAGS);
            var totalPages:int = getTotalPages(isBigPage);

            // Configure Page Background
            var limit:int = (isBigPage) ? 7 : 18;
            background.pageBackground.x = (totalPages > limit) ? 3 : 32;
            background.pageBackground.width = (totalPages > limit) ? 605 : 545;

            // Draw Page Boxes
            buildPages(totalPages, isBigPage);
        }

        /**
         * Gets the total number of pages for the set genreLength. This number is assumes 12
         * items per page and caps at 20 max pages regardless if more is available.
         * When isBigPage is set, it uses genreLength / ITEM_PER_PAGE to determine page count.
         * @param isBigPage Use Bigger Page Style
         * @return Number of Pages
         */
        private function getTotalPages(isBigPage:Boolean):int
        {
            if (isBigPage)
                return Math.ceil(genreLength / ITEM_PER_PAGE);
            return Math.min(Math.ceil(genreLength / 12), 20);
        }

        /**
         * Generates the page buttons at the bottom of the playlist pane.
         *
         * @param totalPages Page Count
         * @param isBigPage Use Bigger Page Style
         */
        private function buildPages(totalPages:int, isBigPage:Boolean):void
        {
            if (isBigPage && totalPages > 16)
                isBigPage = false;

            var pBox:PageBox;
            var page_width:int = (isBigPage) ? 72 : 27;
            var page_height:int = 16;
            var pages_per_row:int = 600 / (page_width + 3);

            var page_x:Number;
            var page_y:Number;
            var page_scroll:Number;
            var page_str:String;

            for (var pY:int = 0; pY < totalPages; ++pY)
            {
                page_x = (page_width + 3) * (pY % pages_per_row);
                page_y = (page_height + 2) * Math.floor(pY / pages_per_row);
                page_scroll = (pY / (totalPages - 1));
                page_str = (pY + 1).toString();

                if (isBigPage)
                    page_str = ((pY * ITEM_PER_PAGE) + 1) + " - " + (((pY + 1) * ITEM_PER_PAGE) > genreLength ? genreLength : ((pY + 1) * ITEM_PER_PAGE));

                pBox = new PageBox(pages, page_x, page_y);
                pBox.page = pY;
                pBox.page_scroll = page_scroll;
                pBox.setSize(page_width, page_height);
                pBox.setText(page_str);
            }

            pages.x = 145 + ((610 - pages.width) / 2);
            pages.y = pages.height > 26 ? 417 : 424;
        }

        /**
         * Callback for PageBox clicks. Handles either scrolling though the playlist, or
         * swapping pages in the All Genres and Searches.
         * @param e
         */
        private function pageClicked(e:Event = null):void
        {
            if (e.target is PageBox)
            {
                var pagebox:PageBox = (e.target as PageBox);
                var targetPage:Number = pagebox.page;
                if (options.activeGenre <= -1 || GENRE_MODE == GENRE_SONGFLAGS)
                {
                    if (options.pageNumber != targetPage)
                    {
                        options.activeSongId = -1;
                        options.activeIndex = -1;
                        options.pageNumber = targetPage;
                        options.infoTab = TAB_PLAYLIST;
                        buildPlayList();
                        buildInfoBox();
                    }
                }
                else
                {
                    options.scroll_position = pagebox.page_scroll;
                    scrollbar.scrollTo(options.scroll_position);
                    pane.scrollTo(options.scroll_position);
                }
            }
            stage.focus = stage;
        }

        //******************************************************************************************//
        // Event Handlers
        //******************************************************************************************//
        /**
         * General Click Handler for multiple objects.
         * @param e
         */
        private function clickHandler(e:Event):void
        {
            if (e.target == genre_mode_prev || e.target == genre_mode_next)
            {
                resetFilterOptions();
                GENRE_MODE = (GENRE_MODE + (e.target == genre_mode_prev ? -1 : 1));
                if (GENRE_MODE < 0)
                    GENRE_MODE = GENRE_MODES;
                if (GENRE_MODE > GENRE_MODES)
                    GENRE_MODE = 0;
                LocalStore.setVariable("genre_mode", GENRE_MODE);
                options.scroll_position = 0;
                options.activeGenre = 0;
                options.activeIndex = -1;
                options.activeSongId = -1;
                options.infoTab = TAB_PLAYLIST;
                buildGenreList();
                buildPlayList();
                buildInfoBox();
            }
            else if (e.target.action != null)
            {
                var clickAction:String = e.target.action;
                if (clickAction == "search")
                {
                    resetFilterOptions();
                    options.infoTab = (options.infoTab == TAB_SEARCH ? TAB_PLAYLIST : TAB_SEARCH);
                    buildInfoBox();
                    return;
                }
                else if (clickAction == "playQueue")
                {
                    playQueue();
                }
                else if (clickAction == "playQueueFromHere")
                {
                    playQueue(options.activeIndex);
                }
                else if (clickAction == "doSearch")
                {
                    doSearch(searchBox.text);
                }
                else if (clickAction == "queue")
                {
                    options.infoTab = options.infoTab == TAB_QUEUE ? TAB_PLAYLIST : TAB_QUEUE;
                    swapToQueue(false);
                }
                else if (clickAction == "highscores")
                {
                    options.infoTab = (options.infoTab == TAB_PLAYLIST ? TAB_HIGHSCORES : TAB_PLAYLIST);
                    buildInfoBox();
                }
                else if (clickAction == "purchase")
                {
                    var songDetails:Object = e.target.song_details;
                    var purchaseRequest:WebRequest = new WebRequest(URLs.resolve(URLs.SONG_PURCHASE_URL), e_purchaseSongComplete, e_purchaseSongFailure);
                    purchaseRequest.level = songDetails.level;
                    purchaseRequest.load({"level": songDetails.level, "session": _gvars.userSession});
                    purchasedWebRequests.push(purchaseRequest);

                    e.target.enabled = false;
                }
                else if (clickAction == "songOptions")
                {
                    var songInfo:SongInfo = _playlist.getSongInfo(e.target.level);

                    if (songInfo != null)
                        _gvars.gameMain.addPopup(new PopupSongNotes(this, songInfo));
                }
                else if (clickAction == "clearQueue")
                {
                    _gvars.songQueue = [];
                    saveQueuePlaylist();
                    buildPlayList();
                    buildInfoBox();
                }
                else if (clickAction == "queueRandomize")
                {
                    for (var rq:int = 0; rq < 5; rq++)
                    {
                        _gvars.songQueue = ArrayUtil.randomize(_gvars.songQueue);
                    }
                    saveQueuePlaylist();
                    buildPlayList();
                    buildInfoBox();
                }
                else if (clickAction == "queueSave")
                {
                    new Prompt(this, 320, _lang.string("song_selection_song_queue_name_prompt"), 100, "SUBMIT", e_saveSongQueue);
                }
                else if (clickAction == "queueManager")
                {
                    addPopup(new PopupQueueManager(this));
                }
                else if (clickAction == "doFilterRandom")
                {
                    var randomList:Array = songList.filter(function(item:SongInfo, index:int, array:Array):Boolean
                    {
                        return (_gvars.activeFilter ? _gvars.activeFilter.process(item, _gvars.activeUser) : true) && _gvars.checkSongAccess(item) == GlobalVariables.SONG_ACCESS_PLAYABLE;
                    });
                    if (randomList.length > 0)
                    {
                        var random:Object = randomList[int(Math.floor(Math.random() * randomList.length))];
                        if (_mp.gameplayHasOpponent())
                            multiplayerLoad(random.level);
                        else
                            playSong(random.level);
                        return;
                    }
                    else
                    {
                        Alert.add(_lang.string("song_selection_no_songs_random"), 120, Alert.RED);
                    }
                }
            }
            stage.focus = stage;
        }

        /**
         * General Keyboard Key Down Handler for multiple objects.
         * @param e
         */
        private function keyHandler(e:KeyboardEvent):void
        {
            // Don't do anything with popups open.
            if (_gvars.gameMain.current_popup != null)
                return;

            if (searchBox != null && options.infoTab == TAB_SEARCH && searchBox.focus)
            {
                switch (e.keyCode)
                {
                    case Keyboard.ENTER:
                        doSearch(searchBox.text);
                        break;
                }
                return;
            }

            var newIndex:int = options.activeIndex;
            var lastIndex:int = options.activeIndex;
            var maxGenreIndex:int = getTotalGenres() - 1;

            switch (e.keyCode)
            {
                case Keyboard.PAGE_UP:
                    newIndex -= 11;
                    break;

                case Keyboard.UP:
                    newIndex -= 1;
                    break;

                case Keyboard.PAGE_DOWN:
                    newIndex += 11;
                    break;

                case Keyboard.DOWN:
                    newIndex += 1;
                    break;

                case Keyboard.HOME:
                    newIndex = 0;
                    break;

                case Keyboard.END:
                    newIndex = genreLength - 1;
                    break;

                case Keyboard.TAB:
                    resetFilterOptions();
                    options.scroll_position = 0;
                    options.activeIndex = -1;
                    options.activeSongId = -1;
                    options.activeGenre = options.activeGenre + (e.ctrlKey ? -1 : 1);
                    options.infoTab = TAB_PLAYLIST;
                    if (options.activeGenre < -1)
                        options.activeGenre = maxGenreIndex;
                    if (options.activeGenre > maxGenreIndex)
                        options.activeGenre = -1;
                    updateGenreList()
                    buildPlayList();
                    buildInfoBox();
                    return;

                case Keyboard.ENTER:
                    if (!((stage.focus is PushButton) || (stage.focus is TextField)) && options.activeSongId >= 0)
                    {
                        if (_mp.gameplayHasOpponent())
                            multiplayerLoad(options.activeSongId);
                        else
                            playSong(options.activeSongId);
                    }
                    return;

                default:
                    if (!((stage.focus is PushButton) || (stage.focus is TextField)) && ((e.keyCode == Keyboard.BACKSPACE) || (e.keyCode == Keyboard.SPACE) || (e.keyCode >= 48 && e.keyCode <= 111) || (e.keyCode >= 186 && e.keyCode <= 222)))
                    {
                        // Focus on search and begin typing.
                        if (options.infoTab != TAB_SEARCH)
                        {
                            options.infoTab = TAB_SEARCH;
                            buildInfoBox();
                        }
                        stage.focus = searchBox.field;
                    }
                    return;
            }

            if (genreLength == 0)
                return;

            if (newIndex < 0)
                newIndex = 0;
            else if (newIndex > genreLength - 1)
                newIndex = genreLength - 1;

            if (newIndex != lastIndex)
            {
                setActiveIndex(newIndex, lastIndex, true);
                buildInfoBox();
                stage.focus = null;
            }
        }

        /**
         * Mouse Wheel Handler for the Playlist Scroll Pane.
         * Moves the scroll pane based on the scroll delta direction.
         * @param e
         */
        private function mouseWheelHandler(e:MouseEvent):void
        {
            //- Sanity
            if (genreLength == 0 || !scrollbar.draggerVisibility)
                return;

            //- Scroll
            options.scroll_position = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(options.scroll_position);
            scrollbar.scrollTo(options.scroll_position);
        }

        /**
         * Scroll Bar Moved Update Handler for the Playlist Scroll Bar.
         * Updates the scroll pane postion based on the scroll bar position.
         * @param e
         */
        private function scrollBarMoved(e:Event):void
        {
            options.scroll_position = e.target.scroll;
            pane.scrollTo(e.target.scroll);
        }

        /**
         * Callback for saving a song queue.
         * @param subevent
         */
        private function e_saveSongQueue(queueName:String):void
        {
            var songArray:Array = [];
            for (var songQueueI:int = 0; songQueueI < _gvars.songQueue.length; songQueueI++)
            {
                songArray[songArray.length] = _gvars.songQueue[songQueueI].level;
            }
            _gvars.playerUser.songQueues.push(new SongQueueItem(queueName, songArray));
            _gvars.playerUser.save();
        }

        /**
         * Called when a song purchase completes.
         * @param e
         */
        private function e_purchaseSongComplete(e:Event):void
        {
            var level_id:int;

            // Remove Loader and get Level Info
            for each (var pur_loader:WebRequest in purchasedWebRequests)
            {
                if (pur_loader.loader == e.target)
                {
                    level_id = pur_loader.level;
                    purchasedWebRequests.removeAt(purchasedWebRequests.indexOf(pur_loader));
                    break;
                }
            }

            var response:Object = JSON.parse(e.target.data);

            if (response["status"] == 0)
            {
                var songDetails:Object = _playlist.getSongInfo(level_id);
                if (songDetails != null && !songDetails.hasOwnProperty("error"))
                    Alert.add(sprintf(_lang.string("song_purchase_complete"), {"name": songDetails.name}), 120, Alert.DARK_GREEN);

                _gvars.activeUser.setPurchasedString(response["purchased"]);
                _gvars.activeUser.credits = response["credits"];
                _playlist.updateSongAccess();

                buildPlayList();
            }
            else
            {
                Alert.add(_lang.string("song_purchase_error_" + response["status"]), 120, Alert.RED);
            }

            if (options.activeSongId == level_id && options.infoTab == TAB_PLAYLIST)
            {
                buildInfoBox();
            }
        }

        /**
         * Called when a song purchase fails.
         * @param e
         */
        private function e_purchaseSongFailure(e:Event):void
        {
            // Remove Loader and refresh Info Box if active song.
            for each (var pur_loader:WebRequest in purchasedWebRequests)
            {
                if (pur_loader.loader == e.target)
                {
                    if (options.activeSongId == pur_loader.level && options.infoTab == TAB_PLAYLIST)
                    {
                        buildInfoBox();
                    }
                    purchasedWebRequests.removeAt(purchasedWebRequests.indexOf(pur_loader));
                    break;
                }
            }
        }

        //******************************************************************************************//
        // Menu Music
        //******************************************************************************************//

        /**
         * Callback for Menu Music Song when loaded and available.
         */
        private function e_menuMusicConvertSongLoad(e:Event):void
        {
            var song:Song = (e.target as Song);
            song.removeEventListener(Event.COMPLETE, e_menuMusicConvertSongLoad);
            writeMenuMusicBytes(song);
            playMenuMusicSong(song);
        }

        /**
         * Callback for menu song preview when loaded and available.
         */
        private function e_songPreviewConvertSongLoad(e:Event):void
        {
            var song:Song = (e.target as Song);
            song.removeEventListener(Event.COMPLETE, e_songPreviewConvertSongLoad);
            playSongPreview(song);
        }

        /**
         * Begins play of a loaded Song class object.
         * This updates the stored song name, begins music playback
         * and display the song controls.
         * @param song Song Class to set as menu music.
         */
        private function playMenuMusicSong(song:Song):void
        {
            Alert.add(_lang.string("song_selection_playing_menu_music"));

            LocalStore.setVariable("menu_music", song.songInfo.name);
            var par:MainMenu = ((this.my_Parent) as MainMenu);
            par.drawMenuMusicControls();
            par.updateMenuMusicControls();

            if (_gvars.menuMusic)
                _gvars.menuMusic.stop();

            if (previewMusic)
                previewMusic.stop();

            _gvars.menuMusic = new SongPlayerBytes(song.bytesSWF);
            _gvars.menuMusic.start();
        }

        /**
         * Same as playMenuMusicSong, but it plays the song preview without repeat
         * and the song controls aren't drawn.
         */
        private function playSongPreview(song:Song):void
        {
            Alert.add(_lang.string("song_selection_playing_song_preview"));

            if (_gvars.menuMusic)
                _gvars.menuMusic.stop();

            if (previewMusic)
                previewMusic.stop();

            previewMusic = new SongPlayerBytes(song.bytesSWF, false, true);
            previewMusic.start();
        }

        /**
         * Writes the loaded SWF byte data to the fixed menu music file path location.
         * @param song Song Class to save SWF bytes from.
         */
        private function writeMenuMusicBytes(song:Song):void
        {
            AirContext.writeFile(AirContext.getAppFile(Constant.MENU_MUSIC_PATH), song.bytesSWF);
        }
    }
}


import assets.GameBackgroundColor;

import classes.ui.Text;

import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Point;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.utils.Timer;

internal class PageBox extends Sprite
{
    public var page:int;
    public var page_scroll:Number;

    private var page_text:Text;
    private var draw_width:Number = 27;
    private var draw_height:Number = 16;

    public function PageBox(parent:DisplayObjectContainer, x:Number, y:Number):void
    {
        this.x = x;
        this.y = y;

        this.mouseChildren = false;
        this.useHandCursor = true;
        this.buttonMode = true;

        parent.addChild(this);
    }

    public function setSize(w:Number, h:Number):void
    {
        draw_width = w;
        draw_height = h;

        this.graphics.lineStyle(1, 0xFFFFFF, 0.5, false);
        this.graphics.beginFill(GameBackgroundColor.BG_STATIC, 1);
        this.graphics.drawRect(0, 0, draw_width, draw_height);
        this.graphics.endFill();

        if (page_text != null)
        {
            page_text.width = draw_width;
            page_text.height = draw_height - 1;
        }
    }

    public function setText(str:String):void
    {
        if (page_text == null)
        {
            page_text = new Text(this, 0, 0, str, draw_height - 4);
            page_text.width = draw_width;
            page_text.height = draw_height;
            page_text.align = Text.CENTER;
        }
        else
        {
            page_text.text = str;
        }
    }
}

internal class HoverPABox extends Sprite
{
    private var _width:Number;
    private var _height:Number;

    private var _hoverText:String;
    private var _hoverSprite:Sprite;
    private var _hoverSpriteText:TextField;
    private var _hoverTimer:Timer = new Timer(500, 1);

    public function HoverPABox(xpos:Number, ypos:Number, text:String, width:Number = 165, height:Number = 38)
    {
        // No Hover Text, do nothing.
        if (text == null)
            return;

        this._hoverText = text;
        this._width = width;
        this._height = height;
        this.x = xpos;
        this.y = ypos;

        this.mouseChildren = false;

        this.graphics.lineStyle(0, 0, 0);
        this.graphics.beginFill(0, 0);
        this.graphics.drawRect(0, 0, _width, _height);
        this.graphics.endFill();

        this.addEventListener(MouseEvent.ROLL_OVER, e_hoverRollOver);
    }

    public function set delay(val:int):void
    {
        _hoverTimer.delay = val;
    }


    private function e_hoverRollOver(e:MouseEvent):void
    {
        this.addEventListener(MouseEvent.ROLL_OUT, e_hoverRollOut);

        if (this.parent && this.parent.stage)
        {
            drawHoverSprite();
            _hoverTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
            _hoverTimer.start();
        }
    }

    private function e_hoverRollOut(e:MouseEvent):void
    {
        _hoverTimer.stop();
        this.removeEventListener(MouseEvent.ROLL_OUT, e_hoverRollOut);
        this.removeEventListener(Event.ENTER_FRAME, e_onEnterFrame);

        if (_hoverSprite.parent)
            _hoverSprite.parent.removeChild(_hoverSprite);
    }

    private function e_hoverTimerComplete(e:Event):void
    {
        _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);

        var placePoint:Point = new Point(0, -_hoverSprite.height);

        // Center on Label
        placePoint.x = -(_hoverSprite.width / 2) + (width / 2);

        var stagePoint:Point = this.localToGlobal(placePoint);

        // Keep on Stage
        if (stagePoint.x < 5)
            stagePoint.x = 5;

        if (stagePoint.x + _hoverSprite.width > Main.GAME_WIDTH - 5)
            stagePoint.x = Main.GAME_WIDTH - 5 - _hoverSprite.width;

        if (stagePoint.y < 5)
            stagePoint.y = 5;

        if (stagePoint.y + _hoverSprite.height > Main.GAME_HEIGHT - 5)
            stagePoint.y = Main.GAME_HEIGHT - 5 - _hoverSprite.height;

        // Position
        _hoverSprite.x = stagePoint.x;
        _hoverSprite.y = stagePoint.y;

        if (this.parent && this.parent.stage)
        {
            this.parent.stage.addChild(_hoverSprite);
            this.addEventListener(Event.ENTER_FRAME, e_onEnterFrame, false, 0, true);
        }
    }

    private function e_onEnterFrame(e:Event):void
    {
        if (!this.parent || !this.parent.stage)
        {
            this.removeEventListener(Event.ENTER_FRAME, e_onEnterFrame);

            if (_hoverSprite && _hoverSprite.parent)
                _hoverSprite.parent.removeChild(_hoverSprite);
        }
    }

    private function drawHoverSprite():void
    {
        if (!_hoverSprite)
        {
            _hoverSprite = new Sprite();
            _hoverSprite.mouseEnabled = false;
            _hoverSprite.mouseChildren = false;

            _hoverSpriteText = new TextField();
            _hoverSpriteText.x = 4;
            _hoverSpriteText.y = 2;
            _hoverSpriteText.embedFonts = true;
            _hoverSpriteText.selectable = false;
            _hoverSpriteText.mouseEnabled = false;
            _hoverSpriteText.defaultTextFormat = Constant.TEXT_FORMAT;
            _hoverSpriteText.autoSize = TextFieldAutoSize.LEFT;
            _hoverSpriteText.antiAliasType = AntiAliasType.ADVANCED;
            //_hoverSpriteText.border = true;
            _hoverSpriteText.cacheAsBitmap = true;
            _hoverSprite.addChild(_hoverSpriteText);

            _hoverSpriteText.htmlText = _hoverText;

            var minWidth:Number = Math.max(_width, _hoverSpriteText.width + 8);
            _hoverSpriteText.x = (minWidth - _hoverSpriteText.width) / 2;
            _hoverSprite.graphics.lineStyle(1, 0xFFFFFF, 0.5, false);
            _hoverSprite.graphics.beginFill(GameBackgroundColor.BG_DARK, 0.9);
            _hoverSprite.graphics.drawRect(0, 0, minWidth, _hoverSpriteText.height + 4);
            _hoverSprite.graphics.endFill();
        }
    }
}
