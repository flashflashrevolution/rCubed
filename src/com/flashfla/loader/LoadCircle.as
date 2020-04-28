/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.loader
{
    import flash.display.Sprite;

    public class LoadCircle extends Sprite
    {
        public var circle:Sprite = new Sprite();
        public var tweened:Boolean = false;

        public function LoadCircle()
        {
            // Draws a circle.
            circle.graphics.lineStyle(0);
            circle.graphics.beginFill(0x000000);
            circle.graphics.drawCircle(5, 5, 6);
            this.addChild(circle);
        }
    }
}
