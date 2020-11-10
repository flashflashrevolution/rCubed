/**
 * @author Jonathan (Velocity)
 */

package classes.ui
{
    import com.greensock.TweenLite;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class ScrollPane extends Sprite
    {
        private var _width:Number;
        private var _height:Number;
        private var _mask:Sprite;
        private var _filler:Sprite;

        public var content:ScrollPaneContent;

        private var _listener:Function = null;

        public function ScrollPane(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:int = 0, height:int = 0, listener:Function = null):void
        {
            if (parent)
                parent.addChild(this);

            this.x = xpos;
            this.y = ypos;

            this._width = width;
            this._height = height;

            //- Draw Filler
            _filler = new Sprite();
            _filler.graphics.beginFill(0xFFFFFF, 0);
            _filler.graphics.drawRect(0, 0, _width, _height);
            _filler.graphics.endFill();
            this.addChild(_filler);

            //- Build Content Pane
            content = new ScrollPaneContent();

            //- Add Mask
            _mask = new Sprite();
            _mask.graphics.beginFill(0xFFFFFF, 1);
            _mask.graphics.drawRect(0, 0, _width, _height);
            _mask.graphics.endFill();
            this.addChild(_mask);
            content.mask = _mask;

            //- Add Content Pane
            this.addChild(content);

            //- Set click event listener
            if (listener != null)
            {
                this._listener = listener;
                this.addEventListener(MouseEvent.MOUSE_WHEEL, listener);
            }
        }

        public function dispose():void
        {
            if (_listener != null)
                this.removeEventListener(MouseEvent.MOUSE_WHEEL, _listener);

            if (_mask)
            {
                this.removeChild(_mask);
                _mask = null;
            }
            if (_filler)
            {
                this.removeChild(_filler);
                _filler = null;
            }
            if (content != null)
            {
                if (content.numChildren > 0)
                {
                    for (var i:uint = 0; i < content.numChildren; i++)
                    {
                        content.removeChildAt(i);
                    }
                }
                this.removeChild(content);
                content = null;
            }
        }

        public function clear():void
        {
            content.clear();
        }

        public function update():void
        {
            content.update(content.y * -1, _height);
        }

        public function scrollTo(val:Number, useTween:Boolean = true):void
        {
            if (val < 0)
                val = 0;
            if (val > 1)
                val = 1;

            if (!useTween)
            {
                content.y = -((content.height - _height) * val);
                update();
            }
            else
            {
                TweenLite.to(content, 0.25, {y: -((content.height - _height) * val), onUpdate: update, onComplete: update});
            }
        }

        override public function get height():Number
        {
            return _height;
        }

        override public function get width():Number
        {
            return _width;
        }

        /**
         * Gets the current vertical scroll factor.
         * Scroll factor is the percent of the height the scrollpane is compared to the overall content height.
         */
        public function get scrollFactorVertical():Number
        {
            return Math.max(Math.min(height / content.height, 1), 0) || 0;
        }
    }
}
