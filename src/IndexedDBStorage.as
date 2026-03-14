package
{
    import by.blooddy.crypto.Base64;
    import flash.external.ExternalInterface;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    public class IndexedDBStorage
    {
        private static var _callbacks:Dictionary = new Dictionary();

        public static function init():void
        {
            if (ExternalInterface.available)
            {
                ExternalInterface.addCallback("r3_onIdbRead", onIdbRead);
            }
        }

        public static function exists(path:String):Boolean
        {
            if (!ExternalInterface.available)
                return false;
            return ExternalInterface.call("r3_idbExists", path);
        }

        public static function readBytes(path:String, callback:Function):void
        {
            if (!ExternalInterface.available)
            {
                callback(null);
                return;
            }
            var requestId:int = ExternalInterface.call("r3_idbRead", path);
            _callbacks[requestId] = callback;
        }

        public static function writeBytes(path:String, data:ByteArray):void
        {
            if (!ExternalInterface.available)
                return;
            data.position = 0;
            var base64:String = Base64.encode(data);
            ExternalInterface.call("r3_idbWrite", path, base64);
        }

        public static function deleteEntry(path:String):void
        {
            if (!ExternalInterface.available)
                return;
            ExternalInterface.call("r3_idbDelete", path);
        }

        private static function onIdbRead(requestId:int, base64data:String):void
        {
            var callback:Function = _callbacks[requestId];
            if (callback == null)
                return;
            delete _callbacks[requestId];

            if (base64data == null || base64data.length == 0)
            {
                callback(null);
                return;
            }

            var bytes:ByteArray = Base64.decode(base64data);
            callback(bytes);
        }
    }
}
