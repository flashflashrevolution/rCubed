package classes.ui
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;

    public class ScrollPaneContent extends Sprite
    {
        private var doUpdate:Boolean = false;
        private var _children:Array;
        private var _width:Number = -1;
        private var _height:Number = -1;

        public function ScrollPaneContent()
        {
            _children = [];
            super();
        }

        public function update(maskY:Number, maskHeight:Number):void
        {
            for each (var _child:DisplayObject in _children)
            {
                if ((_child.y >= maskY || _child.y + _child.height >= maskY) && _child.y < maskY + maskHeight)
                {
                    _child.visible = true;
                }
                else
                {
                    _child.visible = false;
                }
            }
        }

        /**
         * Add a display object to the content field.
         * Requires calling "scrollTo" or "update" on the ScrollPane to make children visible.
         * @param	child
         * @return
         */
        override public function addChild(child:DisplayObject):DisplayObject
        {
            child.visible = false;
            _children[_children.length] = child;
            //if (!doUpdate) {
            //	doUpdate = true;
            //	this.addEventListener(Event.ENTER_FRAME, updateEvent, false, 0, true);
            //}
            return super.addChild(child);
        }

        override public function removeChild(child:DisplayObject):DisplayObject
        {
            _children.splice(_children.indexOf(child), 1);
            //if (!doUpdate) {
            //	doUpdate = true;
            //	this.addEventListener(Event.ENTER_FRAME, updateEvent, false, 0, true);
            //}
            return super.removeChild(child);
        }

        private function updateEvent(e:Event):void
        {
            this.removeEventListener(Event.ENTER_FRAME, updateEvent);
            if (doUpdate)
            {
                updateSizes();
            }
        }

        public function updateSizes():void
        {
            _width = super.width;
            _height = super.height;
        }

        public function clear():void
        {
            this.removeChildren();
            _width = -1;
            _height = -1;
        }

        override public function get width():Number
        {
            if (_width == -1)
                updateSizes();
            return _width;
        }

        override public function get height():Number
        {
            if (_height == -1)
                updateSizes();
            return _height;
        }
    }

}
