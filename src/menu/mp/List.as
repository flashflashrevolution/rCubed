package menu.mp
{
    import classes.Text;
    import classes.Box;
    import com.flashfla.components.ScrollPane;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class List extends Sprite
    {
        public static const ITEM_EVENT:String = "LIST_ITEM_EVENT";

        private var _width:Number;
        private var _height:Number;
        private var _title:String;

        private var background:Box;
        private var header:Box;
        private var headerText:Text;
        private var content:ScrollPane;

        private var _items:Array;
        private var contentItems:Array;

        public function List(_width:Number, _height:Number, _title:String = null):void
        {
            this._width = _width;
            this._height = _height;
            this._title = _title;
            this._items = new Array();
            this.contentItems = new Array();

            if (stage)
                init();
            else
                addEventListener(Event.ADDED_TO_STAGE, init);
        }

        private function init(e:Event = null):void
        {
            if (e)
                removeEventListener(Event.ADDED_TO_STAGE, init);

            background = new Box(_width, _height, false, true);
            background.color = 0x888888;
            addChild(background);

            header = new Box(_width, 24, false, false);
            header.color = 0x000000;
            addChild(header);

            headerText = new Text(_title, 12);
            headerText.x = 5;
            headerText.y = 2;
            header.addChild(headerText);

            content = new ScrollPane(_width, _height - header.height);
            content.y = header.height;
            addChild(content);

            reposition();
            updateItems();

            content.mouseEnabled = false;
            content.content.mouseEnabled = false;
        }

        private function reposition():void
        {
            if (!Boolean(_title))
            {
                header.visible = false;
                content.y = 0;
                content.height = _height;
            }
            else
            {
                header.visible = true;
                content.y = header.height;
                content.height = _height - header.height;
            }
        }

        public function updateItems():void
        {
            if (!content)
                return;

            var i:int;
            var contentItem:ListItem;
            for (i = contentItems.length; i < _items.length; i++)
            {
                contentItem = new ListItem(_width);
                contentItems.push(contentItem);
                contentItem.doubleClickEnabled = true;
                contentItem.addEventListener(MouseEvent.DOUBLE_CLICK, onItemClick);
                contentItem.addEventListener(MouseEvent.CLICK, onItemClick);
            }

            var offset:Number = 0;
            for (i = 0; i < contentItems.length; i++)
            {
                contentItem = contentItems[i];
                if (i < _items.length)
                {
                    if (!contentItem.parent)
                        content.content.addChild(contentItem);
                    contentItem.item = items[i];
                    contentItem.y = offset;
                    offset += contentItem.height;
                }
                else if (contentItem.parent)
                    contentItem.parent.removeChild(contentItem);
            }

            content.scrollTo(0, false);
        }

        private function onItemClick(event:Event):void
        {
            var item:ListItem = event.currentTarget as ListItem;
            dispatchEvent(new ListEvent(ITEM_EVENT, event.type, item.item));
        }

        public function get items():Array
        {
            return _items;
        }

        public function set items(value:Array):void
        {
            _items = value;
            updateItems();
        }

        public function set title(value:String):void
        {
            _title = value;
            reposition();
        }

        public function get title():String
        {
            return _title;
        }

        override public function get width():Number
        {
            return _width;
        }

        override public function get height():Number
        {
            return _height;
        }
    }
}
