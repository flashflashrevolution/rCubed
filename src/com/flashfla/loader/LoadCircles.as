/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.loader
{
    import com.greensock.TweenMax;
    import flash.display.Sprite;
    import flash.events.Event;

    public class LoadCircles extends Sprite
    {
        public static const LOADER_COMPLETE:String = "LoaderComplete";
        public static const LOADER_REMOVED:String = "LoaderRemoved";

        public var holderWidth:Number = 0;
        public var holderHeight:Number = 0;

        public var holder:Sprite = new Sprite();
        public var circles:Array = new Array();

        public function LoadCircles(totalCircles:int = 10)
        {
            for (var i:uint = 0; i < totalCircles; i++)
            {
                // Create a new loader circle
                var circle:LoadCircle = new LoadCircle();

                circle.x = i * 20;
                circle.tweened = false;
                circles.push(circle);

                // Add the circle to the holder
                holder.addChild(circle);
            }

            // Add the holder to the stage
            addChild(holder);

            // Store the dimension of the holding movieclip.
            holderWidth = holder.width;
            holderHeight = holder.height;
        }

        public function UpdateProgress(percent:Number = 0):void
        {
            // Run through each of the circles and check if the percentage is high enough to make them glow.
            for (var i:int = 0; i < circles.length; i++)
            {
                if (percent >= ((i + 1) * 100 / circles.length) && !circles[i].tweened)
                {
                    // Percentage is equal or above this circles glow amount, make it glow and mark as tweened.
                    TweenMax.to(circles[i], 1, {tint: 0xffffff, glowFilter: {color: 0xffffff, alpha: 1, blurX: 15, blurY: 15, strength: 1.5, quality: 3}});
                    circles[i].tweened = true;

                    // Final circle, report back as complete.
                    if (i == (circles.length - 1))
                        dispatchEvent(new Event(LOADER_COMPLETE));
                }
            }
        }

        public function RemoveLoaderBar(method:String = "center", circleDelay = 0.15):void
        {
            switch (method)
            {
                case "center":
                    // Run through the left side and fade out the circles.
                    for (var i = 0; i < circles.length / 2; i++)
                    {
                        TweenMax.to(circles[i], 0.5, {delay: i * circleDelay, alpha: 0, onComplete: circleRemove, onCompleteParams: [circles[i]]});
                    }

                    // Run through the right side and fade out the circles.
                    for (var n = circles.length - 1; n > (circles.length - 1) / 2; n--)
                    {
                        TweenMax.to(circles[n], 0.5, {delay: ((circles.length - 1) * circleDelay) - (n * circleDelay), alpha: 0, onComplete: circleRemove, onCompleteParams: [circles[n]]});
                    }
                    break;

                case "left":
                    // Run through the left side and fade out the circles.
                    for (var o = 0; o < circles.length; o++)
                    {
                        TweenMax.to(circles[o], 0.5, {delay: o * circleDelay, alpha: 0, onComplete: circleRemove, onCompleteParams: [circles[o]]});
                    }
                    break;

                case "right":
                    // Run through the right side and fade out the circles.
                    for (var p = (circles.length - 1); p > -1; p--)
                    {
                        TweenMax.to(circles[p], 0.5, {delay: ((circles.length - 1) * circleDelay) - (p * circleDelay), alpha: 0, onComplete: circleRemove, onCompleteParams: [circles[p]]});
                    }
                    break;
            }
        }

        private function circleRemove(circle:LoaderCircle):void
        {
            // Remove the circle from the holder and remove from the array.
            holder.removeChild(circle);
            circles.splice(circles.indexOf(circle), 1);

            if (circles.length == 0)
            {
                // No circles left, report back as removed.
                removeChild(holder);
                dispatchEvent(new Event(LOADER_REMOVED));
            }
        }
    }
}
