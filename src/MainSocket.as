package
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.Socket;
    import flash.system.Security;
    import com.worlize.websocket.WebSocket;
    import com.worlize.websocket.WebSocketEvent;
    import com.worlize.websocket.WebSocketErrorEvent;
    import flash.utils.ByteArray;
    import com.worlize.websocket.WebSocketMessage;
    import com.worlize.websocket.WebSocketURI;

    public class MainSocket extends Sprite
    {
        private var websocket:WebSocket

        private function handleWebSocketOpen(event:WebSocketEvent):void
        {
            trace("Connected");
            websocket.sendUTF("Hello World!\n");

            var binaryData:ByteArray = new ByteArray();
            binaryData.writeUTF("Hello as Binary Message!");
            websocket.sendBytes(binaryData);
        }

        private function handleWebSocketClosed(event:WebSocketEvent):void
        {
            trace("Disconnected");
        }

        private function handleConnectionFail(event:WebSocketErrorEvent):void
        {
            trace("Connection Failure: " + event.text);
        }

        private function handleWebSocketMessage(event:WebSocketEvent):void
        {
            if (event.message.type === WebSocketMessage.TYPE_UTF8)
            {
                trace("Got message: " + event.message.utf8Data);
            }
            else if (event.message.type === WebSocketMessage.TYPE_BINARY)
            {
                trace("Got binary message of length " + event.message.binaryData.length);

                var buffer:String = "";
                for (var i:int = 0; i < event.message.binaryData.length; i++)
                {
                    buffer += event.message.binaryData[i];
                }
                trace("buffer", buffer);
            }
        }
        private var socket:Socket;

        public function MainSocket()
        {
            trace("MainSocket");
            websocket = new WebSocket(new WebSocketURI("localhost", 4321), "*", "r3");
            websocket.addEventListener(WebSocketEvent.CLOSED, handleWebSocketClosed);
            websocket.addEventListener(WebSocketEvent.OPEN, handleWebSocketOpen);
            websocket.addEventListener(WebSocketEvent.MESSAGE, handleWebSocketMessage);
            websocket.addEventListener(WebSocketErrorEvent.CONNECTION_FAIL, handleConnectionFail);
            websocket.connect();
        }

    }
}
