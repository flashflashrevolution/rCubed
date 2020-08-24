package classes
{

    dynamic public class BoxButton extends Box
    {
        private var _text:Text;

        private var _enabled:Boolean = true;

        public function BoxButton(width:Number, height:Number, text:String, size:int = 12, color:String = "#FFFFFF", useHover:Boolean = true, useGradient:Boolean = false)
        {
            super(width, height, useHover, useGradient);

            //- Add Text
            _text = new Text(text, size, color);
            _text.height = height + 1;
            _text.width = width;
            _text.align = Text.CENTER;
            this.addChild(_text);

            //- Set Defaults
            this.mouseEnabled = true;
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;
        }

        override public function dispose():void
        {
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
            super.width = value;
        }

        override public function set height(value:Number):void
        {
            _text.height = value;
            super.height = value;
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
    }
}
