package popups.replays
{
    import flash.display.Sprite;
    import flash.geom.Rectangle;
    import classes.replay.Replay;
    import flash.display.DisplayObject;
    import classes.Language;
    import classes.ui.Text;
    import classes.ui.IScrollPane;

    public class ReplayHistoryScrollpane extends Sprite implements IScrollPane
    {
        private var _width:Number = 100;
        private var _height:Number = 100;

        private var entryButtons:Vector.<ReplayHistoryEntry> = new Vector.<ReplayHistoryEntry>();
        private var renderElements:Vector.<Replay>;
        private var renderCount:int = 0;

        private var _scrollY:Number = 0;
        private var _calcHeight:int = 0;

        private var _helper_text:Text;

        public function ReplayHistoryScrollpane(parent:Sprite, xpos:Number, ypos:Number, wid:Number, hei:Number):void
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

            _helper_text = new Text(this, 0, 0, Language.instance.string("replay_no_entries_visible"));
            _helper_text.setAreaParams(_width, _height, "center");
        }

        /**
         * Sets the data for the Song Selector to use as a reference for drawing.
         * @param list Array on EngineLevel Items to use.
         */
        public function setRenderList(list:Array, sortList:Boolean = true):void
        {
            clearButtons(true);

            var i:int;

            _helper_text.visible = (list.length <= 0);

            renderCount = list.length;

            if (sortList)
                list.sortOn(["songname", "score"], [Array.CASEINSENSITIVE, Array.NUMERIC | Array.DESCENDING]);

            _scrollY = 0;
            _calcHeight = (renderCount * (5 + ReplayHistoryEntry.ENTRY_HEIGHT)) + 5;

            renderElements = new Vector.<Replay>(renderCount, true);
            for (i = 0; i < list.length; i++)
                renderElements[i] = list[i];

            updateChildrenVisibility();
        }

        /**
         * Creates and Removes Song Buttons from the stage, depending on the scroll position.
         * This method uses Pooling on Song Buttons to minimize the amount of SongButtons
         * created on screen.
         */
        public function updateChildrenVisibility():void
        {
            if (renderElements == null || renderElements.length == 0)
                return;

            var i:int;

            var entryButton:ReplayHistoryEntry;
            var _y:Number;
            var _inBounds:Boolean;
            var entryObject:Replay;

            var GAP:int = (ReplayHistoryEntry.ENTRY_HEIGHT + 5);
            var startingIndex:int = Math.max(0, Math.floor((_scrollY * -1) / GAP) - 1);
            var lastIndex:int = Math.min(renderCount, (startingIndex + (height / GAP) + 3));
            var START_POINT:int = _scrollY + 5;

            // Update Existing
            var len:int = entryButtons.length - 1;
            for (i = len; i >= 0; i--)
            {
                entryButton = entryButtons[i];
                entryButton.garbageSweep = 0;

                _y = START_POINT + entryButton.index * GAP;
                _inBounds = (_y > -GAP && _y < height);

                // Unlink SongButton no longer on stage.
                if (!_inBounds)
                    removeEntryButton(entryButton);

                // Update Position
                else
                    moveEntryButton(_y, entryButton);
            }

            // Add New Song Buttons
            for (i = startingIndex; i < lastIndex; i++)
            {
                entryObject = renderElements[i];

                // Check for Existing Button
                if (findEntryButton(entryObject) != null)
                    continue;

                // Create Song Button
                _y = START_POINT + i * GAP;
                _inBounds = (_y > -GAP && _y < height);

                if (_inBounds)
                {
                    entryButton = getEntryButton();
                    entryButton.index = i;
                    entryButton.setData(entryObject);
                    //songButton.highlight = (songObject == selectedSongData);
                    this.addChild(entryButton);
                    moveEntryButton(_y, entryButton);
                    entryButtons[entryButtons.length] = entryButton;
                }
            }

            // Remove Old Song Buttons
            len = entryButtons.length - 1;
            for (i = len; i >= 0; i--)
            {
                entryButton = entryButtons[i];
                if (entryButton.garbageSweep == 0)
                    removeEntryButton(entryButton);
            }
        }

        /**
         * Moves the ReplayHistoryEntry to the y value. Also marks the song button
         * as in use for the removal sweep.
         * @param _y
         * @param btn
         */
        public function moveEntryButton(_y:int, btn:ReplayHistoryEntry):void
        {
            btn.y = _y;
            btn.garbageSweep = 1;
        }

        /**
         * Finds the on stage ReplayHistoryEntry for the given Replay.
         * @param replay Replay to look for.
         * @return If a ReplayHistoryEntry exist already for this replay.
         */
        public function findEntryButton(replay:Replay):ReplayHistoryEntry
        {
            if (entryButtons.length == 0)
                return null;

            var len:int = entryButtons.length - 1;
            for (; len >= 0; len--)
            {
                if (entryButtons[len].replay === replay)
                    return entryButtons[len];
            }
            return null;
        }

        /**
         * Removes the ReplayHistoryEntry from stage, along with moving it
         * back into the object pool.
         * @param btn ReplayHistoryEntry to remove.
         */
        public function removeEntryButton(btn:ReplayHistoryEntry):void
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
         * Removes all ReplayHistoryEntrys from the stage.
         * @param force Force Remove, regardless of sweep value.
         */
        public function clearButtons(force:Boolean = false):void
        {
            var entryButton:ReplayHistoryEntry;

            // Remove Old Entry Buttons
            var len:int = entryButtons.length - 1;
            for (; len >= 0; len--)
            {
                entryButton = entryButtons[len];
                if (entryButton.garbageSweep == 0 || force)
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

            var _y:int = (child as ReplayHistoryEntry).index * (ReplayHistoryEntry.ENTRY_HEIGHT + 5); // Calculate Real Y.

            // Child is to tall, Scroll to top.
            if (child.height > height)
                return Math.max(Math.min(_y / (_calcHeight - _height), 1), 0);

            return Math.max(Math.min(((_y + (child.height / 2)) - (_height / 2)) / (_calcHeight - _height), 1), 0);
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /** ReplayHistoryEntry Pool Vector */
        private static var __vectorReplayHistoryEntry:Vector.<ReplayHistoryEntry> = new Vector.<ReplayHistoryEntry>();

        /** Retrieves a SongButton instance from the pool. */
        public static function getEntryButton():ReplayHistoryEntry
        {
            if (__vectorReplayHistoryEntry.length == 0)
                return new ReplayHistoryEntry();
            else
                return __vectorReplayHistoryEntry.pop();
        }

        /** Stores a ReplayHistoryEntry instance in the pool.
         *  Don't keep any references to the object after moving it to the pool! */
        public static function putEntryButton(songbutton:ReplayHistoryEntry):void
        {
            if (songbutton)
            {
                songbutton.clear();
                __vectorReplayHistoryEntry[__vectorReplayHistoryEntry.length] = songbutton;
            }
        }
    }
}
