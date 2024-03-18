package classes.ui
{
    import assets.menu.icons.fa.iconClose;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;

    dynamic public class PromptInput extends Prompt
    {
        protected var _callback:Function = null;

        protected var _text:Text;
        protected var _textfield:BoxText;
        protected var _submit_button:BoxButton;
        protected var _close_button:BoxIcon;

        public function PromptInput(parent:DisplayObjectContainer, title:String = "", buttonText:String = "", callback:Function = null, displayAsPassword:Boolean = false)
        {
            super(parent, 400, 120);

            this._callback = callback;

            //- Add Text
            _text = new Text(this, 9, 10, title, 16);
            _text.setAreaParams(width - 45, 22);

            //- Add Close Button
            _close_button = new BoxIcon(this, _width - 32, 10, 22, 22, new iconClose(), closePrompt);

            //- Add Textfield
            _textfield = new BoxText(this, 10, 43, _width - 21, 26);
            _textfield.field.y += 1;
            _textfield.displayAsPassword = displayAsPassword;
            _textfield.field.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            stage.focus = _textfield.field;

            //- Add Submit Button
            _submit_button = new BoxButton(this, _width - 130, _height - 39, 120, 29, buttonText, 12, submitPrompt);
        }

        protected function closePrompt(e:MouseEvent = null):void
        {
            _textfield.field.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            _textfield.dispose();
            _submit_button.dispose();
            _close_button.dispose();
            _text.dispose();

            close();
        }

        protected function submitPrompt(e:MouseEvent = null):void
        {
            if (this._callback != null && _textfield.field.text.length > 0)
                this._callback(_textfield.field.text);

            dispatchEvent(new Event(Event.CLOSE));
            closePrompt();
        }

        protected function keyDown(e:KeyboardEvent):void
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
