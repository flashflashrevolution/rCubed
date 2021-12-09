package com.flashfla.utils
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.IBitmapDrawable;
    import flash.filters.BlurFilter;
    import flash.geom.ColorTransform;
    import flash.geom.Point;

    public class SpriteUtil
    {
        /*
           public static function setRegistrationPoint(s:DisplayObject, regx:Number, regy:Number):void {
           s.transform.matrix = new Matrix(1, 0, 0, 1, -regx, -regy);
           }

           public static function getAbsolutePosition(t:DisplayObject):Object {
           var aX:Number = t.x;
           var aY:Number = t.y;
           if (t.stage == null)
           return { x:aX, y:aY };

           var p:DisplayObjectContainer = t.parent;
           while (!(p is Stage)) {
           aX += p.x;
           aY += p.y;
           p = p.parent;
           }
           return { x:aX, y:aY };
           }

           public static function isVisible(t:DisplayObject):Boolean {
           if (t.stage == null)
           return false;

           var p:DisplayObjectContainer = t.parent;
           while (!(p is Stage)) {
           if (!p.visible)
           return false;
           p = p.parent;
           }
           return true;
           }
         */

        /**
         * Scales a sprite to fit a max width/height.
         * @param	sprite Sprite to scale
         * @param	maxWidth Max Width
         * @param	maxHeight Max Height
         */
        public static function scaleTo(sprite:DisplayObject, maxWidth:Number, maxHeight:Number):void
        {
            sprite.scaleX = sprite.scaleY = 1;
            sprite.scaleX = sprite.scaleY = Math.min((maxWidth / sprite.width), (maxHeight / sprite.height), 1);
        }

        public static function getBitmapSprite(drawable:IBitmapDrawable, darkness:Number = 1):Bitmap
        {
            var bmd:BitmapData = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            bmd.draw(drawable);
            bmd.applyFilter(bmd, bmd.rect, new Point(), new BlurFilter(16, 16, 3));

            if (darkness < 1)
                bmd.colorTransform(bmd.rect, new ColorTransform(darkness, darkness, darkness));

            return new Bitmap(bmd);
        }
    }
}
