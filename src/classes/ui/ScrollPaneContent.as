package classes.ui
{
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.geom.Rectangle;

    public class ScrollPaneContent extends Sprite
    {
        private var doUpdate:Boolean = false;
        private var _width:Number = -1;
        private var _height:Number = -1;

        private var _idx:int;
        private var _child:DisplayObject;

        public function update(maskY:Number, maskHeight:Number):void
        {
            for (_idx = this.numChildren - 1; _idx >= 0; _idx--)
            {
                _child = this.getChildAt(_idx);
                _child.visible = ((_child.y >= maskY || _child.y + _child.height >= maskY) && _child.y < maskY + maskHeight);
            }

            _child = null;
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
            return super.addChild(child);
        }

        override public function removeChild(child:DisplayObject):DisplayObject
        {
            return super.removeChild(child);
        }

        public function updateSizes():void
        {
            // account for elements not placed at 0.
            var currentBounds:Rectangle = getBounds(this);

            _width = currentBounds.x + currentBounds.width; //super.width;
            _height = currentBounds.y + currentBounds.height; //super.height;
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
