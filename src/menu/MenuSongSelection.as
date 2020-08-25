/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerPrompt;
    import arc.mp.MultiplayerSingleton;
    import assets.GameBackgroundColor;
    import assets.menu.GenreSelection;
    import assets.menu.ScrollBackground;
    import assets.menu.ScrollDragger;
    import assets.menu.SongSelectionBackground;
    import assets.menu.icons.fa.iconLeft;
    import assets.menu.icons.fa.iconRight;
    import classes.Alert;
    import classes.BoxButton;
    import classes.BoxText;
    import classes.Language;
    import classes.Playlist;
    import classes.SongPlayerBytes;
    import classes.SongPreview;
    import classes.SongQueueItem;
    import classes.StarSelector;
    import classes.Text;
    import classes.chart.Song;
    import com.bit101.components.ComboBox;
    import com.bit101.components.PushButton;
    import com.flashfla.components.ScrollBar;
    import com.flashfla.components.ScrollPane;
    import com.flashfla.components.Throbber;
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
    import popups.PopupFilterManager;
    import popups.PopupQueueManager;
    import popups.PopupSongNotes;

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

        private var genreDisplay:Sprite;

        private var GENRE_MODE_TEXT:Text;
        private var genre_mode_prev:iconLeft;
        private var genre_mode_next:iconRight;
        private var SELECTED_GENRE_BACKGROUND:Sprite;

        private var background:SongSelectionBackground;
        private var scrollbar:ScrollBar;
        private var pane:ScrollPane;

        private var genreLength:int;
        private var songItems:Vector.<SongItem>;

        private var optionsBox:Sprite;
        private var infoBox:Sprite;
        private var pages:Sprite;
        private var songList:Array;

        private var GENRE_MODE:int = GENRE_DIFFICULTIES;

        // Info Page
        private var searchBox:BoxText;
        private var searchTypeBox:ComboBox;

        public static var options:MenuSongSelectionOptions = new MenuSongSelectionOptions();

        private var songItemContextMenu:ContextMenu;
        private var songItemContextMenuItem:ContextMenuItem;
        private var songItemSongOptionsContext:ContextMenuItem;
        private var songItemRemoveQueueContext:ContextMenuItem;

        public static var previewMusic:SongPlayerBytes;

        ///- Constructor
        public function MenuSongSelection(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            // Load Default Alt Engine
            if (_avars.legacyDefaultEngine && !Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD])
            {
                _avars.configLegacy = _avars.legacyDefaultEngine;
                _playlist.addEventListener(GlobalVariables.LOAD_COMPLETE, _playlist.engineChangeHandler);
                _playlist.addEventListener(GlobalVariables.LOAD_ERROR, e_defaultEngineLoadFail);
                _playlist.load();

                Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD_SKIP] = true;

                var loadTextEngine:Text = new Text("Loading Default Engine, please wait...");
                loadTextEngine.setAreaParams(Main.GAME_WIDTH, 30, Text.CENTER);
                loadTextEngine.y = Main.GAME_HEIGHT / 2 - 15;
                addChild(loadTextEngine);
            }

            Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD] = true;

            if (Flags.VALUES[Flags.LEGACY_ENGINE_DEFAULT_LOAD_SKIP])
                return true;

            //- Add Background
            background = new SongSelectionBackground();
            background.x = 145;
            background.y = 52;
            this.addChild(background);

            GENRE_MODE = LocalStore.getVariable("genre_mode", GENRE_DIFFICULTIES);

            // Menu Music Context Menu
            songItemContextMenu = new ContextMenu();
            songItemContextMenuItem = new ContextMenuItem("Set as Menu Music");
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_setAsMenuMusicContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            songItemContextMenuItem = new ContextMenuItem("Listen to Song Preview");
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_listenToSongPreviewContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            songItemContextMenuItem = new ContextMenuItem("Play Chart Preview");
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_playChartPreviewContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            songItemSongOptionsContext = new ContextMenuItem("Song Options");
            songItemSongOptionsContext.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_songOptionsContextSelect);
            songItemContextMenu.customItems.push(songItemSongOptionsContext);

            songItemRemoveQueueContext = new ContextMenuItem("Remove from Queue");
            songItemRemoveQueueContext.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_removeFromQueueContextSelect);
            songItemContextMenu.customItems.push(songItemRemoveQueueContext);

            draw();

            return true;
        }

        override public function dispose():void
        {
            var i:uint = 0;

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
                pane.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
                pane.dispose();
                pane = null;
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

                GENRE_MODE_TEXT = new Text("Song Flags");
                GENRE_MODE_TEXT.x = 17;
                GENRE_MODE_TEXT.y = 106;
                GENRE_MODE_TEXT.align = Text.CENTER;
                GENRE_MODE_TEXT.width = 109;
                GENRE_MODE_TEXT.fontSize = 16;
                this.addChild(GENRE_MODE_TEXT);

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
            if (optionsBox == null)
            {
                optionsBox = new Sprite();
                optionsBox.x = 559; // 155
                optionsBox.y = 64;
                this.addChild(optionsBox);

                var optionsTexts:Array = [[_lang.string("song_selection_menu_search"), "search"], [_lang.string("song_selection_search"), "queue"]]
                for (var i:int = 0; i < optionsTexts.length; i++)
                {
                    var optionActionBox:BoxButton = new BoxButton(85.5, 27, optionsTexts[i][0], 11);
                    optionActionBox.x = (i * 88.5);
                    optionActionBox.action = optionsTexts[i][1];
                    optionActionBox.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    optionsBox.addChild(optionActionBox);
                }
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
                pane = new ScrollPane(401, 351);
                pane.x = 155; // 332
                pane.y = 64;
                pane.graphics.lineStyle(1, 0xFFFFFF, 0.35, false);
                pane.graphics.moveTo(0, 0);
                pane.graphics.lineTo(401, 0);
                pane.graphics.moveTo(0, 350);
                pane.graphics.lineTo(401, 350);
                pane.addEventListener(MouseEvent.CLICK, songItemClicked, false, 0, true);
                pane.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler, false, 0, true);
                this.addChild(pane);
            }

            //- Add ScrollBar
            if (scrollbar == null)
            {
                scrollbar = new ScrollBar(21, 325, new ScrollDragger(), new ScrollBackground());
                scrollbar.x = 744;
                scrollbar.y = 81;
                scrollbar.addEventListener(Event.CHANGE, scrollBarMoved, false, 0, true);
                this.addChild(scrollbar);
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
         * General builder for the Genre left sidebar display.
         */
        public function buildGenreList():void
        {
            genreDisplay.removeChildren();

            // Set Genre Text
            GENRE_MODE_TEXT.text = _lang.string("genre_mode_" + GENRE_MODE);

            //- Build Genre List
            var totalGenres:int = getTotalGenres();

            var genre_text:String;
            var genre_index:int;
            var position_index:int = -1;
            var gap:Number = (GENRE_MODE == GENRE_SONGFLAGS) ? (337 / (Math.max(12, totalGenres) + 1)) : (337 / (totalGenres + 1));
            var y:Number;
            var isActiveGenre:Boolean;

            for (genre_index = -1; genre_index < totalGenres; ++genre_index)
            {
                // If displaying genres, and Legacy Genre isisn't displayed, skip it.
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

                isActiveGenre = (options.activeGenre == genre_index);
                genre_text = getGenreText(genre_index);
                y = gap * position_index;

                // Set Selected Background
                if (isActiveGenre)
                {
                    genreDisplay.addChild(SELECTED_GENRE_BACKGROUND);
                    SELECTED_GENRE_BACKGROUND.y = y - 2;
                }

                // Add Text
                buildGenreEntry(genre_text, isActiveGenre, y, genre_index);
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
                return "PLAYED";

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
         * Creates the Genre Text and also sets the selected background if it is the active genre.
         * @param genre_text Display Text
         * @param isActiveGenre
         * @param y
         * @param gindex Genre Index
         */
        private function buildGenreEntry(text:String, isActiveGenre:Boolean, y:Number, gindex:int):void
        {
            var songGenre:Text = new Text(text, (isActiveGenre ? 18 : 14));
            songGenre.height = 22.6;
            songGenre.width = 130.75;
            songGenre.y = y;
            songGenre.mouseChildren = false;
            songGenre.useHandCursor = true;
            songGenre.buttonMode = true;
            songGenre.index = gindex;
            genreDisplay.addChild(songGenre);
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
                options.activeSongID = -1;
                options.scroll_position = 0;

                resetFilterOptions();

                buildGenreList();
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
            songItems = new Vector.<SongItem>();

            scrollbar.reset();
            pane.clear();

            //- Init Variables
            var i:uint;
            var yOffset:int = 0;
            var song:Array;
            var sI:SongItem;

            //- Set Song array based on selected genre
            // DM_QUEUE
            if (options.activeGenre == PLAYLIST_QUEUE)
            {
                _gvars.songQueue = options.queuePlaylist;
                songList = _gvars.songQueue.slice(options.pageNumber * ITEM_PER_PAGE, (options.pageNumber + 1) * ITEM_PER_PAGE);
                genreLength = _gvars.songQueue.length;
            }

            // DM_SEARCH
            else if (options.activeGenre == PLAYLIST_SEARCH)
            {
                // Doing search, build array based on case-insensitive match
                if (options.isFilter)
                {
                    songList = _playlist.indexList.filter(filterSongListOptionsFilter);

                    genreLength = songList.length;
                    songList = songList.slice(options.pageNumber * ITEM_PER_PAGE, (options.pageNumber + 1) * ITEM_PER_PAGE);
                }
            }

            // DM_ALL
            else if (options.activeGenre == PLAYLIST_ALL)
            {
                songList = _playlist.indexList;

                // Song List Filters
                songList = filterSongListLegacy(songList);
                songList = filterSongListUser(songList);

                // List Length and Slice into pages.
                genreLength = songList.length;
                songList = songList.slice(options.pageNumber * ITEM_PER_PAGE, (options.pageNumber + 1) * ITEM_PER_PAGE);
            }

            // STANDARD_DISPLAY
            else
            {
                if (GENRE_MODE == GENRE_DIFFICULTIES)
                {
                    // Difficulty Filter
                    if (options.activeGenre == _gvars.DIFFICULTY_RANGES.length - 1)
                    {
                        songList = _playlist.indexList.filter(filterSongListDifficultyMax);
                    }
                    else
                    {
                        songList = _playlist.indexList.filter(filterSongListDifficultyRange);
                    }

                    // Song List Filters
                    songList = filterSongListLegacy(songList);
                    songList = filterSongListUser(songList);

                    // Sort and get List Length
                    songList.sortOn(["access", "difficulty", "name"], [Array.NUMERIC, Array.NUMERIC, Array.CASEINSENSITIVE]);
                    genreLength = songList.length;
                }
                else if (GENRE_MODE == GENRE_SONGFLAGS)
                {
                    // Song Flag Filter
                    songList = _playlist.indexList.filter(filterSongListSongFlags);

                    // Song List Filters
                    songList = filterSongListLegacy(songList);
                    songList = filterSongListUser(songList);

                    // Sort, List Length, and Slice into pages.
                    songList.sortOn(["access", "difficulty", "name"], [Array.NUMERIC, Array.NUMERIC, Array.CASEINSENSITIVE]);
                    genreLength = songList.length;
                    songList = songList.slice(options.pageNumber * ITEM_PER_PAGE, (options.pageNumber + 1) * ITEM_PER_PAGE);
                }
                else
                {
                    songList = _playlist.genreList[options.activeGenre + 1];
                    genreLength = songList ? songList.length : 0;
                }
            }

            songItemRemoveQueueContext.visible = options.activeGenre == PLAYLIST_QUEUE;

            //- Pages
            drawPages();

            //- Sanity
            if (songList == null || songList.length <= 0)
            {
                options.activeIndex = -1;
                options.activeSongID = -1;
                return;
            }

            // User Filter
            if (options.activeGenre != PLAYLIST_ALL && options.infoTab != TAB_QUEUE)
            {
                songList = filterSongListUser(songList);
                genreLength = songList.length;
            }

            //- Build Playlist
            for (var sX:int = 0; sX < songList.length; sX++)
            {
                song = songList[sX];
                sI = new SongItem();
                sI.setData(song, _gvars.activeUser.getLevelRank(song));
                sI.setContextMenu(songItemContextMenu);
                sI.y = yOffset;
                sI.index = sX;
                songItems[songItems.length] = sI;
                pane.content.addChild(sI);
                yOffset += sI.height + 2;
            }

            // Scroll Position
            pane.scrollTo(options.scroll_position, false);
            scrollbar.scrollTo(options.scroll_position, false);

            scrollbar.draggerVisibility = (yOffset > pane.height);

            //- Update Selected Index
            // No song items to select, bail.
            if (songList.length <= 0)
                return;

            // Find and select last active song id.
            var hasSelected:Boolean = false;
            for (sX = 0; sX < songList.length; sX++)
            {
                song = songList[sX];
                if (options.activeSongID == song.level)
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
                options.activeSongID = -1;
            }

            // No song selected, select the first in the list if valid.
            if (options.activeIndex == -1)
            {
                setActiveIndex(0, -1, false, false);
            }
        }

        /**
         * Array filter for difficulty ranges. This one handles everything at and above the top range and the special case for difficulty 0.
         */
        private function filterSongListDifficultyMax(item:Object, index:int, array:Array):Boolean
        {
            return item.difficulty <= 0 || item.difficulty >= _gvars.DIFFICULTY_RANGES[options.activeGenre][0];
        }

        /**
         * Array filter for difficulty ranges. This one handles the range between two difficulty points.
         */
        private function filterSongListDifficultyRange(item:Object, index:int, array:Array):Boolean
        {
            return item.difficulty >= _gvars.DIFFICULTY_RANGES[options.activeGenre][0] && item.difficulty <= _gvars.DIFFICULTY_RANGES[options.activeGenre][1];
        }

        /**
         * Array filter for song flags.
         */
        private function filterSongListSongFlags(item:Object, index:int, array:Array):Boolean
        {
            return GlobalVariables.getSongIconIndex(item, _gvars.activeUser.getLevelRank(item)) == options.activeGenre;
        }

        /**
         * Array filter for options.filter
         */
        private function filterSongListOptionsFilter(item:Object, index:int, array:Array):Boolean
        {
            return options.filter(item);
        }

        /**
         * Process the legacy filter on the given song list if enabled.
         * @param songList Song List Array for Song objects to filter.
         */
        private function filterSongListLegacy(songList:Array):Array
        {
            if (!_playlist.engine && !_gvars.activeUser.DISPLAY_LEGACY_SONGS)
            {
                songList = songList.filter(filterSongListLegacyFilter);
            }

            return songList;
        }

        /**
         * Array filter for filterSongListLegacy.
         */
        private function filterSongListLegacyFilter(item:Object, index:int, array:Array):Boolean
        {
            return item.genre != Constant.LEGACY_GENRE;
        }

        /**
         * Process the user filter on the given song list if enabled.
         * @param songList Song List Array for Song objects to filter.
         */
        private function filterSongListUser(songList:Array):Array
        {
            if (_gvars.activeFilter != null)
            {
                songList = songList.filter(filterSongListUserFilter);
            }
            return songList;
        }

        /**
         * Array filter for filterSongListUser.
         */
        private function filterSongListUserFilter(item:Object, index:int, array:Array):Boolean
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
                options.activeSongID = -1;
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
            options.activeSongID = songItems[index].level;

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
            if (mpUpdate && options.activeSongID != -1)
                _mp.gameplayPicking(_playlist.getSong(options.activeSongID));
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
                tarSongItem.e_onClick(e);
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
            if (!_gvars.options)
            {
                _gvars.options = new GameOptions();
                _gvars.options.fill();
            }
            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            var songData:Object = _playlist.getSong(songItem.level);
            if (songData.error == null)
            {
                _gvars.gameMain.addPopup(new PopupSongNotes(this, songData));
            }
        }

        /**
         * Song Item Context Menu: Sets the interacted song as the current menu music.
         * This handles loading the music in the background if not already loaded,
         * or sets the music from the already loaded copy if available.
         * @param e
         */
        private function e_setAsMenuMusicContextSelect(e:ContextMenuEvent):void
        {
            if (!_gvars.options)
            {
                _gvars.options = new GameOptions();
                _gvars.options.fill();
            }
            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            var songData:Object = _playlist.getSong(songItem.level);
            if (songData.error == null)
            {
                var song:Song = _gvars.getSongFile(songData);
                if (song.isLoaded)
                {
                    writeMenuMusicBytes(song);
                    playMenuMusicSong(song);
                }
                else
                {
                    _gvars.gameMain.addAlert("Loading Music for \"" + songData["name"] + "\"", 90);
                    song.addEventListener(Event.COMPLETE, e_menuMusicConvertSongLoad);
                }
            }
        }

        /**
         * Song Item Context Menu: Plays the chart preview of the selected song.
         */
        private function e_playChartPreviewContextSelect(e:ContextMenuEvent):void
        {
            if (!_gvars.options)
            {
                _gvars.options = new GameOptions();
                _gvars.options.fill();
            }
            _gvars.options.replay = new SongPreview((e.contextMenuOwner as SongItem).level);
            _gvars.options.loadPreview = true;

            if (!_gvars.options.replay.isLoaded)
            {
                (_gvars.options.replay as SongPreview).setupSongPreview();
            }

            if (_gvars.options.replay.isLoaded)
            {
                // Setup Vars
                _gvars.songQueue = [];
                _gvars.songQueue.push(Playlist.instance.getSong(_gvars.options.replay.level));

                // Switch to game
                _gvars.gameMain.addAlert("Playing chart preview...");
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
            if (!_gvars.options)
            {
                _gvars.options = new GameOptions();
                _gvars.options.fill();
            }
            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            var songData:Object = _playlist.getSong(songItem.level);
            if (songData.error == null)
            {
                var song:Song = _gvars.getSongFile(songData);
                if (song.isLoaded)
                {
                    playSongPreview(song);
                }
                else
                {
                    _gvars.gameMain.addAlert("Loading Music for \"" + songData["name"] + "\"", 90);
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
            var songDetails:Object = _playlist.getSong(options.activeSongID);

            //- Cleanup old Info Box
            infoBox.removeChildren();

            //- Sanity
            if (songDetails.error != null && options.infoTab != TAB_QUEUE && options.infoTab != TAB_SEARCH)
                return;

            //- Build Info Box
            // Song Search
            if (options.infoTab == TAB_SEARCH)
                buildInfoBoxSearch()

            // Playlist Queue
            else if (options.infoTab == TAB_QUEUE)
                buildInfoBoxQueue();

            // Song Ranks
            else if (options.infoTab == TAB_HIGHSCORES)
                buildInfoBoxHighscores(songDetails);

            // Song Details
            else
                buildInfoBoxSongDetails(songDetails);

            // Action Buttons for Songs
            if (options.infoTab == TAB_PLAYLIST || options.infoTab == TAB_HIGHSCORES)
                buildInfoBoxSongActionButtons(songDetails);

            // For search, set focus on search box:
            if (options.infoTab == TAB_SEARCH)
                stage.focus = searchBox.field;
        }

        /**
         * Builds Search Display for the InfoBox.
         */
        public function buildInfoBoxSearch():void
        {
            // Highlight Tab Button
            optionsBox.getChildAt(0).alpha = 1;

            // Search Box
            if (searchBox == null)
            {
                searchBox = new BoxText(164, 27);
                searchBox.x = 5;
                searchBox.y = 5;
            }
            infoBox.addChild(searchBox);

            // Search Type
            if (searchTypeBox == null)
            {
                searchTypeBox = new ComboBox(null, 5, 37, "", [{label: "Song Name", data: "name"}, {label: "Author", data: "author"}, {label: "Stepauthor", data: "stepauthor"}, {label: "Style", data: "style"}]);
                searchTypeBox.setSize(164, 25);
                searchTypeBox.selectedIndex = 0;
                searchTypeBox.fontSize = 11;
            }
            infoBox.addChild(searchTypeBox);

            // Save Search Parameters
            if (options.last_search_text != null)
            {
                searchBox.text = options.last_search_text;
                searchBox.field.setSelection(searchBox.field.length, searchBox.field.length);
                options.last_search_text = null;
            }

            // Saved Search Type
            if (options.last_search_type != null)
            {
                searchTypeBox.selectedItemByData = options.last_search_type;
                options.last_search_type = null;
            }

            var searchBtn:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_search_panel_search"));
            searchBtn.x = 5;
            searchBtn.y = 67;
            searchBtn.action = "doSearch";
            searchBtn.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(searchBtn);

            var randomButton:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_filter_panel_random"));
            randomButton.x = 5;
            randomButton.y = 256;
            randomButton.action = "doFilterRandom";
            randomButton.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(randomButton);

            var filterQueueManager:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_filter_panel_manager"));
            filterQueueManager.x = 5;
            filterQueueManager.y = 288;
            filterQueueManager.action = "filterManager";
            filterQueueManager.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(filterQueueManager);
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
                songTotalLength += _gvars.songQueue[qS].timeSecs;
            }

            infoTitle = new Text(_lang.string("song_selection_queue_panel_title"), 14, "#DDDDDD");
            infoTitle.x = 5;
            infoTitle.y = tY;
            infoTitle.width = 164;
            infoBox.addChild(infoTitle);
            tY += 32;

            var queueDisplay:Array = [[_lang.string("song_selection_queue_panel_total_songs"), NumberUtil.numberFormat(_gvars.songQueue.length)], [_lang.string("song_selection_queue_panel_total_length"), TimeUtil.convertToHHMMSS(songTotalLength)]];

            for (var queueItem:String in queueDisplay)
            {
                // Info Title
                infoTitle = new Text(queueDisplay[queueItem][0], 14, "#DDDDDD");
                infoTitle.x = 5;
                infoTitle.y = tY;
                infoTitle.width = 164;
                infoBox.addChild(infoTitle);
                tY += 16;

                // Info Display
                infoDetails = new Text(queueDisplay[queueItem][1]);
                infoDetails.x = 5;
                infoDetails.y = tY;
                infoDetails.width = 164;
                infoBox.addChild(infoDetails);
                tY += 23;
            }

            // Actions
            var songQueuePlay:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_queue_panel_play"), 12);
            songQueuePlay.x = 5;
            songQueuePlay.y = 160;
            songQueuePlay.action = "playQueue";
            songQueuePlay.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(songQueuePlay);

            var songQueuePlayFromHere:BoxButton = new BoxButton(164, 27, "PLAY FROM HERE", 12);
            songQueuePlayFromHere.x = 5;
            songQueuePlayFromHere.y = 192;
            songQueuePlayFromHere.action = "playQueueFromHere";
            songQueuePlayFromHere.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(songQueuePlayFromHere);

            var songQueueRandomizer:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_queue_panel_randomize"), 12);
            songQueueRandomizer.x = 5;
            songQueueRandomizer.y = 224;
            songQueueRandomizer.action = "queueRandomize";
            songQueueRandomizer.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(songQueueRandomizer);

            var songQueueManager:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_queue_panel_manager"), 12);
            songQueueManager.x = 5;
            songQueueManager.y = 256;
            songQueueManager.action = "queueManager";
            songQueueManager.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(songQueueManager);

            var songQueueSave:BoxButton = new BoxButton(79.5, 27, _lang.string("song_selection_queue_panel_save"), 12);
            songQueueSave.x = 5;
            songQueueSave.y = 288;
            songQueueSave.action = "queueSave";
            songQueueSave.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(songQueueSave);

            var songQueueClear:BoxButton = new BoxButton(79.5, 27, _lang.string("song_selection_queue_panel_clear"), 12);
            songQueueClear.x = 89.5;
            songQueueClear.y = 288;
            songQueueClear.action = "clearQueue";
            songQueueClear.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
            infoBox.addChild(songQueueClear);
        }

        /**
         * Builds the Highscore Display for the InfoBox for the given song.
         * @param songDetails Song Object
         */
        public function buildInfoBoxHighscores(songDetails:Object):void
        {
            var infoTitle:Text;
            var infoDetails:Text;
            var infoPAHover:HoverPABox;
            var tY:int = 0;

            infoTitle = new Text(_lang.string("song_selection_song_panel_highscores"), 14, "#DDDDDD");
            infoTitle.x = 5;
            infoTitle.y = tY;
            infoTitle.width = 164;
            infoBox.addChild(infoTitle);

            // Refresh button
            var refreshBtn:BoxButton = new BoxButton(19, 19, "R");
            refreshBtn.x = infoBox.width - refreshBtn.width - 2;
            refreshBtn.y = 2;
            refreshBtn.addEventListener(MouseEvent.CLICK, refreshHighscoresClick, false, 0, true);
            infoBox.addChild(refreshBtn);

            var infoRanks:Object = _gvars.activeUser.getLevelRank(songDetails) || {};
            var highscores:Object = _gvars.getHighscores(songDetails.level);
            if (highscores && highscores["1"]) // Check for rank 1 entry.
            {
                var lastRank:int = 0;
                var lastScore:Number = Number.MAX_VALUE;
                tY = 21;
                for (var r:int = 1; r <= 5; r++)
                {
                    if (highscores[r])
                    {
                        var username:String = highscores[r]['name'];
                        var score:Number = highscores[r]['score'];
                        var isMyPB:Boolean = (!_gvars.activeUser.isGuest) && (_gvars.activeUser.name == username);

                        if (score < lastScore)
                        {
                            lastScore = score;
                            lastRank = r;
                        }

                        infoPAHover = new HoverPABox(5, tY, highscores[r]['av']);

                        // Username
                        infoTitle = new Text("#" + lastRank + ": " + username, 14);
                        infoTitle.x = 5;
                        infoTitle.y = tY;
                        infoTitle.width = 164;
                        infoTitle.fontColor = isMyPB ? "#D9FF9E" : "#FFFFFF";
                        infoBox.addChild(infoTitle);
                        tY += 16;

                        // Rank
                        infoDetails = new Text(NumberUtil.numberFormat(score), 12);
                        infoDetails.x = 5;
                        infoDetails.y = tY;
                        infoDetails.width = 164;
                        infoDetails.fontColor = isMyPB ? "#B8D8B3" : "#DDDDDD";
                        infoBox.addChild(infoDetails);
                        tY += 23;

                        // PA Hover Box
                        infoBox.addChild(infoPAHover);
                    }
                }

                infoPAHover = new HoverPABox(5, tY, infoRanks.results);

                // Username
                infoTitle = new Text("#" + infoRanks.rank + ": " + _gvars.activeUser.name, 14, "#D9FF9E");
                infoTitle.x = 5;
                infoTitle.y = tY;
                infoTitle.width = 164;
                infoBox.addChild(infoTitle);
                tY += 16;

                // Rank
                infoDetails = new Text(NumberUtil.numberFormat(infoRanks.rawscore), 12, "#B8D8B3");
                infoDetails.x = 5;
                infoDetails.y = tY;
                infoDetails.width = 164;
                infoBox.addChild(infoDetails);
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
                _gvars.loadHighscores(songDetails.level);
            }
        }

        /**
         * Builds the Song Details and Information Display for the InfoBox for the given song.
         * @param songDetails Song Object
         */
        public function buildInfoBoxSongDetails(songDetails:Object):void
        {
            var infoTitle:Text;
            var infoDetails:Text;
            var tY:int = 0;

            var infoRanks:Object = _gvars.activeUser.getLevelRank(songDetails) || {};
            var infoDisplay:Array = [["song", songDetails['name']],
                ["author", songDetails['author']],
                ["stepfile", songDetails['stepauthor']],
                ["length", (songDetails['arrows'] > 0 ? sprintf(_lang.string("song_selection_song_panel_length_value"), {"time": songDetails['time'], "note_count": songDetails['arrows']}) : songDetails['time'])],
                ["style", songDetails['style']],
                ["best", (infoRanks.score > 0 ? "\n" + NumberUtil.numberFormat(infoRanks.score) + "\n" + infoRanks.results : _lang.string("song_selection_song_panel_unplayed"))]];

            if (songDetails['song_rating'])
            {
                var ratingDisplay:StarSelector = new StarSelector(false);
                ratingDisplay.x = 169;
                ratingDisplay.y = 5;
                ratingDisplay.value = songDetails['song_rating'];
                ratingDisplay.rotation = 90;
                ratingDisplay.scaleX = ratingDisplay.scaleY = 0.60;
                infoBox.addChild(ratingDisplay);
            }
            for (var item:String in infoDisplay)
            {
                // Info Title
                infoTitle = new Text(_lang.string("song_selection_song_panel_" + infoDisplay[item][0]), 14, "#DDDDDD");
                infoTitle.x = 5;
                infoTitle.y = tY;
                infoTitle.width = 164;
                infoBox.addChild(infoTitle);
                tY += 16;

                // Info Display
                infoDetails = new Text(infoDisplay[item][1]);
                infoDetails.x = 5;
                infoDetails.y = tY;
                infoDetails.width = 164;
                infoBox.addChild(infoDetails);
                tY += 23;
            }
        }

        /**
         * Add the buttons for Adding to Queue, Highscores, and Play
         */
        public function buildInfoBoxSongActionButtons(songDetails:Object):void
        {
            var accessLevel:int = _gvars.checkSongAccess(songDetails);

            if (accessLevel == GlobalVariables.SONG_ACCESS_PLAYABLE)
            {
                var hasHighscores:Boolean = !songDetails.engine;

                //- Make Display
                var songQueueButton:BoxButton = new BoxButton(hasHighscores ? 79.5 : 164, 27, _lang.string("song_selection_song_panel_queue"), 12);
                songQueueButton.x = 5;
                songQueueButton.y = 256;
                songQueueButton.level = songDetails.level;
                songQueueButton.addEventListener(MouseEvent.CLICK, songQueueClick, false, 0, true);
                infoBox.addChild(songQueueButton);

                if (hasHighscores)
                {
                    var songHighscoresButton:BoxButton = new BoxButton(79.5, 27, (options.infoTab == TAB_HIGHSCORES ? _lang.string("song_selection_song_panel_info") : _lang.string("song_selection_song_panel_scores")), 12);
                    songHighscoresButton.x = 89.5;
                    songHighscoresButton.y = 256;
                    songHighscoresButton.level = songDetails.level;
                    songHighscoresButton.action = "highscores";
                    songHighscoresButton.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                    infoBox.addChild(songHighscoresButton);
                }

                var songStartWidth:Number = 164;
                if (_mp.gameplayCanPick())
                {
                    songStartWidth = 79.5;
                    var songLoadButton:BoxButton = new BoxButton(79.5, 27, _lang.string("song_selection_song_panel_mp_load"), 14);
                    songLoadButton.x = 89.5;
                    songLoadButton.y = 288;
                    songLoadButton.level = songDetails.level;
                    songLoadButton.addEventListener(MouseEvent.CLICK, songLoadClick, false, 0, true);
                    infoBox.addChild(songLoadButton);
                }
                var songStartButton:BoxButton = new BoxButton(songStartWidth, 27, _lang.string("song_selection_song_panel_play"), 14);
                songStartButton.x = 5;
                songStartButton.y = 288;
                songStartButton.level = songDetails.level;
                songStartButton.addEventListener(MouseEvent.CLICK, songStartClick, false, 0, true);
                infoBox.addChild(songStartButton);
            }
            else
            {
                var songHighscoresButtonLocked:BoxButton = new BoxButton(164, 27, (options.infoTab == TAB_HIGHSCORES ? _lang.string("song_selection_song_panel_info") : _lang.string("song_selection_song_panel_scores")), 12);
                songHighscoresButtonLocked.x = 5;
                songHighscoresButtonLocked.y = 288;
                songHighscoresButtonLocked.level = songDetails.level;
                songHighscoresButtonLocked.action = "highscores";
                songHighscoresButtonLocked.addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
                infoBox.addChild(songHighscoresButtonLocked);
            }
        }

        /**
         * Called from Info Box: Adds the active song into the song queue.
         */
        private function songQueueClick(e:Event):void
        {
            _gvars.gameMain.addAlert(sprintf(_lang.string("song_selection_add_to_queue"), {song_name: _playlist.getSong(e.target.level).name}), 90);
            _gvars.songQueue.push(_playlist.getSong(e.target.level));
            saveQueuePlaylist();
            if (songList == _gvars.songQueue)
            {
                options.infoTab = TAB_QUEUE;
                buildPlayList();
                options.infoTab = TAB_PLAYLIST;
                buildInfoBox();
            }
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

            _mp.gameplayPicking(_playlist.getSong(level));
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
            var songData:Object = _playlist.getSong(level);
            if (songData.error == null)
            {
                _gvars.songQueue.push(songData);
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

            _gvars.songQueue = _gvars.songQueue.filter(function(item:Object, index:int, array:Array):Boolean
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
            options.activeSongID = -1;
            options.activeIndex = -1;
            options.pageNumber = 0;
            options.isFilter = true;
            options.filter = function(song:Object):Boolean
            {
                return song[searchTypeParam].toLowerCase().indexOf(search_term.toLowerCase()) > -1;
            };
            options.scroll_position = 0;

            buildGenreList();
            buildPlayList();
        }

        /**
         * Does a specific search for a selected song from a multiplayer lobby.
         * It will use a song object first to make level ids first, and if none
         * given, will look for an exact match on the song name instead.
         * @param songName Song Name
         * @param song Song Object
         */
        public function multiplayerSelect(songName:String, song:Object):void
        {
            saveSearchTextAndType();
            options.activeGenre = PLAYLIST_SEARCH;
            options.activeSongID = (song != null && song.level != null) ? song.level : -1;
            options.pageNumber = 0;
            options.isFilter = true;
            if (song)
                options.filter = function(fsong:Object):Boolean
                {
                    return fsong.level == song.level;
                };
            else
                options.filter = function(fsong:Object):Boolean
                {
                    return fsong.name == songName;
                };
            options.infoTab = TAB_PLAYLIST;
            buildGenreList();
            buildPlayList();
            buildInfoBox();

            for (var i:int = 0; i < songItems.length; i++)
            {
                if (songItems[i].level == options.activeSongID)
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
                options.activeSongID = -1;
                options.scroll_position = 0;
            }
            options.activeGenre = (options.infoTab == TAB_QUEUE ? PLAYLIST_QUEUE : 0);
            buildGenreList();
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
                pages.y = 424;
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
                {
                    page_str = ((pY * ITEM_PER_PAGE) + 1) + " - " + (((pY + 1) * ITEM_PER_PAGE) > genreLength ? genreLength : ((pY + 1) * ITEM_PER_PAGE));
                }

                pBox = new PageBox(pages, page_x, page_y);
                pBox.page = pY;
                pBox.page_scroll = page_scroll;
                pBox.setSize(page_width, page_height);
                pBox.setText(page_str);
            }

            pages.x = 145 + ((610 - pages.width) / 2);
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
                        options.activeSongID = -1;
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
                options.activeSongID = -1;
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
                    var prompt:MultiplayerPrompt = new MultiplayerPrompt(this, "Song Queue Name");
                    prompt.move(Main.GAME_WIDTH / 2 - prompt.width / 2, Main.GAME_HEIGHT / 2 - prompt.height / 2);
                    prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, e_saveSongQueue);
                    prompt.addEventListener(Event.CLOSE, e_closeSongQueuePrompt);
                }
                else if (clickAction == "queueManager")
                {
                    addPopup(new PopupQueueManager(this));
                }
                else if (clickAction == "filterManager")
                {
                    addPopup(new PopupFilterManager(this));
                }
                else if (clickAction == "doFilterRandom")
                {
                    var randomList:Array = songList.filter(function(item:Object, index:int, array:Array):Boolean
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
                        _gvars.gameMain.addAlert("No possible songs to choose from...", 120, Alert.RED);
                    }
                }
            }
            stage.focus = stage;
        }

        /**
         * Callback for saving a song queue.
         * @param subevent
         */
        private function e_saveSongQueue(subevent:Object):void
        {
            if (subevent.params.value.length > 0)
            {
                var songArray:Array = [];
                for (var songQueueI:int = 0; songQueueI < _gvars.songQueue.length; songQueueI++)
                {
                    songArray[songArray.length] = _gvars.songQueue[songQueueI].level;
                }
                _gvars.playerUser.songQueues.push(new SongQueueItem(subevent.params.value, songArray));
                _gvars.playerUser.save();
            }
        }

        /**
         * Callback for closing the prompt for saving a song queue.
         * @param e
         */
        private function e_closeSongQueuePrompt(e:Event):void
        {
            var prompt:MultiplayerPrompt = (e.target as MultiplayerPrompt);
            prompt.removeEventListener(MultiplayerPrompt.EVENT_SEND, e_saveSongQueue);
            prompt.removeEventListener(Event.CLOSE, e_closeSongQueuePrompt);
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

                case Keyboard.TAB:
                    resetFilterOptions();
                    options.scroll_position = 0;
                    options.activeIndex = -1;
                    options.activeSongID = -1;
                    options.activeGenre = options.activeGenre + (e.ctrlKey ? -1 : 1);
                    options.infoTab = TAB_PLAYLIST;
                    if (options.activeGenre < -1)
                        options.activeGenre = maxGenreIndex;
                    if (options.activeGenre > maxGenreIndex)
                        options.activeGenre = -1;
                    buildGenreList();
                    buildPlayList();
                    buildInfoBox();
                    return;

                case Keyboard.ENTER:
                    if (!((stage.focus is PushButton) || (stage.focus is TextField)) && options.activeSongID >= 0)
                    {
                        if (_mp.gameplayHasOpponent())
                            multiplayerLoad(options.activeSongID);
                        else
                            playSong(options.activeSongID);
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
            _gvars.gameMain.addAlert("Playing menu music...");

            LocalStore.setVariable("menu_music", song.entry.name);
            var par:MainMenu = ((this.my_Parent) as MainMenu);
            if (par.menuMusicControls)
                ((par.menuMusicControls.contextMenu as ContextMenu).customItems[0] as ContextMenuItem).caption = "Now Playing: " + song.entry.name;

            if (_gvars.menuMusic)
                _gvars.menuMusic.stop();

            if (previewMusic)
                previewMusic.stop();

            _gvars.menuMusic = new SongPlayerBytes(song.bytesSWF);
            _gvars.menuMusic.start();
            par.drawMenuMusicControls();
        }

        /**
         * Same as playMenuMusicSong, but it plays the song preview without repeat
         * and the song controls aren't drawn.
         */
        private function playSongPreview(song:Song):void
        {
            _gvars.gameMain.addAlert("Playing song preview...");

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
            AirContext.writeFile(AirContext.getAppPath(Constant.MENU_MUSIC_PATH), song.bytesSWF);
        }
    }
}


import assets.GameBackgroundColor;

import classes.Text;

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
            page_text = new Text(str, draw_height - 4);
            page_text.width = draw_width;
            page_text.height = draw_height;
            page_text.align = Text.CENTER;
            this.addChild(page_text);
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
    private var _hoverTimer:Timer = new Timer(650, 1);

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
