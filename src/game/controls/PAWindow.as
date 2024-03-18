package game.controls
{
    import classes.ui.BoxCheck;
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.text.AntiAliasType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import game.GameOptions;

    public class PAWindow extends GameControl
    {
        public var scores:Array;
        private var labels:Array;

        private var options:GameOptions;

        public function PAWindow(options:GameOptions, parent:DisplayObjectContainer)
        {
            if (parent)
                parent.addChild(this);

            this.options = options;

            labels = new Array();
            scores = new Array();

            var scoreSize:int = 36;

            var labelDesc:Array = [{color: options.judgeColors[0], title: _lang.stringSimple("game_amazing")},
                {color: options.judgeColors[1], title: _lang.stringSimple("game_perfect")},
                {color: options.judgeColors[2], title: _lang.stringSimple("game_good")},
                {color: options.judgeColors[3], title: _lang.stringSimple("game_average")},
                {color: options.judgeColors[4], title: _lang.stringSimple("game_miss")},
                {color: options.judgeColors[5], title: _lang.stringSimple("game_boo")}];

            if (!options.displayAmazing)
                labelDesc.splice(0, 1);

            for each (var label:Object in labelDesc)
            {
                var field:TextField = new TextField();
                field.defaultTextFormat = new TextFormat(_lang.font(), 13, label.color, true);
                field.antiAliasType = AntiAliasType.ADVANCED;
                field.embedFonts = true;
                field.selectable = false;
                field.autoSize = TextFieldAutoSize.LEFT;
                field.text = label.title;
                addChild(field);
                labels.push(field);

                field = new TextField();
                field.defaultTextFormat = new TextFormat(_lang.font(), scoreSize--, label.color, true);
                field.antiAliasType = AntiAliasType.ADVANCED;
                field.embedFonts = true;
                field.selectable = false;
                field.autoSize = TextFieldAutoSize.LEFT;
                field.text = "0";
                addChild(field);
                scores.push(field);
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

        public function set type(val:Number):void
        {
            var xpos:int = 50;
            var ypos:int = 0;
            var scoreSize:int = 36;

            var label:TextField;
            var score:TextField;

            // --- / ---
            if (val == 1)
            {
                scoreSize = 0;
            }
            // - / - / - / - / - / -
            else
            {
                if (!options.displayAmazing)
                    ypos = 49;
            }

            for (var i:int = 0; i < labels.length; i++)
            {
                label = labels[i];
                score = scores[i];

                // LEFT/RIGHT - 2 Lines
                if (val == 1)
                {
                    label.x = xpos - label.textWidth;
                    label.y = ypos;

                    score.x = xpos + 5;
                    score.y = ypos - 22 + scoreSize++;

                    xpos += 166;

                    if (!((i + 1) % 3))
                    {
                        xpos = 50;
                        ypos += 42;
                    }
                }

                // Normal - 6 Lines
                else
                {
                    label.x = xpos - label.textWidth;
                    label.y = ypos;

                    score.x = xpos + 5;
                    score.y = ypos - 22 + (36 - scoreSize--);

                    ypos += 49;
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

        override public function get id():String
        {
            return GameLayoutManager.LAYOUT_PA;
        }

        override public function getEditorInterface():GameControlEditor
        {
            var self:PAWindow = this;

            var out:GameControlEditor = super.getEditorInterface();

            new Text(out, 10, out.cy, _lang.string("editor_component_show_labels"));
            var checkLabels:BoxCheck = new BoxCheck(out, 10 + 3, out.cy + 22, e_changeHandler);
            checkLabels.checked = (editorLayout.show_labels == null || editorLayout.show_labels);

            out.cy += 42;

            new Text(out, 10, out.cy, _lang.string("editor_component_alt_layout"));
            var checkLayout:BoxCheck = new BoxCheck(out, 10 + 3, out.cy + 22, e_changeHandler);
            checkLayout.checked = (editorLayout.type == 1);

            out.cy += 42;

            function e_changeHandler(e:Event):void
            {
                if (e.target == checkLabels)
                {
                    checkLabels.checked = !checkLabels.checked;
                    editorLayout["show_labels"] = checkLabels.checked;
                    self.show_labels = editorLayout["show_labels"];
                }
                else if (e.target == checkLayout)
                {
                    checkLayout.checked = !checkLayout.checked;
                    editorLayout["type"] = checkLayout.checked ? 1 : 0;
                    self.type = editorLayout["type"];
                }
            }

            return out;
        }
    }
}
