package
{
    import flash.net.SharedObject;
    import flash.utils.ByteArray;

    /** SharedObject-based storage for Ruffle builds where filesystem access is unavailable. */
    public class SharedObjectStorage
    {
        private static var _cache:Object = {};

        private static function getSO(namespace:String):SharedObject
        {
            if (_cache[namespace] == null)
            {
                _cache[namespace] = SharedObject.getLocal(namespace);
            }
            return _cache[namespace];
        }

        public static function getString(namespace:String, key:String):String
        {
            var so:SharedObject = getSO(namespace);
            if (so.data[key] != null)
                return so.data[key] as String;
            return null;
        }

        public static function setString(namespace:String, key:String, value:String):void
        {
            var so:SharedObject = getSO(namespace);
            so.setProperty(key, value);
        }

        public static function getBytes(namespace:String, key:String):ByteArray
        {
            var so:SharedObject = getSO(namespace);
            if (so.data[key] != null)
                return so.data[key] as ByteArray;
            return null;
        }

        public static function setBytes(namespace:String, key:String, value:ByteArray):void
        {
            var so:SharedObject = getSO(namespace);
            so.setProperty(key, value);
        }

        public static function exists(namespace:String, key:String):Boolean
        {
            var so:SharedObject = getSO(namespace);
            return so.data[key] != null;
        }

        public static function remove(namespace:String, key:String):void
        {
            var so:SharedObject = getSO(namespace);
            delete so.data[key];
        }

        public static function flush(namespace:String):void
        {
            var so:SharedObject = getSO(namespace);
            try
            {
                so.flush();
            }
            catch (e:Error)
            {
            }
        }

        public static function flushAll():void
        {
            for (var ns:String in _cache)
            {
                flush(ns);
            }
        }
    }
}
