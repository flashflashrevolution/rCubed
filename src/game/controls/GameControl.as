package game.controls
{
    import classes.Language;
    import classes.ui.BoxButton;
    import classes.ui.BoxSlider;
    import classes.ui.Text;
    import classes.ui.ValidatedText;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    public class GameControl extends Sprite
    {
        protected static var _lang:Language = Language.instance;

        public static const FLAG_POSITION:int = (1 << 0);
        public static const FLAG_SIZE:int = (1 << 1);
        public static const FLAG_SCALE:int = (1 << 2);
        public static const FLAG_ROTATE:int = (1 << 3);
        public static const FLAG_OPACITY:int = (1 << 4);

        public var editorLayout:Object;

        public function get id():String
        {
            return "unknown";
        }

        public function set scale(val:Number):void
        {
            scaleX = scaleY = val;
        }

        public function get editorFlags():int
        {
            return FLAG_POSITION | FLAG_SCALE | FLAG_ROTATE | FLAG_OPACITY;
        }

        public function get editorWidth():int
        {
            return 250;
        }

        public function getEditorInterface():GameControlEditor
        {
            var self:GameControl = this;

            addEventListener(Event.CHANGE, e_onExternalChange);

            var out:GameControlEditor = new GameControlEditor(editorWidth);
            out.title.text = _lang.string("editor_component_" + id);
            out.closeButton.addEventListener(MouseEvent.CLICK, e_editorClose);

            if (this is TextStatic)
                out.title.text += " - " + (this as TextStatic).field.text;

            // Elements
            if ((editorFlags & FLAG_POSITION) != 0)
            {
                new Text(out, 10, out.cy, _lang.string("editor_component_x"));
                var inputX:ValidatedText = new ValidatedText(out, 10, out.cy + 20, 80, 20, ValidatedText.R_INT, e_changeHandler);
                inputX.field.y -= 1;

                new Text(out, 105, out.cy, _lang.string("editor_component_y"));
                var inputY:ValidatedText = new ValidatedText(out, 105, out.cy + 20, 80, 20, ValidatedText.R_INT, e_changeHandler);
                inputY.field.y -= 1;

                out.cy += 50;
            }

            if ((editorFlags & FLAG_SIZE) != 0)
            {
                new Text(out, 10, out.cy, _lang.string("editor_component_width"));
                var inputWidth:ValidatedText = new ValidatedText(out, 10, out.cy + 20, 80, 20, ValidatedText.R_INT, e_changeHandler);
                inputWidth.field.y -= 1;

                new Text(out, 105, out.cy, _lang.string("editor_component_height"));
                var inputHeight:ValidatedText = new ValidatedText(out, 105, out.cy + 20, 80, 20, ValidatedText.R_INT, e_changeHandler);
                inputHeight.field.y -= 1;

                out.cy += 50;
            }

            if ((editorFlags & FLAG_SCALE) != 0)
            {
                new Text(out, 10, out.cy, _lang.string("editor_component_scale"));
                var sliderScale:BoxSlider = new BoxSlider(out, 10 + 3, out.cy + 20, editorWidth - 56, 10, e_changeHandler);
                sliderScale.minValue = 0;
                sliderScale.maxValue = 200;

                var sliderScaleDisplay:Text = new Text(out, 10, out.cy, "100%");
                sliderScaleDisplay.setAreaParams(editorWidth - 52, 22, "right");
                var sliderScaleReset:BoxButton = new BoxButton(out, editorWidth - 36, out.cy + 5, 22, 22, "R", 12, e_changeHandler);

                out.cy += 42;
            }

            if ((editorFlags & FLAG_ROTATE) != 0)
            {
                new Text(out, 10, out.cy, _lang.string("editor_component_rotation"));
                var sliderRotate:BoxSlider = new BoxSlider(out, 10 + 3, out.cy + 20, editorWidth - 56, 10, e_changeHandler);
                sliderRotate.minValue = 0;
                sliderRotate.maxValue = 360;

                var sliderRotateDisplay:Text = new Text(out, 10, out.cy, "0°");
                sliderRotateDisplay.setAreaParams(editorWidth - 52, 22, "right");
                var sliderRotateReset:BoxButton = new BoxButton(out, editorWidth - 36, out.cy + 5, 22, 22, "R", 12, e_changeHandler);

                out.cy += 42;
            }

            if ((editorFlags & FLAG_OPACITY) != 0)
            {
                new Text(out, 10, out.cy, _lang.string("editor_component_opacity"));
                var sliderOpacity:BoxSlider = new BoxSlider(out, 10 + 3, out.cy + 20, editorWidth - 56, 10, e_changeHandler);
                sliderOpacity.minValue = 0;
                sliderOpacity.maxValue = 100;

                var sliderOpacityDisplay:Text = new Text(out, 10, out.cy, "100%");
                sliderOpacityDisplay.setAreaParams(editorWidth - 52, 22, "right");
                var sliderOpacityReset:BoxButton = new BoxButton(out, editorWidth - 36, out.cy + 5, 22, 22, "R", 12, e_changeHandler);

                out.cy += 42;
            }

            function updateValues():void
            {
                if ((editorFlags & FLAG_POSITION) != 0)
                {
                    inputX.text = x.toString();
                    inputY.text = y.toString();
                }
                if ((editorFlags & FLAG_SIZE) != 0)
                {
                    inputHeight.text = height.toString();
                    inputWidth.text = width.toString();
                }
                if ((editorFlags & FLAG_SCALE) != 0)
                {
                    sliderScale.slideValue = (editorLayout.scale == null ? 100 : editorLayout.scale * 100);
                    sliderScaleDisplay.text = Math.round(sliderScale.slideValue) + "%";
                }
                if ((editorFlags & FLAG_ROTATE) != 0)
                {
                    sliderRotate.slideValue = (editorLayout.rotation == null ? 0 : editorLayout.rotation);
                    sliderRotateDisplay.text = Math.round(sliderRotate.slideValue) + "°";
                }
                if ((editorFlags & FLAG_OPACITY) != 0)
                {
                    sliderOpacity.slideValue = (editorLayout.alpha == null ? 100 : editorLayout.alpha * 100);
                    sliderOpacityDisplay.text = Math.round(sliderOpacity.slideValue) + "%";
                }
            }

            function e_changeHandler(e:Event):void
            {
                if (e.target == inputX)
                {
                    editorLayout["x"] = inputX.validate(0);
                    self.x = editorLayout["x"];
                }
                else if (e.target == inputY)
                {
                    editorLayout["y"] = inputY.validate(0);
                    self.y = editorLayout["y"];
                }
                else if (e.target == inputWidth)
                {
                    editorLayout["width"] = inputWidth.validate(0);
                    self.width = editorLayout["width"];
                }
                else if (e.target == inputHeight)
                {
                    editorLayout["height"] = inputHeight.validate(0);
                    self.height = editorLayout["height"];
                }
                else if (e.target == sliderScale)
                {
                    var scaleSnap:int = Math.round(sliderScale.slideValue / 5) * 5;
                    sliderScaleDisplay.text = Math.round(scaleSnap) + "%";
                    editorLayout["scale"] = Math.round(scaleSnap) / 100;
                    self.scale = editorLayout["scale"];
                }
                else if (e.target == sliderScaleReset)
                {
                    sliderScale.slideValue = 100;
                    sliderScaleDisplay.text = Math.round(sliderScale.slideValue) + "%";
                    editorLayout["scale"] = 1;
                    self.scale = editorLayout["scale"];
                }
                else if (e.target == sliderRotate)
                {
                    var rotateSnap:int = Math.round(sliderRotate.slideValue / 5) * 5;
                    sliderRotateDisplay.text = Math.round(rotateSnap) + "°";
                    editorLayout["rotation"] = Math.round(rotateSnap);
                    self.rotation = editorLayout["rotation"];
                }
                else if (e.target == sliderRotateReset)
                {
                    sliderRotate.slideValue = 0;
                    sliderRotateDisplay.text = Math.round(sliderRotate.slideValue) + "°";
                    editorLayout["rotation"] = 0;
                    self.rotation = editorLayout["rotation"];
                }
                else if (e.target == sliderOpacity)
                {
                    sliderOpacityDisplay.text = Math.round(sliderOpacity.slideValue) + "%";
                    editorLayout["alpha"] = Math.round(sliderOpacity.slideValue) / 100;
                    self.alpha = editorLayout["alpha"];
                }
                else if (e.target == sliderOpacityReset)
                {
                    sliderOpacity.slideValue = 100;
                    sliderOpacityDisplay.text = Math.round(sliderOpacity.slideValue) + "%";
                    editorLayout["alpha"] = 1;
                    self.alpha = editorLayout["alpha"];
                }
            }

            function e_onExternalChange(e:Event):void
            {
                inputX.text = self.x.toString();
                inputY.text = self.y.toString();
            }

            function e_editorClose(e:MouseEvent):void
            {
                out.dispatchEvent(new Event(Event.CLOSE));

                if (out.parent.contains(out))
                    out.parent.removeChild(out);
            }

            updateValues();

            return out;
        }

        public function drawDebugBounds():void
        {
            var bounds:Rectangle = this.getBounds(this);
            this.graphics.lineStyle(1, 0xFF00FF, 0.35);
            this.graphics.beginFill(0xFF00FF, 0.05);
            this.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
            this.graphics.endFill();

            this.graphics.lineStyle(0, 0, 0);
            this.graphics.beginFill(0xFF00FF, 1);
            this.graphics.drawRect(-2, -2, 4, 4);
            this.graphics.endFill();
        }
    }
}
