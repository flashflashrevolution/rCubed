package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;

    dynamic public class MPCreateRoomPrompt extends Sprite
    {
        private var _parent:DisplayObjectContainer = null;
        private var _promptFunc:Function = null;

        private var _box:Box;
        private var _title:Text;
        private var _room_name_text:Text;
        private var _password_text:Text;
        private var _room_name_textfield:BoxText;
        private var _password_textfield:BoxText;
        private var _submit_button:BoxButton;
        private var _close_button:BoxButton;

        private static var _write_room_name:Boolean = false;
        private static var _write_password:Boolean = false;

        public function MPCreateRoomPrompt(parent:DisplayObjectContainer = null, promptWidth:uint = 320, buttonWidth:uint = 120, promptFunc:Function = null)
        {
            this._promptFunc = promptFunc;
            if (parent != null)
            {
                this._parent = parent;
                parent.addChild(this);
            }

            _box = new Box(this, (Main.GAME_WIDTH - promptWidth) / 2, (Main.GAME_HEIGHT - 125) / 2, false, false);
            _box.setSize(promptWidth, 125);
            _box.borderColor = 0x656565;
            _box.normalAlpha = 1;
            _box.borderAlpha = 1;

            //- Add Text
            _title = new Text(_box, 1, 0, "Create Room", 12, "#000000");
            _title.height = 22;
            _title.width = promptWidth - 2;

            //- Add Close Button
            _close_button = new BoxButton(_box, promptWidth - 18, 3, 15, 15, "", 12, closePrompt);
            _close_button.color = 0xFF0000;
            _close_button.borderColor = 0x880015;
            _close_button.normalAlpha = 0.45;
            _close_button.activeAlpha = 1;
            _close_button.borderAlpha = 1;
            _close_button.borderActiveAlpha = 1;

            //- Add Room Name Text
            _room_name_text = new Text(_box, 1, 22, "Room Name:", 12, "#000000");
            _room_name_text.height = 22;
            _room_name_text.width = promptWidth - 2;

            //- Add Room Name Textfield
            _room_name_textfield = new BoxText(_box, 3, 42, promptWidth - 7, 28);
            _room_name_textfield.color = 0x000000;
            _room_name_textfield.normalAlpha = 0.045;
            _room_name_textfield.activeAlpha = 0.175;
            _room_name_textfield.textColor = 0;
            _room_name_textfield.borderColor = 0x000000;
            _room_name_textfield.borderAlpha = 0.2175;
            _room_name_textfield.borderActiveAlpha = 0.455;
            _room_name_textfield.field.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

            //- Add Password Text
            _password_text = new Text(_box, 1, 73, "Password (Optional):", 12, "#000000");
            _password_text.height = 22;
            _password_text.width = promptWidth - 2;

            //- Add Password Textfield
            _password_textfield = new BoxText(_box, 3, 93, promptWidth - buttonWidth - 10, 28);
            _password_textfield.color = 0x000000;
            _password_textfield.normalAlpha = 0.045;
            _password_textfield.activeAlpha = 0.175;
            _password_textfield.textColor = 0;
            _password_textfield.borderColor = 0x000000;
            _password_textfield.borderAlpha = 0.2175;
            _password_textfield.borderActiveAlpha = 0.455;
            _password_textfield.field.displayAsPassword = true;
            _password_textfield.field.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

            //- Add Submit Button
            _submit_button = new BoxButton(_box, promptWidth - buttonWidth - 3, 93, buttonWidth, 29, "CREATE ROOM", 12, submitPrompt);
            _submit_button.color = 0x000000;
            _submit_button.normalAlpha = 0.045;
            _submit_button.activeAlpha = 0.175;
            _submit_button.textColor = "#000000";
            _submit_button.borderColor = 0x000000;
            _submit_button.borderAlpha = 0.2175;
            _submit_button.borderActiveAlpha = 0.455;

            stage.focus = _room_name_textfield.field;
        }

        private function closePrompt(e:MouseEvent = null):void
        {
            _room_name_textfield.field.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            _password_textfield.field.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            _room_name_text.dispose();
            _room_name_textfield.dispose();
            _password_text.dispose();
            _password_textfield.dispose();
            _submit_button.dispose();
            _close_button.dispose();
            _title.dispose();
            _box.dispose();

            if (this._parent != null)
                this._parent.removeChild(this);
        }

        private function submitPrompt(e:MouseEvent = null):void
        {
            if (this._promptFunc != null && _room_name_textfield.field.text.length > 0)
                this._promptFunc(_room_name_textfield.field.text, _password_textfield.field.text);
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
