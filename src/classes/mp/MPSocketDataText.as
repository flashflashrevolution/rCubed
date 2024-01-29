package classes.mp
{
    import com.flashfla.utils.ObjectUtil;
    import com.worlize.websocket.WebSocketMessage;

    public class MPSocketDataText
    {
        public var type:String;
        public var action:String;
        public var data:Object;

        public function MPSocketDataText(type:String, action:String, data:Object = null)
        {
            this.type = type;
            this.action = action;
            this.data = data;
        }

        public static function parse(message:WebSocketMessage):MPSocketDataText
        {
            try
            {
                if (message.type == WebSocketMessage.TYPE_UTF8)
                {
                    const strData:String = message.utf8Data;
                    if (strData == null || strData.length == 0)
                        return null;

                    // JSON String
                    if (strData.charAt(0) == '{')
                    {
                        const json:Object = JSON.parse(strData);

                        if (json.t == undefined || json.a == undefined)
                            return null;

                        return new MPSocketDataText(json.t, json.a, json.d);
                    }
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
            return "[MPSocketDataText type=" + type + ", action=" + action + "]\n" + ObjectUtil.print_r(data);
        }
    }
}
