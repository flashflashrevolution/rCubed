package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;

    dynamic public class Prompt extends Sprite
    {
        private var _parent:DisplayObjectContainer = null;
        private var _promptFunc:Function = null;

        private var _box:Box;
        private var _text:Text;
        private var _textfield:BoxText;
        private var _submit_button:BoxButton;
        private var _close_button:BoxButton;

        public function Prompt(parent:DisplayObjectContainer = null, promptWidth:uint = 320, promptTitle:String = "", buttonWidth:uint = 100, buttonText:String = "", promptFunc:Function = null, displayAsPassword:Boolean = false)
        {
            this._promptFunc = promptFunc;
            if (parent != null)
            {
                this._parent = parent;
                parent.addChild(this);
            }

            _box = new Box(this, (Main.GAME_WIDTH - promptWidth) / 2, (Main.GAME_HEIGHT - 55) / 2, false, false);
            _box.setSize(promptWidth, 55);
            _box.borderColor = 0x656565;
            _box.normalAlpha = 1;
            _box.borderAlpha = 1;

            //- Add Text
            _text = new Text(_box, 1, 0, promptTitle, 12, "#000000");
            _text.height = 22;
            _text.width = promptWidth - 2;

            //- Add Close Button
            _close_button = new BoxButton(_box, promptWidth - 18, 3, 15, 15, "", 12, closePrompt);
            _close_button.color = 0xFF0000;
            _close_button.borderColor = 0x880015;
            _close_button.normalAlpha = 0.45;
            _close_button.activeAlpha = 1;
            _close_button.borderAlpha = 1;
            _close_button.borderActiveAlpha = 1;

            //- Add Textfield
            _textfield = new BoxText(_box, 3, 23, promptWidth - buttonWidth - 10, 28);
            _textfield.color = 0x000000;
            _textfield.normalAlpha = 0.045;
            _textfield.activeAlpha = 0.175;
            _textfield.textColor = 0;
            _textfield.borderColor = 0x000000;
            _textfield.borderAlpha = 0.2175;
            _textfield.borderActiveAlpha = 0.455;
            _textfield.displayAsPassword = displayAsPassword;
            _textfield.field.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

            //- Add Submit Button
            _submit_button = new BoxButton(_box, promptWidth - buttonWidth - 3, 23, buttonWidth, 29, buttonText, 12, submitPrompt);
            _submit_button.color = 0x000000;
            _submit_button.normalAlpha = 0.045;
            _submit_button.activeAlpha = 0.175;
            _submit_button.textColor = "#000000";
            _submit_button.borderColor = 0x000000;
            _submit_button.borderAlpha = 0.2175;
            _submit_button.borderActiveAlpha = 0.455;

            stage.focus = _textfield.field;
        }

        private function closePrompt(e:MouseEvent = null):void
        {
            _textfield.field.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            _textfield.dispose();
            _submit_button.dispose();
            _close_button.dispose();
            _text.dispose();
            _box.dispose();

            if (this._parent != null)
                this._parent.removeChild(this);
        }

        private function submitPrompt(e:MouseEvent = null):void
        {
            if (this._promptFunc != null && _textfield.field.text.length > 0)
                this._promptFunc(_textfield.field.text);
            closePrompt();
        }

        private function keyDown(e:KeyboardEvent):void
        {
            if (e.keyCode == Keyboard.ENTER)
            {
                submitPrompt();
            }
            else if (e.keyCode == Keyboard.ESCAPE)
            {
                closePrompt();
            }
        }
    }
}
