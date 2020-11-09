/**
 * @author Jonathan (Velocity)
 */

package classes.ui
{
    import com.greensock.TweenLite;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    public class ScrollBar extends Sprite
    {
        private var _width:int;
        private var _height:int;
        private var _dragger:Sprite;
        private var _background:Sprite;
        private var _bottom:Number;
        private var _bounds:Rectangle;

        public var scroll:Number = 0;

        private var _listener:Function = null;

        public function ScrollBar(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:int = 0, height:int = 0, dragger:Sprite = null, background:Sprite = null, listener:Function = null):void
        {
            if (parent)
                parent.addChild(this);

            this.x = xpos;
            this.y = ypos;

            this._width = width;
            this._height = height;
            this._dragger = dragger;
            this._background = background;

            //- Draw Background if one isn't provided
            if (_background == null)
            {
                _background = new Sprite();
                _background.graphics.beginFill(0x64A4B8, 0.25);
                _background.graphics.drawRect(0, 0, _width, _height);
                _background.graphics.endFill();
            }
            this.addChild(_background);

            //- Draw Dragger if one isn't provided
            if (_dragger == null)
            {
                _dragger = new Sprite();
                _dragger.graphics.beginFill(0x819AA2, 1);
                _dragger.graphics.drawRect(0, 0, _width, (_height < 30 ? _height : 30));
                _dragger.graphics.endFill();
            }

            //- Set Button Mode
            _dragger.mouseChildren = false;
            _dragger.useHandCursor = true;
            _dragger.buttonMode = true;

            //- Add Listeners
            _dragger.addEventListener(MouseEvent.MOUSE_DOWN, draggerDown);
            _dragger.addEventListener(MouseEvent.MOUSE_UP, draggerUp);

            this.addChild(_dragger);

            //- Set Bottom Bound
            _bottom = Math.floor(_height - _dragger.height);

            //- Set click event listener
            if (listener != null)
            {
                this._listener = listener;
                this.addEventListener(Event.CHANGE, listener);
            }
        }

        public function reset():void
        {
            _dragger.y = 0;
            scroll = 0;
        }

        public function scrollTo(val:Number, useTween:Boolean = true):void
        {
            if (val < 0)
                val = 0;
            if (val > 1)
                val = 1;
            scroll = val;
            if (!useTween)
                _dragger.y = (_bottom * val);
            else
                TweenLite.to(_dragger, 0.25, {y: (_bottom * val)});
        }

        public function set draggerVisibility(visible:Boolean):void
        {
            _dragger.visible = visible;
        }

        public function get draggerVisibility():Boolean
        {
            return _dragger.visible;
        }

        ///- Dragger Events
        private function draggerDown(e:MouseEvent):void
        {
            _bounds = new Rectangle(0, 0, 0, _bottom);
            _dragger.startDrag(false, _bounds);
            e.target.stage.addEventListener(MouseEvent.MOUSE_MOVE, draggerMove);
            e.target.stage.addEventListener(MouseEvent.MOUSE_UP, draggerUpOutside);
        }

        private function draggerUp(e:MouseEvent):void
        {
            e.stopImmediatePropagation();
            _dragger.stopDrag();
            e.target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, draggerMove);
            e.target.stage.removeEventListener(MouseEvent.MOUSE_UP, draggerUpOutside);
        }

        private function draggerUpOutside(e:MouseEvent):void
        {
            _dragger.stopDrag();
            e.target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, draggerMove);
            e.target.stage.removeEventListener(MouseEvent.MOUSE_UP, draggerUpOutside);
        }

        private function draggerMove(e:MouseEvent):void
        {
            scroll = (_dragger.y / _bottom);
            this.dispatchEvent(new Event(Event.CHANGE));
        }
    }

}
