package classes.mp.components.browser
{
    import classes.Language;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCRoomDelete;
    import classes.mp.room.MPRoom;
    import classes.ui.IScrollPane;
    import classes.ui.Text;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.ContextMenuEvent;
    import flash.geom.Rectangle;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;

    public class MPBrowserScrollpane extends Sprite implements IScrollPane
    {
        private static const _mp:Multiplayer = Multiplayer.instance;
        private static const _lang:Language = Language.instance;

        private var _width:Number = 100;
        private var _height:Number = 100;

        private var entryButtons:Vector.<MPBrowserEntry> = new Vector.<MPBrowserEntry>();
        private var renderElements:Vector.<MPRoom>;
        private var renderCount:int = 0;

        private var _scrollY:Number = 0;
        private var _calcHeight:int = 0;

        private var _helper_text:Text;

        private var roomContextMenu:ContextMenu;

        public function MPBrowserScrollpane(parent:Sprite, xpos:Number, ypos:Number, wid:Number, hei:Number):void
        {
            _width = wid;
            _height = hei;
            x = xpos;
            y = ypos;
            parent.addChild(this);

            scrollRect = new Rectangle(-1, -1, _width + 1, _height);

            this.graphics.beginFill(0x000000, 0);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();

            _helper_text = new Text(this, 0, 0, Language.instance.string("mp_room_no_entries_visible"));
            _helper_text.setAreaParams(_width, _height, "center");

            // Room Context Menu
            var songItemContextMenuItem:ContextMenuItem;

            if (_mp.currentUser.permissions.mod)
            {
                roomContextMenu = new ContextMenu();

                songItemContextMenuItem = new ContextMenuItem(_lang.stringSimple("mp_room_list_mod_delete"));
                songItemContextMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, e_roomDelete);
                roomContextMenu.customItems.push(songItemContextMenuItem);
            }
        }

        /**
         * Sets the data for the Server Browser to use as a reference for drawing.
         * @param list Array on MPRoom Items to use.
         */
        public function setRenderList(list:Array, sortList:Boolean = true):void
        {
            clearButtons(true);

            var i:int;

            _helper_text.visible = (list.length <= 0);

            renderCount = list.length;

            if (sortList)
                list.sortOn(["name"], [Array.CASEINSENSITIVE]);

            _scrollY = 0;
            _calcHeight = (renderCount * (5 + MPBrowserEntry.ENTRY_HEIGHT)) + 5;

            renderElements = new Vector.<MPRoom>(renderCount, true);
            for (i = 0; i < list.length; i++)
                renderElements[i] = list[i];

            updateChildrenVisibility();
        }

        /**
         * Creates and Removes Room Buttons from the stage, depending on the scroll position.
         * This method uses Pooling on Room Buttons to minimize the amount of RoomButtons
         * created on screen.
         */
        public function updateChildrenVisibility():void
        {
            if (renderElements == null || renderElements.length == 0)
                return;

            var i:int;

            var entryButton:MPBrowserEntry;
            var _y:Number;
            var _inBounds:Boolean;
            var entryObject:MPRoom;

            var GAP:int = (MPBrowserEntry.ENTRY_HEIGHT + 5);
            var startingIndex:int = Math.max(0, Math.floor((_scrollY * -1) / GAP) - 1);
            var lastIndex:int = Math.min(renderCount, (startingIndex + (height / GAP) + 3));
            var START_POINT:int = _scrollY + 5;

            // Update Existing
            var len:int = entryButtons.length - 1;
            for (i = len; i >= 0; i--)
            {
                entryButton = entryButtons[i];
                entryButton.isStale = true;

                _y = START_POINT + entryButton.index * GAP;
                _inBounds = (_y > -GAP && _y < height);

                // Unlink RoomButton no longer on stage.
                if (!_inBounds)
                    removeEntryButton(entryButton);

                // Update Position
                else
                    moveEntryButton(_y, entryButton);
            }

            // Add New Room Buttons
            for (i = startingIndex; i < lastIndex; i++)
            {
                entryObject = renderElements[i];

                // Check for Existing Button
                if (findEntryButton(entryObject) != null)
                    continue;

                // Create Room Button
                _y = START_POINT + i * GAP;
                _inBounds = (_y > -GAP && _y < height);

                if (_inBounds)
                {
                    entryButton = getEntryButton();
                    entryButton.index = i;
                    entryButton.setData(entryObject);

                    if (roomContextMenu)
                        entryButton.contextMenu = roomContextMenu;

                    this.addChild(entryButton);
                    moveEntryButton(_y, entryButton);
                    entryButtons[entryButtons.length] = entryButton;
                }
            }

            // Remove Old Room Buttons
            len = entryButtons.length - 1;
            for (i = len; i >= 0; i--)
            {
                entryButton = entryButtons[i];
                if (entryButton.isStale)
                    removeEntryButton(entryButton);
            }
        }

        /**
         * Moves the MPBrowserEntry to the y value. Also marks the song button
         * as in use for the removal sweep.
         * @param _y
         * @param btn
         */
        public function moveEntryButton(_y:int, btn:MPBrowserEntry):void
        {
            btn.y = _y;
            btn.isStale = false;
        }

        /**
         * Finds the on stage MPBrowserEntry for the given MPRoom.
         * @param room MPRoom to look for.
         * @return If a MPBrowserEntry exist already for this room.
         */
        public function findEntryButton(room:MPRoom):MPBrowserEntry
        {
            if (entryButtons.length == 0)
                return null;

            var len:int = entryButtons.length - 1;
            for (; len >= 0; len--)
            {
                if (entryButtons[len].room === room)
                    return entryButtons[len];
            }
            return null;
        }

        /**
         * Removes the MPBrowserEntry from stage, along with moving it
         * back into the object pool.
         * @param btn MPBrowserEntry to remove.
         */
        public function removeEntryButton(btn:MPBrowserEntry):void
        {
            var idx:int = entryButtons.indexOf(btn);
            if (idx >= 0)
                entryButtons.splice(idx, 1);

            btn.parent.removeChild(btn);
            putEntryButton(btn);
        }

        /**
         * Clears the component of old data.
         */
        public function clear():void
        {
            clearButtons(true);

            renderCount = 0;
            renderElements = null;
            _calcHeight = 0;
        }

        /**
         * Removes all MPBrowserEntrys from the stage.
         * @param force Force Remove, regardless of sweep value.
         */
        public function clearButtons(force:Boolean = false):void
        {
            var entryButton:MPBrowserEntry;

            // Remove Old Entry Buttons
            var len:int = entryButtons.length - 1;
            for (; len >= 0; len--)
            {
                entryButton = entryButtons[len];
                if (entryButton.isStale || force)
                    removeEntryButton(entryButton);
            }
        }

        /**
         * Check the requirement if scrolling should happen.
         * @return
         */
        public function get doScroll():Boolean
        {
            return _calcHeight > _height;
        }

        /**
         * Gets the current vertical scroll factor.
         * Scroll factor is the percent of the height the scrollpane is compared to the overall content height.
         */
        public function get scrollFactorVertical():Number
        {
            return Math.max(Math.min(height / _calcHeight, 1), 0) || 0;
        }

        public function scrollTo(val:Number):void
        {
            _scrollY = -((_calcHeight - _height) * Math.max(Math.min(val, 1), 0));
            updateChildrenVisibility();
        }

        /**
         *
         * Gets the vertical scroll value required to display a specified child.
         * @param	child Child to show.
         * @return	Scroll Value required to show child in center of scroll pane.
         */
        public function scrollChildVertical(child:DisplayObject):Number
        {
            // Checks
            if (child == null || !this.contains(child) || !doScroll)
                return 0;

            var _y:int = (child as MPBrowserEntry).index * (MPBrowserEntry.ENTRY_HEIGHT + 5); // Calculate Real Y.

            // Child is to tall, Scroll to top.
            if (child.height > height)
                return Math.max(Math.min(_y / (_calcHeight - _height), 1), 0);

            return Math.max(Math.min(((_y + (child.height / 2)) - (_height / 2)) / (_calcHeight - _height), 1), 0);
        }

        private function e_roomDelete(e:ContextMenuEvent):void
        {
            const entry:MPBrowserEntry = (e.contextMenuOwner as MPBrowserEntry);
            _mp.sendCommand(new MPCRoomDelete(entry.room));
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /** MPBrowserEntry Pool Vector */
        private static var __vectorMPBrowserEntry:Vector.<MPBrowserEntry> = new Vector.<MPBrowserEntry>();

        /** Retrieves a RoomButton instance from the pool. */
        public static function getEntryButton():MPBrowserEntry
        {
            if (__vectorMPBrowserEntry.length == 0)
                return new MPBrowserEntry();
            else
                return __vectorMPBrowserEntry.pop();
        }

        /** Stores a MPBrowserEntry instance in the pool.
         *  Don't keep any references to the object after moving it to the pool! */
        public static function putEntryButton(roomButton:MPBrowserEntry):void
        {
            if (roomButton)
            {
                roomButton.clear();
                __vectorMPBrowserEntry[__vectorMPBrowserEntry.length] = roomButton;
            }
        }
    }
}
