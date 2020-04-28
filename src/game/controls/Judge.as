package game.controls
{
    import com.greensock.TweenLite;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import game.GameOptions;
    import flash.geom.Matrix;

    public class Judge extends Sprite
    {
        private var options:GameOptions;
        private var indexes:Object = Judge_Tweens.judge_indexes;
        private var labelDesc:Array = [];
        private var field:TextField;
        private var freeze:Boolean = false;

        private var lastScore:Number = 100;
        private var frame:uint = 0;
        private var sX:Number = 0;

        private var frameRateMod:int = 1;

        public function Judge(options:GameOptions)
        {
            this.options = options;

            var fps:int = this.options.frameRate;
            if (fps >= 60)
            {
                frameRateMod = fps / 60;
            }

            labelDesc[100] = {colour: options.judgeColours[0], title: "AMAZING!!!"};
            labelDesc[50] = {colour: options.judgeColours[1], title: "PERFECT!"};
            labelDesc[25] = {colour: options.judgeColours[2], title: "GOOD"};
            labelDesc[5] = {colour: options.judgeColours[3], title: "AVERAGE"};
            labelDesc[-5] = {colour: options.judgeColours[5], title: "BOO!!"};
            labelDesc[-10] = {colour: options.judgeColours[4], title: "MISS!"};

            var textFormat:TextFormat = new TextFormat(new Xolonium.Bold().fontName, 36, 0xffffff, true);
            textFormat.kerning = true;
            textFormat.letterSpacing = -2;

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

            addEventListener(Event.ENTER_FRAME, updateJudge, false, 0, true);

            //updateDisplay();

            this.mouseChildren = false;
            this.doubleClickEnabled = false;
            this.tabEnabled = false;
        }

        public function hideJudge():void
        {
            this.frame = 0;
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
            field.textColor = labelDesc[newScore].colour;
            field.text = labelDesc[newScore].title;
            sX = field.x;
            frame = 0;
            freeze = doFreeze;
            updateDisplay();
        }

        public function updateJudge(e:Event):void
        {
            if (!freeze && this.alpha > 0)
            {
                frame++;
                updateDisplay();
                this.visible = true;
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
                if (i[0] > 1 && indexes[lastScore][frame + i[0]])
                {
                    var n:Array = indexes[lastScore][frame + i[0]]; // Next Frame
                    TweenLite.to(this, i[0] * frameRateMod, {useFrames: true, scaleX: n[3], scaleY: n[4], alpha: n[5]});

                    TweenLite.to(field, i[0] * frameRateMod, {useFrames: true, x: sX + n[1], y: (n[2] - 30)});
                }
            }
        }
    }
}
