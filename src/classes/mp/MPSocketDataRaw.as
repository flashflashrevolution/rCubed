package classes.mp
{

    import com.worlize.websocket.WebSocketMessage;
    import flash.utils.ByteArray;

    public class MPSocketDataRaw
    {
        public var type:Number;
        public var action:Number;
        public var data:ByteArray;

        public function MPSocketDataRaw(type:Number, action:Number, data:ByteArray = null)
        {
            this.type = type;
            this.action = action;
            this.data = data;
        }

        public static function parse(message:WebSocketMessage):MPSocketDataRaw
        {
            try
            {
                if (message == null)
                    return null;

                // Binary Command
                if (message.type === WebSocketMessage.TYPE_BINARY)
                {
                    if (message.binaryData == null || message.binaryData.length == 0)
                        return null;

                    var data:ByteArray = message.binaryData;
                    var type:Number = data.readUnsignedByte();
                    var action:Number = data.readUnsignedByte();

                    data.position = 0;

                    return new MPSocketDataRaw(type, action, data);
                }
            }
            catch (err)
            {
                trace("parseMessage err:", err);
            }

            return null;
        }

        public function toString():String
        {
            return "[MPSocketDataRaw type=" + type + ", action=" + action + "]";
        }
    }
}
