package classes
{
    import flash.display.Sprite;
    import assets.GameBackgroundColor;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;

    dynamic public class BoxCheck extends Sprite
    {
        // Display
        private var _width:Number = 14;
        private var _height:Number = 14;
        private var _highlight:Boolean = false;
        private var _active:Boolean = false;

        public function BoxCheck():void
        {
            //- Set Button Mode
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            draw();
        }

        public function draw():void
        {
            this.graphics.clear();
            this.graphics.lineStyle(1, 0xFFFFFF, 0.75, true);
            this.graphics.beginFill((highlight ? GameBackgroundColor.BG_LIGHT : 0xFFFFFF), (highlight ? 1 : 0.25))
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
