package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;
    import assets.menu.icons.fa.iconClose;

    dynamic public class PromptInput extends Prompt
    {
        private var _promptFunc:Function = null;

        private var _text:Text;
        private var _textfield:BoxText;
        private var _submit_button:BoxButton;
        private var _close_button:BoxIcon;

        public function PromptInput(parent:DisplayObjectContainer = null, promptTitle:String = "", buttonText:String = "", promptFunc:Function = null, displayAsPassword:Boolean = false)
        {
            super(parent, 400, 120);

            this._promptFunc = promptFunc;
            if (parent != null)
            {
                this._parent = parent;
                parent.addChild(this);
            }

            //- Add Text
            _text = new Text(this, 9, 10, promptTitle, 16);
            _text.setAreaParams(width - 45, 22);

            //- Add Close Button
            _close_button = new BoxIcon(this, _width - 32, 10, 22, 22, new iconClose(), closePrompt);

            //- Add Textfield
            _textfield = new BoxText(this, 10, 43, _width - 21, 26);
            _textfield.field.y += 1;
            _textfield.displayAsPassword = displayAsPassword;
            _textfield.field.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

            //- Add Submit Button
            _submit_button = new BoxButton(this, _width - 130, _height - 39, 120, 29, buttonText, 12, submitPrompt);

            stage.focus = _textfield.field;
        }

        private function closePrompt(e:MouseEvent = null):void
        {
            _textfield.field.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            _textfield.dispose();
            _submit_button.dispose();
            _close_button.dispose();
            _text.dispose();

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
