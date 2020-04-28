package popups
{
    import arc.mp.MultiplayerPrompt;
    import assets.GameBackgroundColor;
    import classes.Alert;
    import classes.Box;
    import classes.BoxButton;
    import classes.BoxText;
    import classes.Language;
    import classes.Text;
    import classes.filter.EngineLevelFilter;
    import classes.filter.SavedFilterButton;
    import com.flashfla.components.ScrollBar;
    import com.flashfla.components.ScrollPane;
    import com.flashfla.utils.ArrayUtil;
    import com.flashfla.utils.SystemUtil;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Point;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
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

        private var addSavedFilterButton:BoxButton;
        private var clearFilterButton:BoxButton;
        private var filterListButton:BoxButton;
        private var closeButton:BoxButton;

        private var scrollpane:ScrollPane;
        private var scrollbar:ScrollBar;

        private var filterButtons:Array;

        private var typeSelector:Sprite;

        private var _contextExport:ContextMenu;
        private var _contextImport:ContextMenu;

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

            // Context Menus
            _contextExport = new ContextMenu();
            var expFilterExport:ContextMenuItem = new ContextMenuItem(_lang.stringSimple("popup_filter_filter_single_export"), CONFIG::not_air);
            expFilterExport.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_contextFilterExport);
            _contextExport.customItems.push(expFilterExport);

            _contextImport = new ContextMenu();
            var expFilterImport:ContextMenuItem = new ContextMenuItem(_lang.stringSimple("popup_filter_filter_single_import"), CONFIG::not_air);
            expFilterImport.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_contextFilterImport);
            _contextImport.customItems.push(expFilterImport);

            // Tab Label
            tabLabel = new Text("", 20);
            tabLabel.x = 10;
            tabLabel.y = 8;
            tabLabel.width = box.width - 10;
            box.addChild(tabLabel);

            //- Closed
            closeButton = new BoxButton(100, 31, _lang.string("popup_close"));
            closeButton.x = box.width - 105;
            closeButton.y = 5;
            closeButton.addEventListener(MouseEvent.CLICK, e_closeButton);
            box.addChild(closeButton);

            //- Saved 
            filterListButton = new BoxButton(100, 31, _lang.string("popup_filter_saved_filters"));
            filterListButton.x = closeButton.x - 105;
            filterListButton.y = 5;
            filterListButton.addEventListener(MouseEvent.CLICK, e_toggleTabButton);
            box.addChild(filterListButton);

            //- Clear
            clearFilterButton = new BoxButton(100, 31, _lang.string("popup_filter_clear_filter"));
            clearFilterButton.x = filterListButton.x - 105;
            clearFilterButton.y = 5;
            clearFilterButton.addEventListener(MouseEvent.CLICK, e_clearFilterButton);
            box.addChild(clearFilterButton);

            //- Add
            addSavedFilterButton = new BoxButton(100, 31, _lang.string("popup_filter_add_filter"));
            addSavedFilterButton.x = filterListButton.x - 105;
            addSavedFilterButton.y = 5;
            addSavedFilterButton.contextMenu = _contextImport;
            addSavedFilterButton.addEventListener(MouseEvent.CLICK, e_addSavedFilterButton);
            box.addChild(addSavedFilterButton);

            // Filter Name Input
            filterNameInput = new BoxText(clearFilterButton.x - 10, 31);
            filterNameInput.x = 5;
            filterNameInput.y = 5;
            filterNameInput.addEventListener(Event.CHANGE, e_filterNameUpdate);
            box.addChild(filterNameInput);

            //- content
            scrollpane = new ScrollPane(box.width - 35, box.height - 46);
            scrollpane.x = 5;
            scrollpane.y = 41;
            scrollpane.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
            box.addChild(scrollpane);
            scrollbar = new ScrollBar(20, scrollpane.height);
            scrollbar.x = 10 + scrollpane.width;
            scrollbar.y = 41;
            scrollbar.addEventListener(Event.CHANGE, e_scrollBarMoved);
            box.addChild(scrollbar);

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

            var typeSelectorTitle:Text = new Text(_lang.string("filter_editor_add_filter"));
            typeSelectorTitle.x = Main.GAME_WIDTH / 2 - 200;
            typeSelectorTitle.y = 5;
            typeSelectorTitle.width = 400;
            typeSelectorTitle.align = Text.CENTER;
            typeSelector.addChild(typeSelectorTitle);

            var typeButton:BoxButton;
            var typeOptions:Array = EngineLevelFilter.createOptions(EngineLevelFilter.FILTERS, "type");
            for (var i:int = 0; i < typeOptions.length; i++)
            {
                typeButton = new BoxButton(185, 25, typeOptions[i]["label"]);
                typeButton.tag = typeOptions[i]["data"];
                typeButton.x = (Main.GAME_WIDTH / 2 - 200) + 10 + (195 * (i % 2));
                typeButton.y = 30 + (Math.floor(i / 2) * 35);
                typeButton.addEventListener(MouseEvent.CLICK, e_addFilterSelection);
                typeSelector.addChild(typeButton);
            }

            draw();

            return true;
        }

        private function e_contextFilterImport(e:ContextMenuEvent):void
        {
            var prompt:MultiplayerPrompt = new MultiplayerPrompt(box.parent, _lang.stringSimple("popup_filter_filter_single_import"));
            prompt.addEventListener(MultiplayerPrompt.EVENT_SEND, function(subevent:Object):void
            {
                try
                {
                    var item:Object = JSON.parse(subevent.params.value);
                    var filter:EngineLevelFilter = new EngineLevelFilter();
                    filter.setup(item);
                    filter.is_default = false;
                    _gvars.activeUser.filters.push(filter);
                    draw();
                }
                catch (e:Error)
                {

                }
            });
        }

        private function e_contextFilterExport(e:ContextMenuEvent):void
        {
            var filterString:String = JSON.stringify((e.contextMenuOwner.parent as SavedFilterButton).filter.export());
            var success:Boolean = SystemUtil.setClipboard(filterString);
            if (success)
            {
                _gvars.gameMain.addAlert("Copied to Clipboard!", 120, Alert.GREEN);
            }
            else
            {
                _gvars.gameMain.addAlert("Error Copying to Clipboard", 120, Alert.RED);
            }
        }

        override public function draw():void
        {
            scrollbar.reset();
            scrollpane.clear();

            pG.clear();
            filterButtons = [];

            // Active Filter Editor
            if (DRAW_TAB == TAB_FILTER)
            {
                filterListButton.text = _lang.string("popup_filter_saved_filters");
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
                var yPos:Number = -40;
                var savedFilterButton:SavedFilterButton;
                for each (var item:EngineLevelFilter in _gvars.activeUser.filters)
                {
                    savedFilterButton = new SavedFilterButton(scrollpane.content, 0, yPos += 40, item, this);
                    savedFilterButton.editButton.contextMenu = _contextExport;
                    filterButtons.push(savedFilterButton);
                }
            }

            scrollpane.scrollTo(scrollbar.scroll, false);
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

                        // AND / OR Label
                        var type_text:Text = new Text(_lang.string("filter_type_" + filter.type));
                        type_text.x = xPos;
                        type_text.y = yPos + 2;
                        scrollpane.content.addChild(type_text);

                        // Remove Filter Button
                        var removeFilter:BoxButton = new BoxButton(23, 23, "X");
                        removeFilter.x = xPos + INDENT_GAP + 327;
                        removeFilter.y = yPos;
                        removeFilter.addEventListener(MouseEvent.CLICK, e_removeFilter);
                        removeFilter.tag = filter;
                        scrollpane.content.addChild(removeFilter);

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

                    var addFilter:BoxButton = new BoxButton(23, 23, "+");
                    addFilter.x = xPos + INDENT_GAP;
                    addFilter.y = yPos += 44;
                    addFilter.addEventListener(MouseEvent.CLICK, e_addFilter);
                    addFilter.tag = filter;
                    scrollpane.content.addChild(addFilter);
                    pG.drawRect(addFilter.x, addFilter.y, 23, 23);

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
            if ((_gvars.gameMain.activePanel is MainMenu) && (_gvars.gameMain.activePanel as MainMenu).panel is MenuSongSelection)
            {
                ((_gvars.gameMain.activePanel as MainMenu).panel as MenuSongSelection).buildPlayList();
                ((_gvars.gameMain.activePanel as MainMenu).panel as MenuSongSelection).buildInfoTab();
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
