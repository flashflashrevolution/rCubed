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
        private var paneItems:Array;
        private var optionsBox:Sprite;
        private var infoBox:Sprite;
        private var info:Sprite;
        private var pages:Sprite;
        private var songList:Array;

        private var GENRE_MODE:int = GENRE_DIFFICULTIES;

        // Info Page
        private var searchBox:BoxText;
        private var searchTypeBox:ComboBox;
        private var levelBoxLow:BoxText;
        private var levelBoxHigh:BoxText;

        public var options:Object;

        private var songItemContextMenu:ContextMenu;
        private var songItemContextMenuItem:ContextMenuItem;

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
            CONFIG::air
            {
                if (_gvars.sql_connect)
                {
                    songItemContextMenuItem = new ContextMenuItem("Song Options");
                    songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_songOptionsContextSelect);
                    songItemContextMenu.customItems.push(songItemContextMenuItem);
                }
            }
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
            for (i = 0; i < paneItems.length; i++)
            {
                paneItems[i].dispose();
                paneItems[i].removeEventListener(MouseEvent.CLICK, songItemClicked);
                paneItems[i] = null;
            }
            paneItems = null;

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
            var SongGenre:Text;
            genrelistItems = []; // new Vector.<Text>;
            var gindex:int;
            var str:String;
            if (GENRE_MODE == GENRE_DIFFICULTIES)
            {
                var max_diff_genres:int = _gvars.DIFFICULTY_RANGES.length;
                for (gindex = -1; gindex < max_diff_genres; gindex++)
                {
                    if (gindex == -1)
                        str = _lang.string("genre_" + gindex);
                    else
                        str = _lang.string("difficulty_title_" + gindex);

                    if (options.activeGenre == gindex)
                    {
                        SELECTED_GENRE_BACKGROUND.y = ((337 / (max_diff_genres + 1)) * (gindex + 1)) - 2;
                        genrelist.addChild(SELECTED_GENRE_BACKGROUND);
                    }
                    SongGenre = new Text(str, (options.activeGenre == gindex ? 18 : 14));
                    SongGenre.height = 22.6;
                    SongGenre.width = 130.75;
                    SongGenre.y = ((337 / (max_diff_genres + 1)) * (gindex + 1));
                    SongGenre.mouseChildren = false;
                    SongGenre.useHandCursor = true;
                    SongGenre.buttonMode = true;
                    SongGenre.index = gindex;
                    SongGenre.addEventListener(MouseEvent.CLICK, genreClick);
                    genrelistItems[genrelistItems.length] = SongGenre;
                    genrelist.addChild(SongGenre);
                }
            }
            else if (GENRE_MODE == GENRE_SONGFLAGS)
            {
                var max_flags_genres:int = GlobalVariables.SONG_ICON_TEXT.length;
                for (gindex = -1; gindex < max_flags_genres; gindex++)
                {
                    str = _lang.string("genre_" + gindex);
                    if (gindex >= 0)
                        str = GlobalVariables.SONG_ICON_TEXT[gindex];
                    if (gindex == 1)
                        str = "PLAYED";
                    if (options.activeGenre == gindex)
                    {
                        SELECTED_GENRE_BACKGROUND.y = ((337 / (Math.max(12, max_flags_genres) + 1)) * (gindex + 1)) - 2;
                        genrelist.addChild(SELECTED_GENRE_BACKGROUND);
                    }
                    SongGenre = new Text(str, (options.activeGenre == gindex ? 18 : 14));
                    SongGenre.height = 22.6;
                    SongGenre.width = 130.75;
                    SongGenre.y = ((337 / (Math.max(12, max_flags_genres) + 1)) * (gindex + 1));
                    SongGenre.mouseChildren = false;
                    SongGenre.useHandCursor = true;
                    SongGenre.buttonMode = true;
                    SongGenre.index = gindex;
                    SongGenre.addEventListener(MouseEvent.CLICK, genreClick);
                    genrelistItems[genrelistItems.length] = SongGenre;
                    genrelist.addChild(SongGenre);
                }
            }
            else
            {
                var totalGenres:int = (!_gvars.activeUser.DISPLAY_LEGACY_SONGS && !_playlist.engine) ? _gvars.TOTAL_GENRES - 1 : _gvars.TOTAL_GENRES;
                var gposy:int = -1;
                for (gindex = -1; gindex < totalGenres; gindex++)
                {

                    // Legacy Playlist
                    if (!_gvars.activeUser.DISPLAY_LEGACY_SONGS && !_playlist.engine && gindex == (Constant.LEGACY_GENRE - 1))
                        continue;

                    if (options.activeGenre == gindex)
                    {
                        SELECTED_GENRE_BACKGROUND.y = ((337 / (totalGenres + 1)) * (gposy + 1)) - 2;
                        genrelist.addChild(SELECTED_GENRE_BACKGROUND);
                    }
                    SongGenre = new Text(_lang.string("genre_" + gindex), (options.activeGenre == gindex ? 18 : 14));
                    SongGenre.height = 22.6;
                    SongGenre.width = 130.75;
                    SongGenre.y = ((337 / (totalGenres + 1)) * (gposy + 1));
                    SongGenre.mouseChildren = false;
                    SongGenre.useHandCursor = true;
                    SongGenre.buttonMode = true;
                    SongGenre.index = gindex;
                    SongGenre.addEventListener(MouseEvent.CLICK, genreClick);
                    genrelistItems[genrelistItems.length] = SongGenre;
                    genrelist.addChild(SongGenre);
                    gposy++;
                }
            }
        }

        public function buildPlayList():void
        {
            //- Clear out/reset pane items and pages.
            if (paneItems)
            {
                for (i = 0; i < paneItems.length; i++)
                {
                    paneItems[i].dispose();
                    paneItems[i].removeEventListener(MouseEvent.CLICK, songItemClicked);
                    paneItems[i] = null;
                }
            }
            paneItems = null;
            paneItems = [];

            scrollbar.reset();
            pane.clear();

            //- Init Variables
            var i:uint;
            var yOffset:int = 0;
            var song:Array;
            var sI:*;

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
                    // DM_ALL
            }
            else if (options.activeGenre == -1)
            {
                songList = _playlist.indexList;

                // Legacy Filter
                if (!_playlist.engine)
                {
                    songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                    {
                        return item.genre == Constant.LEGACY_GENRE ? _gvars.activeUser.DISPLAY_LEGACY_SONGS : true;
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
                    if (!_playlist.engine)
                    {
                        songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return item.genre == Constant.LEGACY_GENRE ? _gvars.activeUser.DISPLAY_LEGACY_SONGS : true;
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
                    if (!_playlist.engine)
                    {
                        songList = songList.filter(function(item:Object, index:int, array:Array):Boolean
                        {
                            return item.genre == Constant.LEGACY_GENRE ? _gvars.activeUser.DISPLAY_LEGACY_SONGS : true;
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

            drawPages();

            //- Build Playlist
            for (var sX:int = 0; sX < songList.length; sX++)
            {
                song = songList[sX];
                // Playable
                if (!song["access"] || song["access"] == GlobalVariables.SONG_ACCESS_PLAYABLE)
                {
                    sI = new SongItem(song, _gvars.activeUser.getLevelRank(song), options.activeIndex == sX);
                    (sI as SongItem).contextMenu = songItemContextMenu;
                    sI.y = yOffset;
                    sI.genre = -1;
                    sI.index = sX;
                    sI.level = song.level;
                    paneItems[paneItems.length] = sI;
                    pane.content.addChild(sI);
                    yOffset += 29;
                }

                // Locked Song
                else
                {
                    sI = new SongItemLocked(song, getSongLockText(song["access"], song), (song["access"] == GlobalVariables.SONG_ACCESS_PURCHASED ? Constant.SHOP_URL : ""));

                    sI.y = yOffset;
                    if (song["access"] == GlobalVariables.SONG_ACCESS_TOKEN)
                        sI.mouseChildren = true;
                    paneItems[paneItems.length] = sI;
                    pane.content.addChild(sI);
                    yOffset += sI.height + 2;
                }
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

        public function getSongLockText(access:int, song:Object):String
        {
            switch (access)
            {
                case GlobalVariables.SONG_ACCESS_CREDITS:
                    return sprintf(_lang.string("song_selection_banned_credits"), {more_needed: NumberUtil.numberFormat(song.credits - _gvars.activeUser.credits), user_credits: NumberUtil.numberFormat(_gvars.activeUser.credits), song_price: NumberUtil.numberFormat(song.credits)});
                case GlobalVariables.SONG_ACCESS_PURCHASED:
                    return sprintf(_lang.string("song_selection_banned_purchased"), {song_price: NumberUtil.numberFormat(song.price)});
                case GlobalVariables.SONG_ACCESS_VETERAN:
                    return _lang.string("song_selection_banned_veteran");
                case GlobalVariables.SONG_ACCESS_TOKEN:
                    return _gvars.TOKENS[song.level].info;
                case GlobalVariables.SONG_ACCESS_BANNED:
                    return _lang.string("song_selection_banned_invalid");
            }
            return "Unknown Lock Reason (" + access + ") - This shouldn't appear, message Velocity";
        }

        public function drawPages():void
        {
            if (pages != null)
            {
                this.removeChild(pages);
                pages = null;
            }

            var totalPages:int;
            var pY:int;
            var pBox:DynamicSprite;
            var pText:Text;

            pages = new Sprite();
            pages.y = 424;

            if (options.activeGenre <= -1 || GENRE_MODE == GENRE_SONGFLAGS)
            {
                totalPages = Math.ceil(genreLength / 500);

                if (totalPages > 7)
                {
                    background.pageBackground.x = 3;
                    background.pageBackground.width = 605;
                }
                else
                {
                    background.pageBackground.x = 32;
                    background.pageBackground.width = 545;
                }

                for (pY = 0; pY < totalPages; pY++)
                {
                    pBox = new DynamicSprite();
                    pBox.graphics.lineStyle(1, 0xFFFFFF, 0.5, false);
                    pBox.graphics.beginFill(GameBackgroundColor.BG_STATIC, 1);
                    pBox.graphics.drawRect(0, 0, 72, 16);
                    pBox.graphics.endFill();
                    pBox.x = 75 * (pY % 8);
                    pBox.y = 18 * Math.floor(pY / 8);
                    pBox.page = pY;

                    pText = new Text((pY * 500) + 1 + " - " + ((pY + 1) * 500 > genreLength ? genreLength : (pY + 1) * 500), 12);
                    pText.width = 72;
                    pText.height = 15;
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
            else
            {
                totalPages = Math.ceil(genreLength / 12);
                if (totalPages > 20)
                    totalPages = 20;

                if (totalPages > 18)
                {
                    background.pageBackground.x = 3;
                    background.pageBackground.width = 605;
                }
                else
                {
                    background.pageBackground.x = 32;
                    background.pageBackground.width = 545;
                }

                for (pY = 0; pY < totalPages; pY++)
                {
                    pBox = new DynamicSprite();
                    pBox.graphics.lineStyle(1, 0xFFFFFF, 0.5, false);
                    pBox.graphics.beginFill(GameBackgroundColor.BG_STATIC, 1);
                    pBox.graphics.drawRect(0, 0, 27, 16);
                    pBox.graphics.endFill();
                    pBox.x = 30 * (pY % 20);
                    pBox.y = 18 * Math.floor(pY / 20);
                    pBox.page = (pY / (totalPages - 1));

                    pText = new Text((pY + 1), 12);
                    pText.width = 27;
                    pText.height = 15;
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

            if (options.infoTab == TAB_SEARCH)
            { // Song Search
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
                    stage.focus = searchBox.field;
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
                stage.focus = searchBox.field;

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
            else if (options.infoTab == TAB_QUEUE)
            { // Playlist Queue
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
                songQueuePlay.action = "playSong";
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
            else if (options.infoTab == TAB_HIGHSCORES)
            { // Song Ranks
                songInfoTitle = new Text(_lang.string("song_selection_song_panel_highscores"), 14, "#DDDDDD");
                songInfoTitle.x = 0;
                songInfoTitle.y = tY;
                songInfoTitle.width = 164;
                info.addChild(songInfoTitle);

                infoRanks = _gvars.activeUser.getLevelRank(songDetails);
                var highscores:Object = _gvars.getHighscores(songDetails.level);
                if (highscores)
                {
                    var lastRank:int = 0;
                    var lastScore:Number = Number.MAX_VALUE;
                    tY = 21;
                    for (var r:int = 1; r <= 5; r++)
                    {
                        if (highscores[r])
                        {
                            if (highscores[r]['score'] < lastScore)
                            {
                                lastScore = highscores[r]['score'];
                                lastRank = r;
                            }

                            // Username
                            songInfoTitle = new Text("#" + lastRank + ": " + highscores[r]['name'], 14);
                            songInfoTitle.x = 0;
                            songInfoTitle.y = tY;
                            songInfoTitle.width = 164;
                            info.addChild(songInfoTitle);
                            tY += 16;

                            // Rank
                            songInfoDetails = new Text(NumberUtil.numberFormat(highscores[r]['score']), 12, "#DDDDDD");
                            songInfoDetails.x = 0;
                            songInfoDetails.y = tY;
                            songInfoDetails.width = 164;
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
            else
            { // Song Details
                infoRanks = _gvars.activeUser.getLevelRank(songDetails) || {};
                var infoDisplay:Array = [[_lang.string("song_selection_song_panel_song"), songDetails['name']], [_lang.string("song_selection_song_panel_author"), songDetails['author']], [_lang.string("song_selection_song_panel_stepfile"), songDetails['stepauthor']], [_lang.string("song_selection_song_panel_length"), songDetails['time']], [_lang.string("song_selection_song_panel_style"), songDetails['style']], [_lang.string("song_selection_song_panel_best"), (infoRanks.score > 0 ? "\n" + NumberUtil.numberFormat(infoRanks.score) + "\n" + infoRanks.results : _lang.string("song_selection_song_panel_unplayed"))]];

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
                GENRE_MODE = (GENRE_MODE + (e.target == genre_mode_prev ? -1 : 1));
                if (GENRE_MODE < 0)
                    GENRE_MODE = GENRE_MODES;
                if (GENRE_MODE > GENRE_MODES)
                    GENRE_MODE = 0;
                _gvars.tempFlags['genre_mode_temp'] = GENRE_MODE;
                LocalStore.setVariable("genre_mode", GENRE_MODE);
                options.activeGenre = 0;
                buildGenreList();
                buildPlayList();
                buildInfoTab();
            }
            else if (e.target.action != null)
            {
                var clickAction:String = e.target.action;
                if (clickAction == "search")
                {
                    options.infoTab = options.infoTab == TAB_SEARCH ? TAB_PLAYLIST : TAB_SEARCH;
                    _gvars.tempFlags['active_tab_temp'] = options.infoTab;
                    buildInfoTab();
                    return;
                }
                else if (clickAction == "playSong")
                {
                    playSong();
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

                buildGenreList();
                buildPlayList();
                buildInfoTab();
            }
            stage.focus = stage;
        }

        private function songItemClicked(e:Event = null):void
        {
            if (e.target is SongItem)
            {
                var tarSongItem:SongItem = (e.target as SongItem);
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
            switch (e.keyCode)
            {
                case Keyboard.PAGE_UP:
                    newIndex -= 11;
                    if (newIndex < 0)
                        newIndex = 0;
                    break;

                case Keyboard.UP:
                    newIndex -= 1;
                    if (newIndex < 0)
                        newIndex = 0;
                    break;

                case Keyboard.PAGE_DOWN:
                    newIndex += 11;
                    if (newIndex > genreLength - 1)
                        newIndex = genreLength - 1;
                    break;

                case Keyboard.DOWN:
                    newIndex += 1;
                    if (newIndex > genreLength - 1)
                        newIndex = genreLength - 1;
                    break;

                case Keyboard.TAB:
                    options.activeGenre = options.activeGenre + (e.ctrlKey ? -1 : 1);
                    options.activeIndex = -1;
                    if (options.activeGenre < -1)
                        options.activeGenre = _gvars.TOTAL_GENRES - 1;
                    if (options.activeGenre > _gvars.TOTAL_GENRES - 1)
                        options.activeGenre = -1;
                    buildGenreList();
                    buildPlayList();
                    buildInfoTab();
                    return;

                case Keyboard.ENTER:
                case Keyboard.SPACE:
                    if (stage.focus == stage && options.activeSongID >= 0)
                    {
                        if (_mp.gameplayHasOpponent())
                            multiplayerLoad();
                        else
                            playSong();
                    }
                    return;

                default:
                    if (stage.focus == stage && ((e.keyCode >= 48 && e.keyCode <= 111) || (e.keyCode >= 186 && e.keyCode <= 222)))
                    {
                        // Focus on search and begin typing.
                        options.infoTab = options.infoTab == TAB_SEARCH ? TAB_PLAYLIST : TAB_SEARCH;
                        buildInfoTab();
                        searchBox.text = ""; // Empty the box if resetting.
                    }
            }

            if (newIndex != lastIndex)
            {
                setActiveIndex(newIndex, lastIndex, true);
                buildInfoTab();
            }
        }

        private function songLoadClick(e:Event):void
        {
            multiplayerLoad(e.target.level);
        }

        private function multiplayerLoad(level:int = -1):void
        {
            if (options.activeSongID != -1)
            {
                _mp.gameplayPicking(_playlist.getSong(level < 0 ? options.activeSongID : level));
                _mp.gameplayLoading();
                switchTo(MainMenu.MENU_MULTIPLAYER);
            }
        }

        public function playSong(level:int = -1):void
        {
            if (songList != _gvars.songQueue && (level >= 0 || options.activeSongID >= 0))
            {
                var songData:Object = _playlist.getSong(level < 0 ? options.activeSongID : level);
                if (songData.error == null)
                {
                    var accessLevel:int = _gvars.checkSongAccess(songData);
                    if (accessLevel == GlobalVariables.SONG_ACCESS_PLAYABLE)
                    {
                        // Should we prevent PLAY from adding to queue, if the last song in the queue is already the same song?
                        if (_gvars.songQueue.length > 0)
                        {
                            var lastSongData:Object = _gvars.songQueue[_gvars.songQueue.length - 1];
                            if (lastSongData.level != songData.level)
                                _gvars.songQueue.push(songData);
                        }
                        else
                            _gvars.songQueue.push(songData);
                    }
                }
            }
            if (_gvars.songQueue.length > 0)
            {
                _gvars.options = new GameOptions();
                _gvars.options.fill();
                switchTo(Main.GAME_PLAY_PANEL);
            }
        }

        private function doSearch(name:String):void
        {
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
            options.activeSongID = (paneItems[index] != null && paneItems[index] is SongItem ? paneItems[index].level : -1);
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
            paneItems[index].active = true;
            if (paneItems[last] != null)
                paneItems[last].active = false;

            // Scroll when doScroll is set.
            if (doScroll && scrollbar.draggerVisibility)
            {
                var scrollVal:Number = (((paneItems[index].y / pane.content.height) > 0.5) ? ((paneItems[index].y + paneItems[index].height) / pane.content.height) : ((paneItems[index].y) / pane.content.height));
                pane.scrollTo(scrollVal);
                scrollbar.scrollTo(scrollVal);
            }
        }

        public function multiplayerSelect(songName:String, song:Object):void
        {
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

            for (var i:int = 0; i < paneItems.length; i++)
            {
                if (paneItems[i] is SongItem && paneItems[i].level == options.activeSongID)
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
            CONFIG::air
            {
                AirContext.writeFile(AirContext.getAppPath(Constant.MENU_MUSIC_PATH), song.bytesSWF);
            }

            CONFIG::not_air
            {
                LocalStore.setVariable("menu_music_bytes", song.bytesSWF, 20971520); // 20MB Mins size requested.
            }
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
