/**
 * @author Jonathan (Velocity)
 */

package classes.ui
{
    import com.greensock.TweenLite;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;

    public class ProgressBar extends Sprite
    {
        public static const LOADER_COMPLETE:String = "LoaderComplete";

        private var top_mc:Sprite = new Sprite();
        private var progress_mc:Sprite = new Sprite();

        private var curPercent:Number = 0;
        public var isComplete:Boolean = false;
        public var barWidth:int;
        public var barHeight:int;

        public function ProgressBar(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, bWidth:uint = 450, bHeight:uint = 20, bSplits:uint = 0, borColor:uint = 0x000000, borSize:Number = 2, bColor:uint = 0x00BFFF)
        {
            if (parent)
                parent.addChild(this);

            this.x = xpos;
            this.y = ypos;

            // Draw Background
            top_mc.graphics.beginFill(0xFFFFFF, 0.0);
            top_mc.graphics.lineStyle(0);
            top_mc.graphics.drawRect(0, 0, bWidth, bHeight);
            top_mc.graphics.endFill();

            // Draw Gloss
            top_mc.graphics.beginFill(0xFFFFFF, 0.5);
            top_mc.graphics.lineStyle(1, 0x000000, 0);
            top_mc.graphics.drawRect(1, 1, bWidth - 2, (bHeight - 2) / 2);
            top_mc.graphics.endFill();

            // Draw Border
            top_mc.graphics.lineStyle(borSize, borColor, 1);
            top_mc.graphics.drawRect(0, 0, bWidth, bHeight);
            if (bSplits > 0)
            {
                top_mc.graphics.lineStyle(borSize, borColor, 0.75);
                var spacing:Number = bWidth / bSplits;
                for (var sX:int = 0; sX < bSplits; sX++)
                {
                    top_mc.graphics.moveTo(spacing * sX, 0);
                    top_mc.graphics.lineTo(spacing * sX, bHeight);
                }
            }

            // Draw Progress Bar
            progress_mc.graphics.beginFill(bColor);
            progress_mc.graphics.lineStyle(1, 0x000000, 0);
            progress_mc.graphics.drawRect(0, 0, bWidth, bHeight);
            progress_mc.graphics.endFill();
            progress_mc.width = 0;

            // Add the clips to the stage
            addChild(progress_mc);
            addChild(top_mc);

            this.mouseChildren = false;
            this.barWidth = bWidth;
            this.barHeight = height;
        }

        public function update(percent:Number = 0, useTween:Boolean = true):void
        {
            if (percent < 0)
                percent = 0;
            if (percent > 100)
                percent = 100;

            if (curPercent != percent)
            {
                if (useTween)
                    TweenLite.to(progress_mc, 0.25, {width: (percent / 100) * barWidth});
                else
                    progress_mc.width = (percent / 100) * barWidth;

                if (percent == 100)
                {
                    dispatchEvent(new Event(LOADER_COMPLETE));
                    this.isComplete = true;
                }
            }

        }

        public function remove(time:Number = 0.5):void
        {
            TweenLite.to(this, time, {alpha: 0, onComplete: removeLoaderBar});
        }

        private function removeLoaderBar():void
        {
            parent.removeChild(this);
        }
    }
}
