package game.controls
{
    import classes.Language;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import flash.text.AntiAliasType;
    import game.GameOptions;

    public class PAWindow extends Sprite
    {
        private static var _lang:Language = Language.instance;

        public var scores:Array;
        private var labels:Array;

        private var options:GameOptions;

        public function PAWindow(options:GameOptions)
        {
            this.options = options;

            labels = new Array();
            scores = new Array();

            var ypos:int = 0;
            var scoreSize:int = 36;

            var labelDesc:Array = [{color: options.judgeColors[0], title: _lang.stringSimple("game_amazing")},
                {color: options.judgeColors[1], title: _lang.stringSimple("game_perfect")},
                {color: options.judgeColors[2], title: _lang.stringSimple("game_good")},
                {color: options.judgeColors[3], title: _lang.stringSimple("game_average")},
                {color: options.judgeColors[4], title: _lang.stringSimple("game_miss")},
                {color: options.judgeColors[5], title: _lang.stringSimple("game_boo")}];

            if (!options.displayAmazing)
            {
                labelDesc.splice(0, 1);
                ypos = 49;
            }

            for each (var label:Object in labelDesc)
            {
                var field:TextField = new TextField();
                field.defaultTextFormat = new TextFormat(_lang.font(), 13, label.color, true);
                field.antiAliasType = AntiAliasType.ADVANCED;
                field.embedFonts = true;
                field.selectable = false;
                field.autoSize = TextFieldAutoSize.RIGHT;
                field.y = ypos;
                field.x = 50;
                field.width = 10;
                field.text = label.title;
                addChild(field);
                labels.push(field);

                field = new TextField();
                field.defaultTextFormat = new TextFormat(_lang.font(), scoreSize--, label.color, true);
                field.antiAliasType = AntiAliasType.ADVANCED;
                field.embedFonts = true;
                field.selectable = false;
                field.autoSize = TextFieldAutoSize.LEFT;
                field.y = ypos - 22 + (36 - scoreSize);
                field.x = 60;
                field.text = "0";
                addChild(field);
                scores.push(field);

                ypos += 49;
            }
        }

        public function reset():void
        {
            update(0, 0, 0, 0, 0, 0);
        }

        public function update(amazing:int, perfect:int, good:int, average:int, miss:int, boo:int):void
        {
            var offset:int = 0;
            if (options.displayAmazing)
            {
                updateScore(0, amazing);
                updateScore(1, perfect);
                offset = 1;
            }
            else
            {
                updateScore(0, amazing + perfect);
            }

            updateScore(offset + 1, good);
            updateScore(offset + 2, average);
            updateScore(offset + 3, miss);
            updateScore(offset + 4, boo);
        }

        public function updateScore(field:int, score:int):void
        {
            scores[field].text = score.toString();
        }

        public function alternateLayout():void
        {
            var xpos:int = 50;
            var ypos:int = 0;
            var scoreSize:int = 0;
            for (var i:int = 0; i < labels.length; i++)
            {
                var label:TextField = labels[i];
                var score:TextField = scores[i];

                label.x = xpos - label.textWidth;
                label.y = ypos;

                score.x = xpos;
                score.y = ypos - 22 + ++scoreSize;

                xpos += 166;

                if (!((i + 1) % 3))
                {
                    xpos = 50;
                    ypos += 38;
                }
            }
        }

        public function set alignment(val:String):void
        {
            if (val == "right")
            {
                for (var i:int = 0; i < labels.length; i++)
                {
                    var label:TextField = labels[i];
                    var score:TextField = scores[i];

                    score.text = "0";

                    label.autoSize = TextFieldAutoSize.LEFT;
                    label.x = 65;
                    score.autoSize = TextFieldAutoSize.RIGHT;
                    score.x = 40;
                }
            }
        }

        public function set show_labels(val:Boolean):void
        {
            for (var i:int = 0; i < labels.length; i++)
            {
                labels[i].visible = val;
            }
        }
    }
}
