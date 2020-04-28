package menu.mp
{
    import classes.Text;
    import classes.Box;
    import com.flashfla.components.ScrollPane;
    import flash.display.Sprite;
    import flash.events.Event;

    public class ListItem extends Box
    {
        private var _item:Object;

        private var box:Box;
        private var text:Text;

        public function ListItem(_width:Number, _height:Number = 25, _item:Object = null):void
        {
            super(_width, _height, true, false);
            this._item = _item;
            mouseChildren = false;
        }

        override protected function init(e:Event = null):void
        {
            super.init(e);
            if (!text)
            {
                text = new Text("", 11);
                text.x = 5;
                text.width = width;
                text.height = height;
                addChild(text);
            }
        }

        private function updateItem():void
        {
            if (_item.color)
                text.fontColor = _item.color;
            if (_item.size)
                text.fontSize = _item.size;
            text.text = _item.text;
        }

        public function get item():Object
        {
            return _item;
        }

        public function set item(value:Object):void
        {
            _item = value;
            updateItem();
        }
    }
}
