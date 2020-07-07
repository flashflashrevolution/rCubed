package arc.mp
{
    import com.bit101.components.InputText;
    import com.bit101.components.Window;
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import com.bit101.components.Label;

    public class MultiplayerRoomCreatePrompt extends Window
    {
        public static const EVENT_SEND:String = "ARC_EVENT_PROMPT_SEND";

        public var roomNameLabel:Label;
        public var roomName:InputText;

        public var roomPasswordLabel:Label;
        public var roomPassword:InputText;

        public function MultiplayerRoomCreatePrompt(parent:DisplayObjectContainer, initialTitle:String = "")
        {
            super(parent);

            scaleX = scaleY = 1.5;
            hasCloseButton = true;
            hasMinimizeButton = false;

            roomNameLabel = new Label(this, 0, 0, "Room Name");
            roomName = new InputText(this, 0, 16);
            roomName.width = 180;
            roomName.addEventListener(KeyboardEvent.KEY_DOWN, e_keyDown);

            roomPasswordLabel = new Label(this, 0, 36, "Password: (Optional)");
            roomPassword = new InputText(this, 0, 52);
            roomPassword.width = 180;
            roomPassword.addEventListener(KeyboardEvent.KEY_DOWN, e_keyDown);

            addEventListener(Event.CLOSE, e_closeWindow);

            title = initialTitle;

            setSize(roomName.width, titleBar.height + roomPassword.y + roomPassword.height);
            move(parent.width / 2 - width / 2, parent.height / 2 - height / 2);
            stage.focus = roomName.textField;
        }

        private function e_keyDown(event:KeyboardEvent):void
        {
            if (event.keyCode == Keyboard.ENTER)
            {
                if (roomName.text.length > 0)
                    dispatchEvent(new SFSEvent(EVENT_SEND, {"room": roomName.text, "password": roomPassword.text}));
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
            roomName.removeEventListener(KeyboardEvent.KEY_DOWN, e_keyDown);
            removeEventListener(Event.CLOSE, e_closeWindow);
        }
    }
}
