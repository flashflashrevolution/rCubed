package popups.filebrowser
{
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import popups.filebrowser.FileFolder;

    public class FileBrowserItem extends Sprite
    {
        public static const FIXED_WIDTH:int = 500;
        public static const FIXED_HEIGHT:int = 42;

        private static const COLUMN_COLORS:Array = [,"c1ffff", "e3ffcc", "edddff", "ffffff", "67c7f7", "1ddb00", "ffb600", "f40202", "ac00e5", "7641f2"];
        private static const EXT_COLORS:Object = {"sm": 0x0f78ad,
                "ssc": 0xce4f00,
                "osu": 0xdd73d6,
                "qua": 0xa168c9};

        private var COLUMN_COUNTS:Vector.<int> = new <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

        /** Index in Vector */
        public var index:int = 0;

        /** Marks the Button as in-use to avoid removal in song selector. */
        public var isStale:Boolean = true;

        public var songData:FileFolder;

        private var _color:uint = 0x000000;
        private var _highcolor:uint = 0x000000;

        private var _over:Boolean = false;
        private var _highlight:Boolean = false;

        private var _lblSongName:Text;
        private var _lblAuthorName:Text;
        private var _lblType:Text;
        private var _lblColumnType:Text;

        public function FileBrowserItem(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
        {
            COLUMN_COUNTS.fixed = true;
            tabChildren = tabEnabled = false;

            this.x = xpos;
            this.y = ypos;

            this.buttonMode = true;
            this.useHandCursor = true;
            this.mouseChildren = false;

            if (parent != null)
            {
                parent.addChild(this);
            }


            _lblSongName = new Text(this, 5, 4, "--", 13);
            _lblSongName.setAreaParams(FIXED_WIDTH - 100, 16);

            _lblAuthorName = new Text(this, 5, 22, "--", 11);
            _lblAuthorName.setAreaParams(FIXED_WIDTH - 100, 16);

            _lblType = new Text(this, 5, 1, "--", 10);
            _lblType.setAreaParams(FIXED_WIDTH - 7, 16, "right");

            _lblColumnType = new Text(this, 5, 25, "--", 10);
            _lblColumnType.setAreaParams(FIXED_WIDTH - 8, 16, "right");

            drawBox();

            addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
        }

        /**
         * Draws the background rectangle.
         */
        public function drawBox():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35, true);
            if(highlight)
                this.graphics.beginFill(0x777777, 0.5);
            else
                this.graphics.beginFill(0x000000, 0.15);
            this.graphics.drawRect(0, 0, FIXED_WIDTH, FIXED_HEIGHT);
            this.graphics.endFill();

            var textWidth:int = _lblType.textfield.textWidth;
            this.graphics.lineStyle(0, 0, 0, true);
            this.graphics.beginFill(_color, 0.75);
            this.graphics.drawRoundRectComplex(FIXED_WIDTH - textWidth - 10, 1, textWidth + 10, 17, 0, 0, 5, 0);
            this.graphics.endFill();

            textWidth = _lblColumnType.textfield.textWidth;
            this.graphics.beginFill(0x000000, 0.75);
            this.graphics.drawRoundRectComplex(FIXED_WIDTH - textWidth - 9, FIXED_HEIGHT - 17, textWidth + 9, 17, 5, 0, 0, 0);
            this.graphics.endFill();
        }

        ///////////////////////////////////
        // public methods
        ///////////////////////////////////

        private var chartLookIndex:int;
        private var chartLookChartIndex:int;
        private var chartLookData:Array;

        public function setData(songData:FileFolder):void
        {
            this.songData = songData;
            _lblSongName.text = songData.name;
            _lblAuthorName.text = songData.author + " <font color=\"#cccccc\">[" + songData.stepauthor + "]</font>";
            _lblType.text = songData.ext.toUpperCase();

            // Reset
            for (chartLookIndex = 0; chartLookIndex < COLUMN_COUNTS.length; chartLookIndex++)
                COLUMN_COUNTS[chartLookIndex] = 0;

            // Count Column Charts
            for (chartLookIndex = 0; chartLookIndex < songData.data.length; chartLookIndex++)
            {
                chartLookData = songData.data[chartLookIndex].info.chart;
                for (chartLookChartIndex = 0; chartLookChartIndex < chartLookData.length; chartLookChartIndex++)
                {
                    COLUMN_COUNTS[chartLookData[chartLookChartIndex]['type']]++;
                }
            }

            // Build
            var columnString:String = "";
            for (chartLookIndex = 4; chartLookIndex < COLUMN_COUNTS.length; chartLookIndex++)
                if (COLUMN_COUNTS[chartLookIndex] > 0)
                    columnString += "<font color=\"#" + (COLUMN_COLORS[chartLookIndex] || "ffffff") + "\">" + chartLookIndex + "K</font>  ";

            _lblColumnType.text = columnString.substring(0, columnString.length - 2);

            _color = EXT_COLORS[songData.ext] || 0;

            drawBox();
        }

        ///////////////////////////////////
        // event handlers
        ///////////////////////////////////

        /**
         * Internal mouseOver handler.
         * @param event The MouseEvent passed by the system.
         */
        protected function onMouseOver(event:MouseEvent):void
        {
            _over = true;
            addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
            drawBox();
        }

        /**
         * Internal mouseOut handler.
         * @param event The MouseEvent passed by the system.
         */
        protected function onMouseOut(event:MouseEvent):void
        {
            _over = false;
            removeEventListener(MouseEvent.ROLL_OUT, onMouseOut);
            drawBox();
        }

        ///////////////////////////////////
        // getter/setters
        ///////////////////////////////////
        public function get highlight():Boolean
        {
            return _highlight || _over;
        }

        public function set highlight(val:Boolean):void
        {
            _highlight = val;
            drawBox();
        }
    }
}
