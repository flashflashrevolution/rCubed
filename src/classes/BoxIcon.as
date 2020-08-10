package classes
{
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    import com.flashfla.utils.ColorUtil;

    dynamic public class BoxIcon extends Box
    {
        private var _icon:UIIcon;
        private var _enabled:Boolean = true;

        public function BoxIcon(width:Number, height:Number, icon:Sprite, useHover:Boolean = true, useGradient:Boolean = false)
        {
            super(width, height, useHover, useGradient);

            //- Add Icon
            _icon = new UIIcon(this, icon, width / 2 + 1, height / 2 + 1);
            _icon.icon.transform.colorTransform = new ColorTransform(0.88, 0.99, 1);
            _icon.setSize(width - 11, height - 11);

            //- Set Defaults
            this.mouseEnabled = true;
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;
        }

        public function setIconColor(color:String):void
        {
            var newColorJ:int = parseInt("0x" + color.replace("#", ""), 16);
            if (isNaN(newColorJ) || newColorJ < 0)
                newColorJ = 0;
            var rgb:Object = ColorUtil.hexToRgb(newColorJ);
            _icon.icon.transform.colorTransform = new ColorTransform((rgb.r / 255), (rgb.g / 255), (rgb.b / 255));
        }

        public function setHoverText(hover_text:String, location:String):void
        {

        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        override public function set width(value:Number):void
        {
            _icon.setSize(value - 11, height - 11);
            super.width = value;
        }

        override public function set height(value:Number):void
        {
            _icon.setSize(width - 11, value - 11);
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
    }
}
