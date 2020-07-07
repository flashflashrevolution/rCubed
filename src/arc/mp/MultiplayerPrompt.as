package arc.mp
{
    import com.bit101.components.InputText;
    import com.bit101.components.Window;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class MultiplayerPrompt extends Window
    {
        public static const EVENT_SEND:String = "ARC_EVENT_PROMPT_SEND";

        public var controlInput:InputText;

        public function MultiplayerPrompt(parent:DisplayObjectContainer, initialTitle:String = "", initialText:String = "")
        {
            super(parent);

            scaleX = scaleY = 1.5;
            hasCloseButton = true;
            hasMinimizeButton = false;

            controlInput = new InputText(this, 0, 0, initialText);
            controlInput.width = 180;
            controlInput.addEventListener(KeyboardEvent.KEY_DOWN, e_keyDown);

            addEventListener(Event.CLOSE, e_closeWindow);

            title = initialTitle;

            setSize(controlInput.width, titleBar.height + controlInput.height);
            move(parent.width / 2 - width / 2, parent.height / 2 - height / 2);
            stage.focus = controlInput.textField;
            controlInput.draw();
            controlInput.textField.setSelection(initialText.length, initialText.length);
        }

        private function e_keyDown(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.ENTER)
            {
                if (controlInput.text.length > 0)
                    dispatchEvent(new SFSEvent(EVENT_SEND, {value: controlInput.text}));
                dispatchEvent(new Event(Event.CLOSE));
            }
            else if (event.keyCode == Keyboard.ESCAPE)
            {
                dispatchEvent(new Event(Event.CLOSE));
            }
            //event.stopPropagation();
        }

        private function e_closeWindow(e:Event):void
        {
            parent.removeChild(this);
            controlInput.removeEventListener(KeyboardEvent.KEY_DOWN, e_keyDown);
            removeEventListener(Event.CLOSE, e_closeWindow);
        }
    }
}
