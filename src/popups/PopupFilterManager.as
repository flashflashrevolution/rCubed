package popups
{
    import assets.GameBackgroundColor;
    import classes.Language;
    import classes.filter.EngineLevelFilter;
    import classes.filter.SavedFilterButton;
    import classes.ui.Box;
    import classes.ui.BoxButton;
    import classes.ui.BoxText;
    import classes.ui.Prompt;
    import classes.ui.ScrollBar;
    import classes.ui.ScrollPane;
    import classes.ui.Text;
    import com.flashfla.utils.ArrayUtil;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import menu.MainMenu;
    import menu.MenuPanel;
    import menu.MenuSongSelection;

    public class PopupFilterManager extends MenuPanel
    {
        public static const TAB_FILTER:int = 0;
        public static const TAB_LIST:int = 1;
        public static const INDENT_GAP:int = 29;

        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _lang:Language = Language.instance;

        //- Background
        private var box:Box;
        private var bmd:BitmapData;
        private var bmp:Bitmap;

        private var tabLabel:Text;
        private var filterNameInput:BoxText;

        private var importFilterButton:BoxButton;
        private var addSavedFilterButton:BoxButton;
        private var clearFilterButton:BoxButton;
        private var filterListButton:BoxButton;
        private var closeButton:BoxButton;

        private var scrollpane:ScrollPane;
        private var scrollbar:ScrollBar;

        private var typeSelector:Sprite;

        private var SELECTED_FILTER:EngineLevelFilter;

        public var DRAW_TAB:int = TAB_FILTER;

        public function PopupFilterManager(myParent:MenuPanel)
        {
            super(myParent);
        }

        override public function init():Boolean
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

            // Tab Label
            tabLabel = new Text(box, 10, 8, "", 20);
            tabLabel.width = box.width - 10;

            //- Closed
            closeButton = new BoxButton(box, box.width - 105, 5, 100, 31, _lang.string("popup_close"), 12, e_closeButton);

            //- Saved 
            filterListButton = new BoxButton(box, closeButton.x - 105, 5, 100, 31, _lang.string("popup_filter_saved_filters"), 12, e_toggleTabButton);

            //- Clear
            clearFilterButton = new BoxButton(box, filterListButton.x - 105, 5, 100, 31, _lang.string("popup_filter_clear_filter"), 12, e_clearFilterButton);

            //- Add
            addSavedFilterButton = new BoxButton(box, filterListButton.x - 105, 5, 100, 31, _lang.string("popup_filter_add_filter"), 12, e_addSavedFilterButton);

            //- Import Filter
            importFilterButton = new BoxButton(box, addSavedFilterButton.x - 105, 5, 100, 31, _lang.string("popup_filter_filter_single_import"), 12, e_importFilterButton);

            // Filter Name Input
            filterNameInput = new BoxText(box, 5, 5, clearFilterButton.x - 11, 30);
            filterNameInput.addEventListener(Event.CHANGE, e_filterNameUpdate);

            //- content
            scrollpane = new ScrollPane(box, 5, 41, box.width - 35, box.height - 46, mouseWheelHandler);
            scrollbar = new ScrollBar(box, 10 + scrollpane.width, 41, 20, scrollpane.height, null, null, e_scrollBarMoved);

            // new type selector
            typeSelector = new Sprite();
            typeSelector.graphics.beginFill(GameBackgroundColor.BG_POPUP, 0.8);
            typeSelector.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            typeSelector.graphics.endFill();
            typeSelector.graphics.beginFill(GameBackgroundColor.BG_POPUP, 1);
            typeSelector.graphics.drawRect(Main.GAME_WIDTH / 2 - 200, -1, 400, Main.GAME_HEIGHT + 2);
            typeSelector.graphics.endFill();
            typeSelector.graphics.lineStyle(1, 0xffffff, 1);
            typeSelector.graphics.beginFill(0xFFFFFF, 0.25);
            typeSelector.graphics.drawRect(Main.GAME_WIDTH / 2 - 200, -1, 400, Main.GAME_HEIGHT + 2);
            typeSelector.graphics.endFill();

            var typeSelectorTitle:Text = new Text(typeSelector, Main.GAME_WIDTH / 2 - 200, 5, _lang.string("filter_editor_add_filter"));
            typeSelectorTitle.width = 400;
            typeSelectorTitle.align = Text.CENTER;

            var typeButton:BoxButton;
            var typeOptions:Array = EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS, "type");
            for (var i:int = 0; i < typeOptions.length; i++)
            {
                typeButton = new BoxButton(typeSelector, (Main.GAME_WIDTH / 2 - 200) + 10 + (195 * (i % 2)), 30 + (Math.floor(i / 2) * 35), 185, 25, typeOptions[i]["label"], 12, e_addFilterSelection);
                typeButton.tag = typeOptions[i]["data"];
            }

            draw();

            return true;
        }

        override public function draw():void
        {
            scrollbar.reset();
            scrollpane.clear();

            pG.clear();

            // Active Filter Editor
            if (DRAW_TAB == TAB_FILTER)
            {
                filterListButton.text = _lang.string("popup_filter_saved_filters");
                importFilterButton.visible = false;
                if (_gvars.activeFilter != null)
                {
                    addSavedFilterButton.visible = tabLabel.visible = false;
                    filterNameInput.visible = clearFilterButton.visible = true;
                    filterNameInput.text = _gvars.activeFilter.name;

                    drawFilter(_gvars.activeFilter, 0, 0);
                }
                else
                {
                    tabLabel.text = _lang.string("popup_filter_no_active_filter");
                    addSavedFilterButton.visible = tabLabel.visible = true;
                    filterNameInput.visible = clearFilterButton.visible = false;
                }
            }
            // Saved Filters List
            else if (DRAW_TAB == TAB_LIST)
            {
                tabLabel.text = _lang.string("popup_filter_saved_filters");
                filterListButton.text = _lang.string("popup_filter_active_filter");
                filterNameInput.visible = clearFilterButton.visible = false;
                addSavedFilterButton.visible = tabLabel.visible = true;
                importFilterButton.visible = true;
                var yPos:Number = -40;
                var savedFilterButton:SavedFilterButton;
                for each (var item:EngineLevelFilter in _gvars.activeUser.filters)
                {
                    savedFilterButton = new SavedFilterButton(scrollpane.content, 0, yPos += 40, item, this);
                }
            }

            scrollpane.scrollTo(scrollbar.scroll);
            scrollbar.draggerVisibility = (scrollpane.content.height > scrollpane.height);
        }

        /**
         * Draws and adds the filter boxes to the scrollpane. This draws filters using recursion for multiple levels.
         * @param	filter Current Filter to Draw
         * @param	indent Indentation Level
         * @param	yPos Starting Y-Position on the scrollpane.
         * @return Bottom Y-Position of the draw filter.
         */
        private function drawFilter(filter:EngineLevelFilter, indent:int = 0, yPos:Number = 0):Number
        {
            var xPos:Number = INDENT_GAP * indent;
            pG.lineStyle(1, 0xFFFFFF, 0.55);
            switch (filter.type)
            {
                case EngineLevelFilter.FILTER_AND:
                case EngineLevelFilter.FILTER_OR:
                    // Render AND / OR Label
                    if (indent > 0)
                    {
                        // Dash Line
                        pG.moveTo(xPos - 4, yPos + 14);
                        pG.lineTo(xPos - INDENT_GAP + 10, yPos + 14);

                        // Remove Filter Button
                        var removeFilter:BoxButton = new BoxButton(scrollpane.content, xPos, yPos, 23, 23, "×", 10, e_removeFilter);
                        removeFilter.tag = filter;
                        removeFilter.color = 0xFF0000;
                        removeFilter.normalAlpha = 0.35;
                        removeFilter.activeAlpha = 0.45;

                        // AND / OR Label
                        var type_text:Text = new Text(scrollpane.content, xPos + 29, yPos + 2, _lang.string("filter_type_" + filter.type));

                        yPos -= 8;
                    }
                    else
                    {
                        yPos -= 40; // Filters start with AND filter, so remove starting 40px.
                    }

                    var topYPos:Number = yPos + 46; // Store Starting y Position for Line later.

                    // Render Filters
                    for (var i:int = 0; i < filter.filters.length; i++)
                    {
                        yPos = drawFilter(filter.filters[i], indent + 1, yPos += 40);
                    }

                    // Add Filter Button
                    pG.moveTo(xPos + INDENT_GAP - 4, yPos + 57);
                    pG.lineTo(xPos + 10, yPos + 57);

                    var addFilter:BoxButton = new BoxButton(scrollpane.content, xPos + INDENT_GAP, yPos += 44, 23, 23, "+", 14, e_addFilter);
                    addFilter.tag = filter;
                    addFilter.color = 0x27D200;
                    addFilter.normalAlpha = 0.35;
                    addFilter.activeAlpha = 0.45;

                    pG.moveTo(xPos + 10, topYPos);
                    pG.lineTo(xPos + 10, yPos + 14);
                    yPos -= 8;
                    break;

                default:
                    pG.moveTo(xPos - 4, yPos + 17);
                    pG.lineTo(xPos - INDENT_GAP + 10, yPos + 17);
                    new FilterItemButton(scrollpane.content, xPos, yPos, filter, this);
                    break;
            }
            return yPos;
        }

        private function get pG():Graphics
        {
            return scrollpane.content.graphics;
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

        private function e_scrollBarMoved(e:Event):void
        {
            scrollpane.scrollTo(scrollbar.scroll);
        }

        private function e_filterNameUpdate(e:Event):void
        {
            _gvars.activeFilter.name = filterNameInput.text;
        }

        private function e_closeButton(e:Event):void
        {
            removePopup();
            if (_gvars.activeUser == _gvars.playerUser)
            {
                _gvars.activeUser.saveLocal();
                _gvars.activeUser.save();
            }

            if (_gvars.gameMain.activePanel != null && _gvars.gameMain.activePanel is MainMenu)
            {
                var mmmenu:MainMenu = (_gvars.gameMain.activePanel as MainMenu);
                mmmenu.buildMenuItems();

                if (mmmenu.panel != null && (mmmenu.panel is MenuSongSelection))
                {
                    var msmenu:MenuSongSelection = (mmmenu.panel as MenuSongSelection);
                    msmenu.buildPlayList();
                    msmenu.buildInfoBox();
                }
            }
        }

        private function e_toggleTabButton(e:Event):void
        {
            DRAW_TAB = (DRAW_TAB == TAB_FILTER ? TAB_LIST : TAB_FILTER);
            draw();
        }

        private function e_clearFilterButton(e:Event):void
        {
            _gvars.activeFilter = null;
            draw();
        }

        private function e_addSavedFilterButton(e:Event):void
        {
            _gvars.activeUser.filters.push(new EngineLevelFilter(true));

            if (DRAW_TAB == TAB_FILTER)
                _gvars.activeFilter = _gvars.activeUser.filters[_gvars.activeUser.filters.length - 1];

            draw();
        }

        private function e_importFilterButton(e:Event):void
        {
            new Prompt(box.parent, 320, _lang.string("popup_filter_filter_single_import"), 100, "IMPORT", e_importFilter);
        }

        private function e_importFilter(filterJSON:String):void
        {
            try
            {
                var item:Object = JSON.parse(filterJSON);
                var filter:EngineLevelFilter = new EngineLevelFilter();
                filter.setup(item);
                filter.is_default = false;
                _gvars.activeUser.filters.push(filter);
                draw();
            }
            catch (e:Error)
            {

            }
        }

        private function e_addFilter(e:Event):void
        {
            SELECTED_FILTER = (e.target as BoxButton).tag;
            addChild(typeSelector);
        }

        private function e_addFilterSelection(e:Event):void
        {
            removeChild(typeSelector);
            var newFilter:EngineLevelFilter = new EngineLevelFilter();
            newFilter.type = e.target.tag;
            newFilter.parent_filter = SELECTED_FILTER;

            SELECTED_FILTER.filters.push(newFilter);
            draw();
        }

        private function e_removeFilter(e:Event):void
        {
            var filter:EngineLevelFilter = (e.target as BoxButton).tag;
            if (ArrayUtil.remove(filter, filter.parent_filter.filters))
            {
                draw();
            }
        }
    }
}
