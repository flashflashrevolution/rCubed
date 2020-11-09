package classes.ui
{
    import assets.GameBackgroundColor;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    dynamic public class BoxCheck extends Sprite
    {
        // Display
        private var _width:Number = 14;
        private var _height:Number = 14;
        private var _highlight:Boolean = false;
        private var _active:Boolean = false;

        private var _listener:Function = null;

        public function BoxCheck(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, listener:Function = null):void
        {
            if (parent)
                parent.addChild(this);

            //- Set Button Mode
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            //- Set position
            this.x = xpos;
            this.y = ypos;

            //- Set click event listener
            if (listener != null)
            {
                this._listener = listener;
                this.addEventListener(MouseEvent.CLICK, listener);
            }

            draw();
        }

        public function dispose():void
        {
            if (_listener != null)
                this.removeEventListener(MouseEvent.CLICK, _listener);
        }

        public function draw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(1, 0xFFFFFF, 0.75, true);
            this.graphics.beginFill((highlight ? GameBackgroundColor.BG_LIGHT : 0xFFFFFF), (highlight ? 1 : 0.25));
            this.graphics.drawRect(0, 0, width, height);
            this.graphics.endFill();

            // X
            if (checked)
            {
                this.graphics.lineStyle(0, 0, 0);
                this.graphics.beginFill(0xFFFFFF, 0.75)
                this.graphics.drawRect(5, 5, width - 9, height - 9);
                this.graphics.endFill();
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        public function get highlight():Boolean
        {
            return _highlight || _active;
        }

        public function set checked(val:Boolean):void
        {
            _active = val;
            draw();
        }

        public function get checked():Boolean
        {
            return _active;
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
