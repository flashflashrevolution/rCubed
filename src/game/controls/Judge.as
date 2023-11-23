package game.controls
{
    import com.greensock.TweenLite;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.getTimer;
    import game.GameOptions;
    import AachenLight;

    public class Judge extends Sprite
    {
        private var options:GameOptions;
        private var indexes:Object = Judge_Tweens.judge_indexes;
        private var labelDesc:Array = [];
        private var field:TextField;
        private var freeze:Boolean = false;

        private var lastScore:Number = 100;
        private var frame:uint = 0;
        private var subframe:Number = 0;
        private var lastTime:Number = 0;
        private var sX:Number = 0;

        private var speedScale:Number = 1;

        public function Judge(options:GameOptions, parent:DisplayObjectContainer)
        {
            if (parent)
                parent.addChild(this);

            this.options = options;

            if (!this.options.displayJudgeAnimations)
                indexes = Judge_Tweens.judge_indexes_static;

            speedScale = this.options.judgeSpeed;

            labelDesc[100] = {color: options.judgeColors[0], title: "AMAZING!!!"};
            labelDesc[50] = {color: options.judgeColors[1], title: "PERFECT!"};
            labelDesc[25] = {color: options.judgeColors[2], title: "GOOD"};
            labelDesc[5] = {color: options.judgeColors[3], title: "AVERAGE"};
            labelDesc[-5] = {color: options.judgeColors[5], title: "BOO!!"};
            labelDesc[-10] = {color: options.judgeColors[4], title: "MISS!"};

            var textFormat:TextFormat = new TextFormat(Fonts.AACHEN_LIGHT, 42 * options.judgeScale, 0xffffff, true);

            field = new TextField();
            field.defaultTextFormat = textFormat;
            field.antiAliasType = AntiAliasType.NORMAL;
            field.embedFonts = true;
            field.selectable = false;
            field.autoSize = TextFieldAutoSize.CENTER;
            field.mouseEnabled = false;
            field.doubleClickEnabled = false;
            field.mouseWheelEnabled = false;
            field.tabEnabled = false;
            field.x = 0;
            field.y = -30;
            field.visible = true;
            field.alpha = 1;
            field.cacheAsBitmapMatrix = new Matrix();
            addChild(field)

            //updateDisplay();

            this.mouseChildren = false;
            this.doubleClickEnabled = false;
            this.tabEnabled = false;
        }

        public function hideJudge():void
        {
            this.frame = 0;
            this.subframe = 0;
            this.alpha = 0;
            this.visible = false;
        }

        public function showJudge(newScore:int, doFreeze:Boolean = false):void
        {
            // Hide Perfect/Amazing Judge
            if (!options.isEditor && newScore >= 50 && !options.displayPerfect)
            {
                return;
            }

            lastScore = newScore;

            field.x = sX;
            field.textColor = labelDesc[newScore].color;
            field.text = labelDesc[newScore].title;
            sX = field.x;
            frame = 0;
            subframe = 0;
            freeze = doFreeze;
            lastTime = getTimer();
            updateDisplay();
        }

        public function updateJudge(e:Event):void
        {
            if (!freeze && this.alpha > 0)
            {
                var curTime:Number = getTimer();
                subframe += ((curTime - lastTime) / 30) * speedScale; // Animation keys are 30fps.
                while (int(subframe) > frame)
                {
                    frame++;
                    updateDisplay();
                    this.visible = true;
                }
                lastTime = curTime;
            }
        }

        private function updateDisplay():void
        {
            if (freeze && frame > 0)
                return;

            if (indexes[lastScore][frame])
            {
                var i:Array = indexes[lastScore][frame];

                field.x = sX + i[1];
                field.y = (i[2] - 30);
                this.scaleX = i[3];
                this.scaleY = i[4];
                this.alpha = i[5];

                if (freeze)
                    return;

                // Tween
                var next:Array = indexes[lastScore][frame + i[6]]; // Next Frame
                if (i[0] > 0 && next != null)
                {
                    TweenLite.to(this, i[0] / speedScale, {scaleX: next[3], scaleY: next[4], alpha: next[5]});
                    TweenLite.to(field, i[0] / speedScale, {x: sX + next[1], y: (next[2] - 30)});
                }
            }
        }
    }
}
