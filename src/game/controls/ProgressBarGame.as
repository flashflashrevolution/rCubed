package game.controls
{

    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;

    public class ProgressBarGame extends GameControl
    {
        private var top_mc:Sprite = new Sprite();
        private var progress_mc:Sprite = new Sprite();

        public var barWidth:int;
        public var barHeight:int;

        public function ProgressBarGame(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, bWidth:uint = 458, bHeight:uint = 20, bSplits:uint = 4, borColor:uint = 0x545454, borSize:Number = 0.1, bColor:uint = 0x00BFFF)
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

        public function update(value:Number = 0, useTween:Boolean = true):void
        {
            if (value < 0)
                value = 0;
            if (value > 1)
                value = 1;

            progress_mc.width = value * barWidth;
        }

        override public function get id():String
        {
            return GameLayoutManager.LAYOUT_PROGRESS_BAR;
        }
    }
}
