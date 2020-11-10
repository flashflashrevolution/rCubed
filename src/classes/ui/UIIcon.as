package classes.ui
{
    import com.flashfla.utils.ColorUtil;
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.geom.ColorTransform;

    /**
     * Wrapper for icon shapes into UIComponent compatible shapes.
     */
    public class UIIcon extends Sprite
    {
        public var icon:DisplayObject;
        private var _sprWidth:Number = 1;
        private var _sprHeight:Number = 1;

        public function UIIcon(parent:DisplayObjectContainer = null, sprite:DisplayObject = null, xpos:Number = 0, ypos:Number = 0)
        {
            mouseChildren = false;

            if (sprite)
            {
                icon = sprite;
                _sprWidth = sprite.width;
                _sprHeight = sprite.height;
                addChild(icon);
            }

            this.x = xpos;
            this.y = ypos;
            if (parent)
                parent.addChild(this);
        }

        public function setSize(w:Number, h:Number):void
        {
            if (icon != null)
            {
                icon.scaleX = icon.scaleY = Math.min(w / _sprWidth, h / _sprHeight);

                this.graphics.clear();
                this.graphics.lineStyle(1, 0, 0);
                this.graphics.beginFill(0, 0);
                this.graphics.drawRect(-(icon.width / 2), -(icon.height / 2), w, h);
                this.graphics.endFill();
            }
        }

        public function setColor(color:String):void
        {
            if (icon != null)
            {
                var newColorJ:Number = parseInt("0x" + color.replace("#", ""), 16);
                if (isNaN(newColorJ) || newColorJ < 0)
                    newColorJ = 0;
                var rgb:Object = ColorUtil.hexToRgb(newColorJ);

                icon.transform.colorTransform = new ColorTransform((rgb.r / 255), (rgb.g / 255), (rgb.b / 255));
            }
        }
    }
}
