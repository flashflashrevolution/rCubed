package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.events.MouseEvent;

    dynamic public class BoxButton extends Box
    {
        private var _text:Text;
        private var _enabled:Boolean = true;

        private var _listener:Function = null;

        public function BoxButton(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:Number = 0, height:Number = 0, text:String = "", size:int = 12, listener:Function = null)
        {
            super(parent, xpos, ypos, true, false);
            super.setSize(width, height);

            //- Add Text
            _text = new Text(this, 0, 0, text, size, "#FFFFFF");
            _text.height = height + 1;
            _text.width = width;
            _text.align = Text.CENTER;

            //- Set Defaults
            this.mouseEnabled = true;
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            //- Set click event listener
            if (listener != null)
            {
                this._listener = listener;
                this.addEventListener(MouseEvent.CLICK, listener);
            }
        }

        override public function dispose():void
        {
            if (_listener != null)
                this.removeEventListener(MouseEvent.CLICK, _listener);

            super.dispose();

            if (_text != null)
            {
                _text.dispose();
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        override public function set width(value:Number):void
        {
            _text.width = value;
            super.setSize(value, super.height);
        }

        override public function set height(value:Number):void
        {
            _text.height = value;
            super.setSize(super.width, value);
        }

        override public function get highlight():Boolean
        {
            return enabled && super.highlight;
        }

        public function set enabled(value:Boolean):void
        {
            _enabled = value;
            this.mouseEnabled = value;
            this.useHandCursor = value;
            this.alpha = value ? 1 : 0.5;
            setHoverStatus(value);
        }

        public function get enabled():Boolean
        {
            return _enabled;
        }

        public function get text():String
        {
            return _text.text;
        }

        public function set text(value:String):void
        {
            _text.text = value;
        }

        public function set textColor(color:String):void
        {
            _text.fontColor = color;
        }
    }
}
