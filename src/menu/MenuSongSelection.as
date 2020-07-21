/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import arc.ArcGlobals;
    import arc.mp.MultiplayerPrompt;
    import arc.mp.MultiplayerSingleton;
    import assets.GameBackgroundColor;
    import assets.menu.*;
    import classes.*;
    import classes.chart.Song;
    import com.bit101.components.ComboBox;
    import com.bit101.components.PushButton;
    import com.flashfla.components.*;
    import com.flashfla.utils.ArrayUtil;
    import com.flashfla.utils.NumberUtil;
    import com.flashfla.utils.TimeUtil;
    import com.flashfla.utils.sprintf;
    import flash.display.*;
    import flash.events.*;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.ui.Keyboard;
    import game.GameOptions;
    import popups.PopupFilterManager;
    import popups.PopupQueueManager;
    import popups.PopupSongNotes;

    public class MenuSongSelection extends MenuPanel
    {
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

        private var genrelist:Sprite;
        private var genrelistItems:Array; // Vector.<Text>;
        private var genreLength:int;
        private var genre_mode_prev:Sprite;
        private var genre_mode_next:Sprite;
        private var SELECTED_GENRE_BACKGROUND:Sprite;
        private var GENRE_MODE_TEXT:Text;

        private var background:SongSelectionBackground;
        private var scrollbar:ScrollBar;
        private var pane:ScrollPane;
        private var songItems:Vector.<SongItem>;
        private var optionsBox:Sprite;
        private var infoBox:Sprite;
        private var info:Sprite;
        private var pages:Sprite;
        private var songList:Array;

        private var GENRE_MODE:int = GENRE_DIFFICULTIES;

        // Info Page
        private var searchBox:BoxText;
        private var searchTypeBox:ComboBox;

        public var options:Object;

        private var songItemContextMenu:ContextMenu;
        private var songItemContextMenuItem:ContextMenuItem;
        private var removeFromQueueCMItemIndex:int = 1;
        private var isQueuePlaylist:Boolean = false;

        ///- Constructor
        public function MenuSongSelection(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
        {
            // Load Default Alt Engine
            if (_avars.legacyDefaultEngine && !_gvars.tempFlags['legacy_engine_default_load'])
            {
                _avars.configLegacy = _avars.legacyDefaultEngine;
                _playlist.addEventListener(GlobalVariables.LOAD_COMPLETE, _playlist.engineChangeHandler);
                _playlist.addEventListener(GlobalVariables.LOAD_ERROR, e_defaultEngineLoadFail);
                _playlist.load();
                _gvars.tempFlags['legacy_engine_default_load_skip'] = true;

                var loadTextEngine:Text = new Text("Loading Default Engine, please wait...");
                loadTextEngine.setAreaParams(Main.GAME_WIDTH, 30, Text.CENTER);
                loadTextEngine.y = Main.GAME_HEIGHT / 2 - 15;
                addChild(loadTextEngine);
            }
            _gvars.tempFlags['legacy_engine_default_load'] = true;
            if (_gvars.tempFlags['legacy_engine_default_load_skip'])
                return true;

            //- Setup Options
            options = new Object();
            options.activeGenre = 0;
            options.activeIndex = -1;
            options.activeSongID = -1;
            options.pageNumber = 0;
            options.infoTab = 0;
            options.isFilter = false;
            options.filter = '';

            //- Add Background
            background = new SongSelectionBackground();
            background.x = 145;
            background.y = 52;
            this.addChild(background);

            GENRE_MODE = LocalStore.getVariable("genre_mode", GENRE_DIFFICULTIES);

            if (_gvars.tempFlags['genre_mode_temp'] != null)
            {
                GENRE_MODE = _gvars.tempFlags['genre_mode_temp'];
            }
            if (_gvars.tempFlags['active_genre_temp'] != null)
            {
                options.activeGenre = _gvars.tempFlags['active_genre_temp'];
            }
            if (_gvars.tempFlags['active_index_temp'] != null)
            {
                options.activeIndex = _gvars.tempFlags['active_index_temp'];
            }
            if (_gvars.tempFlags['active_songid_temp'] != null)
            {
                options.activeSongID = _gvars.tempFlags['active_songid_temp'];
            }
            if (_gvars.tempFlags['active_isfilter_temp'] != null)
            {
                options.isFilter = _gvars.tempFlags['active_isfilter_temp'];
            }
            if (_gvars.tempFlags['active_filter_temp'] != null)
            {
                options.filter = _gvars.tempFlags['active_filter_temp'];
                if (_gvars.tempFlags['active_tab_temp'] != null)
                {
                    options.infoTab = _gvars.tempFlags['active_tab_temp'];
                }
            }

            // Menu Music Context Menu
            songItemContextMenu = new ContextMenu();
            songItemContextMenuItem = new ContextMenuItem("Set as Menu Music");
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_setAsMenuMusicContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            if (_gvars.sql_connect)
            {
                songItemContextMenuItem = new ContextMenuItem("Song Options");
                songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_songOptionsContextSelect);
                songItemContextMenu.customItems.push(songItemContextMenuItem);
                removeFromQueueCMItemIndex = 2;
            }

            songItemContextMenuItem = new ContextMenuItem("Remove from Queue");
            songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_removeFromQueueContextSelect);
            songItemContextMenu.customItems.push(songItemContextMenuItem);

            draw();

            return true;
        }

        private function e_defaultEngineLoadFail(e:Event):void
        {
            _playlist.engineChangeHandler(e);
            switchTo(MainMenu.MENU_SONGSELECTION, true);
        }

        override public function dispose():void
        {
            var i:uint = 0;

            songItems = null;

            for (i = 0; i < genrelistItems.length; i++)
            {
                genrelistItems[i].dispose();
                genrelistItems[i].removeEventListener(MouseEvent.CLICK, songItemClicked);
                genrelistItems[i] = null;
            }
            genrelistItems = null;
            if (infoBox)
            {
                this.removeChild(infoBox);
                infoBox = null;
            }
            if (pane)
            {
                pane.clear();
                pane.removeEventListener(MouseEvent.CLICK, songItemClicked);
                pane.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
                pane.dispose();
                this.removeChild(pane);
                pane = null;
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
            if (genrelist == null)
            {
                genrelist = new Sprite();
                genrelist.x = 5;
                genrelist.y = 135;
                this.addChild(genrelist);

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

                genre_mode_prev = new Sprite();
                genre_mode_prev.x = 10;
                genre_mode_prev.y = 112;
                genre_mode_prev.buttonMode = true;
                genre_mode_prev.useHandCursor = true;
                genre_mode_prev.graphics.lineStyle(1, 0xffffff, 0.85);
                genre_mode_prev.graphics.beginFill(0xffffff, 0.5);
                genre_mode_prev.graphics.moveTo(7, 0);
                genre_mode_prev.graphics.lineTo(7, 12);
                genre_mode_prev.graphics.lineTo(0, 6);
                genre_mode_prev.graphics.lineTo(7, 0);
                genre_mode_prev.graphics.endFill();
                genre_mode_prev.addEventListener(MouseEvent.CLICK, clickHandler);
                this.addChild(genre_mode_prev);

                genre_mode_next = new Sprite();
                genre_mode_next.x = 121;
                genre_mode_next.y = 112;
                genre_mode_next.buttonMode = true;
                genre_mode_next.useHandCursor = true;
                genre_mode_next.graphics.lineStyle(1, 0xffffff, 0.85);
                genre_mode_next.graphics.beginFill(0xffffff, 0.5);
                genre_mode_next.graphics.moveTo(0, 0);
                genre_mode_next.graphics.lineTo(8, 6);
                genre_mode_next.graphics.lineTo(0, 13);
                genre_mode_next.graphics.lineTo(0, 0);
                genre_mode_next.graphics.endFill();
                genre_mode_next.addEventListener(MouseEvent.CLICK, clickHandler);
                this.addChild(genre_mode_next);
            }

            //- Add Selection Options
            if (optionsBox != null)
            {
                this.removeChild(optionsBox);
                optionsBox = null;
            }
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
                var border:Sprite = new Sprite();
                border.graphics.lineStyle(1, 0xFFFFFF, 1, false);
                border.graphics.lineTo(401, 0);
                border.graphics.moveTo(0, 350);
                border.graphics.lineTo(401, 350);
                border.alpha = 0.35;
                pane.addChild(border);
                pane.addEventListener(MouseEvent.CLICK, songItemClicked);
                pane.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
                this.addChild(pane);
            }

            //- Add ScrollBar
            if (scrollbar == null)
            {
                scrollbar = new ScrollBar(21, 325, new ScrollDragger(), new ScrollBackground());
                scrollbar.x = 744;
                scrollbar.y = 81;
                this.addChild(scrollbar);
            }

            //- Build Content
            buildGenreList();
            buildPlayList();
            buildInfoTab();
        }

        override public function stageAdd():void
        {
            if (_gvars.tempFlags['legacy_engine_default_load_skip'])
            {
                _gvars.tempFlags['legacy_engine_default_load_skip'] = null;
                return;
            }

            //- Add Listeners
            if (stage)
            {
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler, false, 0, true);
                scrollbar.addEventListener(Event.CHANGE, scrollBarMoved, false, 0, true);
            }
        }

        override public function stageRemove():void
        {
            //- Remove Listeners
            if (stage)
            {
                stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyHandler, false);
                if (scrollbar)
                    scrollbar.removeEventListener(Event.CHANGE, scrollBarMoved, false);
            }
        }

        public function buildGenreList():void
        {
            // Clear Old Items
            if (genrelistItems)
            {
                if (genrelist.contains(SELECTED_GENRE_BACKGROUND))
                    genrelist.removeChild(SELECTED_GENRE_BACKGROUND);
                for (var i:uint = 0; i < genrelistItems.length; i++)
                {
                    genrelist.removeChild(genrelistItems[i]);
                    genrelistItems[i].dispose();
                    genrelistItems[i].removeEventListener(MouseEvent.CLICK, songItemClicked);
                    genrelistItems[i] = null;
                }
            }

            // Set Genre Text
            GENRE_MODE_TEXT.text = _lang.string("genre_mode_" + GENRE_MODE);

            //- Build Genre List
            genrelistItems = []; // new Vector.<Text>;
            var genre_text:String;
            var gindex:int;
            var gposy:int = -1;
            var separation:Number;
            var y:Number;
            var isActiveGenre:Boolean;

            const totalGenres:int = getTotalGenres();
            for (gindex = -1; gindex < totalGenres; ++gindex)
            {
                if (GENRE_MODE == GENRE_GENRES)
                {
                    if (!_gvars.activeUser.DISPLAY_LEGACY_SONGS && !_playlist.engine && gindex == (Constant.LEGACY_GENRE - 1))
                        continue;
                    ++gposy;
                }
                else
                {
                    gposy = gindex + 1;
                }

                genre_text = getGenreText(gindex);
                isActiveGenre = (options.activeGenre == gindex);
                separation = (GENRE_MODE == GENRE_SONGFLAGS) ? (337 / (Math.max(12, totalGenres) + 1)) : (337 / (totalGenres + 1));
                y = separation * gposy;

                buildGenreEntry(genre_text, isActiveGenre, y, gindex);
            }
        }

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
            // DM_SEARCH
            if (options.activeGenre == -2)
            {
                // Doing search, build array based on case-insensitive match
                if (options.isFilter)
                {
                    songList = _playlist.indexList.filter(function(item:Object, index:int, array:Array):Boolean
                    {
                        return options.filter(item);
                    });

                    // Legacy Filter
                    if (!_playlist.engine)
                    {
                        songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return item.genre == Constant.LEGACY_GENRE ? _gvars.activeUser.DISPLAY_LEGACY_SONGS : true;
                        });
                    }

                    genreLength = songList.length;
                    songList = songList.slice(options.pageNumber * 500, (options.pageNumber + 1) * 500);
                }

                // Queued Song List
                if (options.infoTab == TAB_QUEUE)
                {
                    songList = _gvars.songQueue;
                    songList = songList.slice(options.pageNumber * 500, (options.pageNumber + 1) * 500);
                    genreLength = _gvars.songQueue.length;
                }
            }

            // DM_ALL
            else if (options.activeGenre == -1)
            {
                songList = _playlist.indexList;

                // Legacy Filter
                if (!_playlist.engine && !_gvars.activeUser.DISPLAY_LEGACY_SONGS)
                {
                    songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                    {
                        return item.genre != Constant.LEGACY_GENRE;
                    });
                }

                // User Filter
                if (_gvars.activeFilter != null)
                {
                    songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                    {
                        return _gvars.activeFilter.process(item, _gvars.activeUser);
                    });
                }
                genreLength = songList.length;
                songList = songList.slice(options.pageNumber * 500, (options.pageNumber + 1) * 500);
            }

            // STANDARD_DISPLAY
            else
            {
                if (GENRE_MODE == GENRE_DIFFICULTIES)
                {
                    if (options.activeGenre == _gvars.DIFFICULTY_RANGES.length - 1)
                    {
                        songList = _playlist.indexList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return item.difficulty <= 0 || item.difficulty >= _gvars.DIFFICULTY_RANGES[options.activeGenre][0];
                        });
                    }
                    else
                    {
                        songList = _playlist.indexList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return item.difficulty >= _gvars.DIFFICULTY_RANGES[options.activeGenre][0] && item.difficulty <= _gvars.DIFFICULTY_RANGES[options.activeGenre][1];
                        });
                    }

                    // Legacy Filter
                    if (!_playlist.engine && !_gvars.activeUser.DISPLAY_LEGACY_SONGS)
                    {
                        songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return item.genre != Constant.LEGACY_GENRE;
                        });
                        genreLength = songList.length;
                    }

                    // User Filter
                    if (_gvars.activeFilter != null)
                    {
                        songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return _gvars.activeFilter.process(item, _gvars.activeUser);
                        });
                    }
                    songList.sortOn(["access", "difficulty", "name"], [Array.NUMERIC, Array.NUMERIC, Array.CASEINSENSITIVE]);
                    genreLength = songList.length;
                }
                else if (GENRE_MODE == GENRE_SONGFLAGS)
                {
                    songList = _playlist.indexList.filter(function(item:Object, index:int, array:Array):Boolean
                    {
                        return GlobalVariables.getSongIconIndex(item, _gvars.activeUser.getLevelRank(item)) == options.activeGenre;
                    });

                    // Legacy Filter
                    if (!_playlist.engine && !_gvars.activeUser.DISPLAY_LEGACY_SONGS)
                    {
                        songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return item.genre != Constant.LEGACY_GENRE;
                        });
                    }

                    // User Filter
                    if (_gvars.activeFilter != null)
                    {
                        songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return _gvars.activeFilter.process(item, _gvars.activeUser);
                        });
                    }
                    songList.sortOn(["access", "difficulty", "name"], [Array.NUMERIC, Array.NUMERIC, Array.CASEINSENSITIVE]);
                    genreLength = songList.length;
                    songList = songList.slice(options.pageNumber * 500, (options.pageNumber + 1) * 500);
                }
                else
                {
                    songList = _playlist.genreList[options.activeGenre + 1];
                    genreLength = songList ? songList.length : 0;
                }
            }

            //- Sanity
            if (songList == null || songList.length <= 0)
                return;

            // User Filter
            if (_gvars.activeFilter != null && options.activeGenre != -1 && options.infoTab != TAB_QUEUE)
            {
                songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                {
                    return _gvars.activeFilter.process(item, _gvars.activeUser);
                });
                genreLength = songList.length;
            }

            // Refresh the queue playlist if we're viewing it right now
            if (isQueuePlaylist)
            {
                songList = _gvars.songQueue;
                genreLength = songList.length;
            }

            drawPages();

            //- Build Playlist
            songItemContextMenu.customItems[removeFromQueueCMItemIndex].visible = isQueuePlaylist;
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

            // Scroll to last song
            if (_gvars.tempFlags['scroll_dist_temp'] != null)
            {
                var dist:Number = _gvars.tempFlags['scroll_dist_temp'];
                pane.scrollTo(dist, false);
                scrollbar.scrollTo(dist, false);
            }
            // Init scroll
            else
            {
                pane.scrollTo(scrollbar.scroll, false);
            }

            scrollbar.draggerVisibility = (yOffset > pane.height);

            // Set Active ID if it's not set
            if (options.activeSongID == -1)
            {
                setActiveID(0, false);
            }
        }

        public function drawPages():void
        {
            // Remove pages
            if (pages != null)
            {
                this.removeChild(pages);
                pages = null;
            }

            pages = new Sprite();
            pages.y = 424;

            var isBigPage:Boolean = (options.activeGenre <= -1 || GENRE_MODE == GENRE_SONGFLAGS);
            var totalPages:int = getTotalPages(isBigPage);

            configurePageBackground(totalPages, isBigPage);
            buildPages(totalPages, isBigPage);
        }

        public function buildInfoTab():void
        {
            // Deselect Buttons
            for (var bti:int = 0; bti < optionsBox.numChildren; bti++)
                optionsBox.getChildAt(bti).alpha = 0.75;

            // Get Song Details
            if (options.activeSongID == -1)
            {
                setActiveID(0, false);
            }
            var songDetails:Object = _playlist.getSong(options.activeSongID);

            //- Cleanup old Info Box
            if (info != null)
            {
                infoBox.removeChild(info);
                info = null;
            }

            //- Sanity
            if (songDetails.error != null && options.infoTab != TAB_QUEUE && options.infoTab != TAB_SEARCH)
                return;

            //- Build Info Box
            info = new Sprite();

            var infoRanks:Object;
            var songInfoTitle:Text;
            var songInfoDetails:Text;
            var tY:int = 0;

            // Song Search
            if (options.infoTab == TAB_SEARCH)
            {
                optionsBox.getChildAt(0).alpha = 1;
                if (searchBox == null)
                {
                    searchBox = new BoxText(164, 27);
                    searchBox.y = 5;
                }
                info.addChild(searchBox);

                // save search parameters
                if (_gvars.tempFlags['active_search_temp'] != null)
                {
                    searchBox.text = _gvars.tempFlags['active_search_temp'];
                    searchBox.field.setSelection(searchBox.field.length, searchBox.field.length); // caret at end of text
                        //searchBox.field.setSelection(0, searchBox.field.length); // select all text
                }

                if (searchTypeBox == null)
                {
                    searchTypeBox = new ComboBox(null, 0, 37, "", [{label: "Song Name", data: "name"}, {label: "Author", data: "author"}, {label: "Stepauthor", data: "stepauthor"}, {label: "Style", data: "style"}]);
                    searchTypeBox.setSize(164, 25);
                    searchTypeBox.selectedIndex = 0;
                    searchTypeBox.fontSize = 11;
                }
                info.addChild(searchTypeBox);

                if (_gvars.tempFlags['active_search_type_temp'] != null)
                {
                    searchTypeBox.selectedItemByData = _gvars.tempFlags['active_search_type_temp'];
                }

                var searchBtn:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_search_panel_search"));
                searchBtn.y = 67;
                searchBtn.action = "doSearch";
                searchBtn.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(searchBtn);

                var randomButton:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_filter_panel_random"));
                randomButton.action = "doFilterRandom";
                randomButton.y = 256;
                randomButton.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(randomButton);

                var filterQueueManager:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_filter_panel_manager"));
                filterQueueManager.y = 288;
                filterQueueManager.action = "filterManager";
                filterQueueManager.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(filterQueueManager);

            }

            // Playlist Queue
            else if (options.infoTab == TAB_QUEUE)
            {
                optionsBox.getChildAt(1).alpha = 1;
                // Get Song Length
                var songTotalLength:int = 0;
                for (var qS:String in _gvars.songQueue)
                {
                    songTotalLength += _gvars.songQueue[qS].timeSecs;
                }
                songInfoTitle = new Text(_lang.string("song_selection_queue_panel_title"), 14, "#DDDDDD");
                songInfoTitle.x = 0;
                songInfoTitle.y = tY;
                songInfoTitle.width = 164;
                info.addChild(songInfoTitle);
                tY += 32;

                var queueDisplay:Array = [[_lang.string("song_selection_queue_panel_total_songs"), NumberUtil.numberFormat(_gvars.songQueue.length)], [_lang.string("song_selection_queue_panel_total_length"), TimeUtil.convertToHHMMSS(songTotalLength)]];

                for (var queueItem:String in queueDisplay)
                {
                    // Info Title
                    songInfoTitle = new Text(queueDisplay[queueItem][0], 14, "#DDDDDD");
                    songInfoTitle.x = 0;
                    songInfoTitle.y = tY;
                    songInfoTitle.width = 164;
                    info.addChild(songInfoTitle);
                    tY += 16;

                    // Info Display
                    songInfoDetails = new Text(queueDisplay[queueItem][1]);
                    songInfoDetails.x = 0;
                    songInfoDetails.y = tY;
                    songInfoDetails.width = 164;
                    info.addChild(songInfoDetails);
                    tY += 23;
                }

                // Actions
                var songQueuePlay:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_queue_panel_play"), 12);
                songQueuePlay.y = 192;
                songQueuePlay.action = "playQueue";
                songQueuePlay.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(songQueuePlay);

                var songQueueRandomizer:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_queue_panel_randomize"), 12);
                songQueueRandomizer.y = 224;
                songQueueRandomizer.action = "queueRandomize";
                songQueueRandomizer.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(songQueueRandomizer);

                var songQueueManager:BoxButton = new BoxButton(164, 27, _lang.string("song_selection_queue_panel_manager"), 12);
                songQueueManager.y = 256;
                songQueueManager.action = "queueManager";
                songQueueManager.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(songQueueManager);

                var songQueueSave:BoxButton = new BoxButton(79.5, 27, _lang.string("song_selection_queue_panel_save"), 12);
                songQueueSave.y = 288;
                songQueueSave.action = "queueSave";
                songQueueSave.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(songQueueSave);

                var songQueueClear:BoxButton = new BoxButton(79.5, 27, _lang.string("song_selection_queue_panel_clear"), 12);
                songQueueClear.x = 84.5;
                songQueueClear.y = 288;
                songQueueClear.action = "clearQueue";
                songQueueClear.addEventListener(MouseEvent.CLICK, clickHandler);
                info.addChild(songQueueClear);
            }

            // Song Ranks
            else if (options.infoTab == TAB_HIGHSCORES)
            {
                songInfoTitle = new Text(_lang.string("song_selection_song_panel_highscores"), 14, "#DDDDDD");
                songInfoTitle.x = 0;
                songInfoTitle.y = tY;
                songInfoTitle.width = 164;
                info.addChild(songInfoTitle);

                // Refresh button
                var refreshBtn:BoxButton = new BoxButton(19, 19, "R");
                refreshBtn.x = info.width - refreshBtn.width + 2;
                refreshBtn.y = 2;
                refreshBtn.addEventListener(MouseEvent.CLICK, refreshHighscoresClick);
                info.addChild(refreshBtn);

                infoRanks = _gvars.activeUser.getLevelRank(songDetails);
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

                            // Username
                            songInfoTitle = new Text("#" + lastRank + ": " + username, 14);
                            songInfoTitle.x = 0;
                            songInfoTitle.y = tY;
                            songInfoTitle.width = 164;
                            songInfoTitle.fontColor = isMyPB ? "#D9FF9E" : "#FFFFFF";
                            info.addChild(songInfoTitle);
                            tY += 16;

                            // Rank
                            songInfoDetails = new Text(NumberUtil.numberFormat(score), 12);
                            songInfoDetails.x = 0;
                            songInfoDetails.y = tY;
                            songInfoDetails.width = 164;
                            songInfoDetails.fontColor = isMyPB ? "#B8D8B3" : "#DDDDDD";
                            info.addChild(songInfoDetails);
                            tY += 23;
                        }
                    }
                    // Username
                    songInfoTitle = new Text("#" + infoRanks.rank + ": " + _gvars.activeUser.name, 14, "#D9FF9E");
                    songInfoTitle.x = 0;
                    songInfoTitle.y = tY;
                    songInfoTitle.width = 164;
                    info.addChild(songInfoTitle);
                    tY += 16;

                    // Rank
                    songInfoDetails = new Text(NumberUtil.numberFormat(infoRanks.rawscore), 12, "#B8D8B3");
                    songInfoDetails.x = 0;
                    songInfoDetails.y = tY;
                    songInfoDetails.width = 164;
                    info.addChild(songInfoDetails);
                    tY += 23;
                }
                else
                {
                    var throbber:Throbber = new Throbber();
                    throbber.x = 70;
                    throbber.y = 122;
                    info.addChild(throbber);
                    throbber.start();

                    _gvars.addEventListener(GlobalVariables.HIGHSCORES_LOAD_COMPLETE, highscoresLoaded);
                    _gvars.loadHighscores(songDetails.level);
                }
            }

            // Song Details
            else
            {
                infoRanks = _gvars.activeUser.getLevelRank(songDetails) || {};
                var infoDisplay:Array = [[_lang.string("song_selection_song_panel_song"), songDetails['name']],
                    [_lang.string("song_selection_song_panel_author"), songDetails['author']],
                    [_lang.string("song_selection_song_panel_stepfile"), songDetails['stepauthor']],
                    [_lang.string("song_selection_song_panel_length"), songDetails['time']],
                    [_lang.string("song_selection_song_panel_style"), songDetails['style']],
                    [_lang.string("song_selection_song_panel_best"), (infoRanks.score > 0 ? "\n" + NumberUtil.numberFormat(infoRanks.score) + "\n" + infoRanks.results : _lang.string("song_selection_song_panel_unplayed"))]];

                if (songDetails['song_rating'])
                {
                    var ratingDisplay:StarSelector = new StarSelector(false);
                    ratingDisplay.x = 164;
                    ratingDisplay.y = 5;
                    ratingDisplay.value = songDetails['song_rating'];
                    ratingDisplay.rotation = 90;
                    ratingDisplay.scaleX = ratingDisplay.scaleY = 0.60;
                    info.addChild(ratingDisplay);
                }
                for (var item:String in infoDisplay)
                {
                    // Info Title
                    songInfoTitle = new Text(infoDisplay[item][0], 14, "#DDDDDD");
                    songInfoTitle.x = 0;
                    songInfoTitle.y = tY;
                    songInfoTitle.width = 164;
                    info.addChild(songInfoTitle);
                    tY += 16;

                    // Info Display
                    songInfoDetails = new Text(infoDisplay[item][1]);
                    songInfoDetails.x = 0;
                    songInfoDetails.y = tY;
                    songInfoDetails.width = 164;
                    info.addChild(songInfoDetails);
                    tY += 23;
                }
            }

            if (options.infoTab == TAB_PLAYLIST || options.infoTab == TAB_HIGHSCORES)
            {
                var accessLevel:int = _gvars.checkSongAccess(songDetails);

                if (accessLevel == GlobalVariables.SONG_ACCESS_PLAYABLE)
                {
                    var hasHighscores:Boolean = !songDetails.engine;

                    //- Make Display
                    var songQueueButton:BoxButton = new BoxButton(hasHighscores ? 79.5 : 164, 27, _lang.string("song_selection_song_panel_queue"), 12);
                    songQueueButton.y = 256;
                    songQueueButton.level = songDetails.level;
                    songQueueButton.addEventListener(MouseEvent.CLICK, songQueueClick);
                    info.addChild(songQueueButton);

                    if (hasHighscores)
                    {
                        var songHighscoresButton:BoxButton = new BoxButton(79.5, 27, (options.infoTab == TAB_HIGHSCORES ? _lang.string("song_selection_song_panel_info") : _lang.string("song_selection_song_panel_scores")), 12);
                        songHighscoresButton.x = 84.5;
                        songHighscoresButton.y = 256;
                        songHighscoresButton.level = songDetails.level;
                        songHighscoresButton.action = "highscores";
                        songHighscoresButton.addEventListener(MouseEvent.CLICK, clickHandler);
                        info.addChild(songHighscoresButton);
                    }

                    var songStartWidth:Number = 164;
                    if (_mp.gameplayCanPick())
                    {
                        songStartWidth = 79.5;
                        var songLoadButton:BoxButton = new BoxButton(79.5, 27, _lang.string("song_selection_song_panel_mp_load"), 14);
                        songLoadButton.y = 288;
                        songLoadButton.x = 84.5;
                        songLoadButton.level = songDetails.level;
                        songLoadButton.addEventListener(MouseEvent.CLICK, songLoadClick);
                        info.addChild(songLoadButton);
                    }
                    var songStartButton:BoxButton = new BoxButton(songStartWidth, 27, _lang.string("song_selection_song_panel_play"), 14);
                    songStartButton.y = 288;
                    songStartButton.level = songDetails.level;
                    songStartButton.addEventListener(MouseEvent.CLICK, songStartClick);
                    info.addChild(songStartButton);
                }
                else
                {
                    var songHighscoresButtonLocked:BoxButton = new BoxButton(164, 27, (options.infoTab == TAB_HIGHSCORES ? _lang.string("song_selection_song_panel_info") : _lang.string("song_selection_song_panel_scores")), 12);
                    songHighscoresButtonLocked.y = 288;
                    songHighscoresButtonLocked.level = songDetails.level;
                    songHighscoresButtonLocked.action = "highscores";
                    songHighscoresButtonLocked.addEventListener(MouseEvent.CLICK, clickHandler);
                    info.addChild(songHighscoresButtonLocked);
                }
            }

            //- Add to box.
            info.x = 5;
            infoBox.addChild(info);

            // For search, set focus on search box:
            if (options.infoTab == TAB_SEARCH)
                stage.focus = searchBox.field;
        }

        private function highscoresLoaded(e:Event):void
        {
            _gvars.removeEventListener(GlobalVariables.HIGHSCORES_LOAD_COMPLETE, highscoresLoaded);
            buildInfoTab();
        }

        private function clickHandler(e:Event):void
        {
            if (e.target == genre_mode_prev || e.target == genre_mode_next)
            {
                clearSearchStateParams();
                GENRE_MODE = (GENRE_MODE + (e.target == genre_mode_prev ? -1 : 1));
                if (GENRE_MODE < 0)
                    GENRE_MODE = GENRE_MODES;
                if (GENRE_MODE > GENRE_MODES)
                    GENRE_MODE = 0;
                _gvars.tempFlags['genre_mode_temp'] = GENRE_MODE;
                LocalStore.setVariable("genre_mode", GENRE_MODE);
                options.activeGenre = 0;
                isQueuePlaylist = false;
                buildGenreList();
                buildPlayList();
                buildInfoTab();
            }
            else if (e.target.action != null)
            {
                var clickAction:String = e.target.action;
                if (clickAction == "search")
                {
                    clearSearchStateParams();
                    options.infoTab = options.infoTab == TAB_SEARCH ? TAB_PLAYLIST : TAB_SEARCH;
                    _gvars.tempFlags['active_tab_temp'] = options.infoTab;
                    buildInfoTab();
                    return;
                }
                else if (clickAction == "playQueue")
                {
                    playQueue();
                }
                else if (clickAction == "doSearch")
                {
                    doSearch(searchBox.text);
                }
                else if (clickAction == "queue")
                {
                    if (songList == _gvars.songQueue && options.infoTab != TAB_QUEUE)
                    {
                        options.infoTab = TAB_QUEUE;
                    }
                    else
                    {
                        isQueuePlaylist = (options.infoTab != TAB_QUEUE);
                        options.infoTab = options.infoTab == TAB_QUEUE ? TAB_PLAYLIST : TAB_QUEUE;
                    }
                    swapToQueue();
                }
                else if (clickAction == "highscores")
                {
                    options.infoTab = (options.infoTab == TAB_PLAYLIST ? TAB_HIGHSCORES : TAB_PLAYLIST);
                    buildInfoTab();
                }
                else if (clickAction == "clearQueue")
                {
                    _gvars.songQueue = [];
                    buildPlayList();
                    buildInfoTab();
                }
                else if (clickAction == "queueRandomize")
                {
                    for (var rq:int = 0; rq < 5; rq++)
                    {
                        _gvars.songQueue = ArrayUtil.randomize(_gvars.songQueue);
                    }
                    buildPlayList();
                    buildInfoTab();
                }
                else if (clickAction == "queueSave")
                {
                    var prompt:MultiplayerPrompt = new MultiplayerPrompt(this, "Song Queue Name");
                    prompt.move(Main.GAME_WIDTH / 2 - prompt.width / 2, Main.GAME_HEIGHT / 2 - prompt.height / 2);
                    prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
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
                    });
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
                    var randomList:Array = songList.filter(function(item:*, index:int, array:Array):Boolean
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

        public function swapToQueue():void
        {
            options.activeGenre = options.infoTab == TAB_QUEUE ? -2 : 0;
            options.pageNumber = 0;
            options.activeIndex = -1;
            options.activeSongID = -1;
            buildGenreList();
            buildPlayList();
            buildInfoTab();
        }

        private function getGenreText(gindex:int):String
        {
            if (GENRE_MODE == GENRE_GENRES || gindex == -1)
                return _lang.string("genre_" + gindex);

            if (GENRE_MODE == GENRE_DIFFICULTIES)
                return _lang.string("difficulty_title_" + gindex);

            if (gindex == 1)
                return "PLAYED";

            return GlobalVariables.SONG_ICON_TEXT[gindex];
        }

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

        private function buildGenreEntry(genre_text:String, isActiveGenre:Boolean, y:Number, gindex:int):void
        {
            if (isActiveGenre)
                addGenreBackground(y - 2);
            addGenreText(genre_text, isActiveGenre, y, gindex);
        }

        private function addGenreBackground(y:Number):void
        {
            SELECTED_GENRE_BACKGROUND.y = y;
            genrelist.addChild(SELECTED_GENRE_BACKGROUND);
        }

        private function addGenreText(genre_text:String, isActiveGenre:Boolean, y:Number, gindex:int):void
        {
            var SongGenre:Text = new Text(genre_text, (isActiveGenre ? 18 : 14));
            SongGenre.height = 22.6;
            SongGenre.width = 130.75;
            SongGenre.y = y;
            SongGenre.mouseChildren = false;
            SongGenre.useHandCursor = true;
            SongGenre.buttonMode = true;
            SongGenre.index = gindex;
            SongGenre.addEventListener(MouseEvent.CLICK, genreClick);
            genrelistItems[genrelistItems.length] = SongGenre;
            genrelist.addChild(SongGenre);
        }

        private function genreClick(e:Event = null):void
        {
            if (options.activeGenre != e.target.index)
            {
                options.infoTab = TAB_PLAYLIST;
                options.isFilter = false;
                options.activeGenre = e.target.index;
                options.activeIndex = -1;
                options.activeSongID = -1;

                clearSearchStateParams();

                _gvars.tempFlags['active_genre_temp'] = options.activeGenre;

                delete _gvars.tempFlags['scroll_dist_temp'];

                isQueuePlaylist = false;
                buildGenreList();
                buildPlayList();
                buildInfoTab();
            }
            stage.focus = stage;
        }

        private function getTotalPages(isBigPage:Boolean):int
        {
            if (isBigPage)
                return Math.ceil(genreLength / 500);
            return Math.min(Math.ceil(genreLength / 12), 20);
        }

        private function configurePageBackground(totalPages:int, isBigPage:Boolean):void
        {
            var limit:int = (isBigPage) ? 7 : 18;
            background.pageBackground.x = (totalPages > limit) ? 3 : 32;
            background.pageBackground.width = (totalPages > limit) ? 605 : 545;
        }

        private function buildPages(totalPages:int, isBigPage:Boolean):void
        {
            var page_width:int = (isBigPage) ? 72 : 27;
            var page_height:int = 16;
            var pages_per_row:int = 600 / (page_width + 3);

            for (var pY:int = 0; pY < totalPages; ++pY)
            {
                var page_x:Number = (page_width + 3) * (pY % pages_per_row);
                var page_y:Number = (page_height + 2) * Math.floor(pY / pages_per_row);
                var page_number:Number = (isBigPage) ? pY : (pY / (totalPages - 1));

                var pBox:DynamicSprite = new DynamicSprite();
                pBox.graphics.lineStyle(1, 0xFFFFFF, 0.5, false);
                pBox.graphics.beginFill(GameBackgroundColor.BG_STATIC, 1);
                pBox.graphics.drawRect(0, 0, page_width, page_height);
                pBox.graphics.endFill();
                pBox.x = page_x;
                pBox.y = page_y;
                pBox.page = page_number;

                var page_str:*;
                if (isBigPage)
                {
                    page_str = ((pY * 500) + 1) + " - " + (((pY + 1) * 500) > genreLength ? genreLength : ((pY + 1) * 500));
                }
                else
                {
                    page_str = (pY + 1);
                }

                var pText:Text = new Text(page_str, page_height - 4);
                pText.width = page_width;
                pText.height = page_height - 1;
                pText.align = Text.CENTER;
                pBox.addChild(pText);

                pBox.mouseChildren = false;
                pBox.useHandCursor = true;
                pBox.buttonMode = true;

                //- Add Listeners
                pBox.addEventListener(MouseEvent.CLICK, pageClicked, false, 0, true);

                pages.addChild(pBox);
            }

            pages.x = 145 + ((610 - pages.width) / 2);
            this.addChild(pages);
        }

        private function pageClicked(e:Event = null):void
        {
            if (options.activeGenre <= -1 || GENRE_MODE == GENRE_SONGFLAGS)
            {
                if (options.pageNumber != e.target.page)
                {
                    options.activeSongID = -1;
                    options.activeIndex = -1;
                    options.pageNumber = e.target.page;
                    buildPlayList();
                    buildInfoTab();
                }
            }
            else
            {
                scrollbar.scrollTo(e.target.page);
                pane.scrollTo(e.target.page);
            }
            stage.focus = stage;
        }

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
                    _gvars.tempFlags['active_index_temp'] = options.activeIndex;
                    buildInfoTab();
                }
                else
                {
                    if (options.infoTab == TAB_PLAYLIST)
                    {
                        if (_mp.gameplayHasOpponent())
                            multiplayerLoad(tarSongItem.level);
                        else
                            playSong(tarSongItem.level);
                    }
                    else
                    {
                        options.infoTab = TAB_PLAYLIST;
                        buildInfoTab();
                    }
                }
            }
        }

        private function songQueueClick(e:Event):void
        {

            _gvars.gameMain.addAlert(sprintf(_lang.string("song_selection_add_to_queue"), {song_name: _playlist.getSong(e.target.level).name}), 90);
            _gvars.songQueue.push(_playlist.getSong(e.target.level));
            if (songList == _gvars.songQueue)
            {
                options.infoTab = TAB_QUEUE;
                buildPlayList();
                options.infoTab = TAB_PLAYLIST;
                buildInfoTab();
            }
        }

        private function songStartClick(e:Event):void
        {
            playSong(e.target.level);
        }

        private function refreshHighscoresClick(e:Event):void
        {
            _gvars.clearHighscores();
            _gvars.activeUser.loadLevelRanks();
            buildInfoTab();
        }

        private function mouseWheelHandler(e:MouseEvent):void
        {
            //- Sanity
            if (genreLength == 0 || !scrollbar.draggerVisibility)
                return;

            //- Scroll
            var dist:Number = scrollbar.scroll + (pane.scrollFactorVertical / 2) * (e.delta > 0 ? -1 : 1);
            pane.scrollTo(dist);
            scrollbar.scrollTo(dist);
            _gvars.tempFlags['scroll_dist_temp'] = dist;
        }

        private function scrollBarMoved(e:Event):void
        {
            pane.scrollTo(e.target.scroll);
        }

        private function keyHandler(e:KeyboardEvent):void
        {
            // Don't do anything with popups open.
            if (_gvars.gameMain.current_popup != null)
                return;

            if (searchBox != null && options.infoTab == 1 && searchBox.focus)
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
            var isNavDirectionUp:Boolean = true;
            var maxGenreIndex:int = getTotalGenres() - 1;

            if (options.activeIndex == -1)
            {
                newIndex = lastIndex = 0;
            }

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
                    isNavDirectionUp = false;
                    break;

                case Keyboard.DOWN:
                    newIndex += 1;
                    isNavDirectionUp = false;
                    break;

                case Keyboard.TAB:
                    clearSearchStateParams();
                    options.activeGenre = options.activeGenre + (e.ctrlKey ? -1 : 1);
                    options.activeIndex = -1;
                    if (options.activeGenre < -1)
                        options.activeGenre = maxGenreIndex;
                    if (options.activeGenre > maxGenreIndex)
                        options.activeGenre = -1;
                    isQueuePlaylist = false;
                    buildGenreList();
                    buildPlayList();
                    buildInfoTab();
                    return;

                case Keyboard.ENTER:
                    if (!(stage.focus is PushButton) && options.activeSongID >= 0)
                    {
                        if (_mp.gameplayHasOpponent())
                            multiplayerLoad(options.activeSongID);
                        else
                            playSong(options.activeSongID);
                    }
                    return;

                default:
                    if (!(stage.focus is PushButton) && ((e.keyCode == Keyboard.BACKSPACE) || (e.keyCode == Keyboard.SPACE) || (e.keyCode >= 48 && e.keyCode <= 111) || (e.keyCode >= 186 && e.keyCode <= 222)))
                    {
                        // Store the string from the searchbox.
                        var tempSearchBoxString:String = "";
                        if (searchBox != null)
                        {
                            tempSearchBoxString = searchBox.text;
                        }

                        // Focus on search and begin typing.
                        options.infoTab = TAB_SEARCH;
                        buildInfoTab();
                        searchBox.text = tempSearchBoxString; // Restore the string.
                    }
                    return;
            }

            if (genreLength == 0)
                return;

            if (newIndex < 0)
            {
                newIndex = 0;
            }
            else if (newIndex > genreLength - 1)
            {
                newIndex = genreLength - 1;
            }

            if (newIndex != lastIndex)
            {
                var action:int = isNavDirectionUp ? -1 : 1;
                var limit:int = isNavDirectionUp ? newIndex : (genreLength - 1 - newIndex);
                for (var counter:int = 0; counter <= limit; ++counter, newIndex += action)
                {
                    if (!songItems[newIndex].isLocked)
                    {
                        setActiveIndex(newIndex, lastIndex, true);
                        buildInfoTab();
                        break;
                    }
                }
            }
        }

        private function songLoadClick(e:Event):void
        {
            multiplayerLoad(e.target.level);
        }

        private function multiplayerLoad(level:int):void
        {
            if (level < 0)
                return;

            isQueuePlaylist = false;
            _mp.gameplayPicking(_playlist.getSong(level));
            _mp.gameplayLoading();
            switchTo(MainMenu.MENU_MULTIPLAYER);
        }

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

        private function playQueue():void
        {
            _gvars.songQueue = _gvars.songQueue.filter(function(item:Object, index:int, array:Array):Boolean
            {
                return (_gvars.checkSongAccess(item) == GlobalVariables.SONG_ACCESS_PLAYABLE);
            });

            if (_gvars.songQueue.length <= 0)
                return;

            isQueuePlaylist = false;
            _gvars.options = new GameOptions();
            _gvars.options.fill();
            switchTo(Main.GAME_PLAY_PANEL);
        }

        private function doSearch(name:String):void
        {
            isQueuePlaylist = false;

            var searchTypeParam:String = searchTypeBox.selectedItem["data"];
            options.activeGenre = -2;
            options.activeSongID = -1;
            options.activeIndex = -1;
            options.isFilter = true;
            options.filter = function(song:Object):Boolean
            {
                return song[searchTypeParam].toLowerCase().indexOf(name.toLowerCase()) > -1;
            };

            // Store Search State
            _gvars.tempFlags['active_genre_temp'] = options.activeGenre;
            _gvars.tempFlags['active_isfilter_temp'] = options.isFilter;
            _gvars.tempFlags['active_filter_temp'] = options.filter;
            _gvars.tempFlags['active_search_temp'] = name;
            _gvars.tempFlags['active_search_type_temp'] = searchTypeParam;

            buildGenreList();
            buildPlayList();
        }

        private function setActiveID(index:int, mpUpdate:Boolean):void
        {
            options.activeSongID = (songItems.length > 0 && index < songItems.length ? songItems[index].level : -1);
            _gvars.tempFlags['active_songid_temp'] = options.activeSongID;
            if (mpUpdate && options.activeSongID != -1)
                _mp.gameplayPicking(_playlist.getSong(options.activeSongID));
        }

        public function setActiveIndex(index:int, last:int, doScroll:Boolean = false):void
        {
            _gvars.removeEventListener(GlobalVariables.LOAD_COMPLETE, highscoresLoaded);

            // No need to do anything if nothing changed
            if (index == last)
                return;

            // Set Index
            options.activeIndex = index;

            // "All" uses pages of 500, so the index will be higher then 500 on other pages. Take care of it.
            if (options.activeGenre <= -1)
            {
                index %= 500;
                last %= 500;
            }

            // Set Song
            setActiveID(index, true);

            // Set Active Highlights
            songItems[index].active = true;
            if (last >= 0 && last < songItems.length)
                songItems[last].active = false;

            // Scroll when doScroll is set.
            if (doScroll && scrollbar.draggerVisibility)
            {
                var scrollVal:Number = (((songItems[index].y / pane.content.height) > 0.5) ? ((songItems[index].y + songItems[index].height) / pane.content.height) : ((songItems[index].y) / pane.content.height));
                pane.scrollTo(scrollVal);
                scrollbar.scrollTo(scrollVal);
            }
        }

        public function multiplayerSelect(songName:String, song:Object):void
        {
            isQueuePlaylist = false;

            options.activeGenre = -2;
            options.activeSongID = (song != null && song.level != null) ? song.level : -1;
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
            buildInfoTab();

            for (var i:int = 0; i < songItems.length; i++)
            {
                if (songItems[i].level == options.activeSongID)
                    setActiveIndex(i, -1, true);
            }
        }

        //-----------------------------------------------------------------------------------------------------------------------------//


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

        private function e_removeFromQueueContextSelect(e:ContextMenuEvent):void
        {
            var songItem:SongItem = (e.contextMenuOwner as SongItem);
            _gvars.songQueue.removeAt(songItem.index);
            buildPlayList();
            buildInfoTab();
        }

        private function e_menuMusicConvertSongLoad(e:Event):void
        {
            writeMenuMusicBytes(e.target as Song);
            playMenuMusicSong(e.target as Song);
        }

        private function playMenuMusicSong(song:Song):void
        {
            LocalStore.setVariable("menu_music", song.entry.name);
            var par:MainMenu = ((this.my_Parent) as MainMenu);
            if (par.menuMusicControls)
                ((par.menuMusicControls.contextMenu as ContextMenu).customItems[0] as ContextMenuItem).caption = "Now Playing: " + song.entry.name;

            if (_gvars.menuMusic)
                _gvars.menuMusic.stop();

            _gvars.menuMusic = new SongPlayerBytes(song.bytesSWF);
            _gvars.menuMusic.start();
            par.drawMenuMusicControls();
        }

        private function writeMenuMusicBytes(song:Song):void
        {
            AirContext.writeFile(AirContext.getAppPath(Constant.MENU_MUSIC_PATH), song.bytesSWF);
        }

        private function clearSearchStateParams():void
        {
            delete _gvars.tempFlags['active_genre_temp'];
            delete _gvars.tempFlags['active_isfilter_temp'];
            delete _gvars.tempFlags['active_filter_temp'];
            delete _gvars.tempFlags['active_search_temp'];
            delete _gvars.tempFlags['active_search_type_temp'];
        }
    }
}
