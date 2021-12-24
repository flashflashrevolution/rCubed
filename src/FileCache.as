package
{

    public class FileCache
    {
        private var CACHE:Object;

        private var CACHE_FILE_NAME:String;
        private var CACHE_FILE_VERSION:int = 1;

        private var _cacheFound:Boolean = false;
        private var _didLoad:Boolean = false;
        private var _isDirty:Boolean = false;

        public function FileCache(cache_name:String, cache_version:Number)
        {
            CACHE_FILE_NAME = cache_name;
            CACHE_FILE_VERSION = cache_version;
            CACHE = getDefaultCacheObject();

            load();
        }

        public function load():void
        {
            if (_didLoad)
                return;

            _didLoad = true;

            var data:String = AirContext.readTextFile(AirContext.getAppFile(CACHE_FILE_NAME));
            if (data != null && data.length > 2)
            {
                try
                {
                    var FILE_CACHE:Object = JSON.parse(data);

                    // valid cache & version
                    if (((FILE_CACHE["cache_version"] || 0) == CACHE_FILE_VERSION) && FILE_CACHE["keys"] != null)
                    {
                        CACHE = FILE_CACHE;
                        _cacheFound = true;
                    }
                    Logger.debug(this, "Loaded Cache \"" + CACHE_FILE_NAME + "\"");
                }
                catch (e:Error)
                {
                    Logger.error(this, "Error on Cache \"" + CACHE_FILE_NAME + "\"");
                }
            }
            else
            {
                Logger.error(this, "Cache \"" + CACHE_FILE_NAME + "\" missing or null");
            }
        }

        public function save():void
        {
            if (_isDirty)
            {
                AirContext.writeTextFile(AirContext.getAppFile(CACHE_FILE_NAME), JSON.stringify(CACHE));
                _isDirty = false;
                _cacheFound = true;
                Logger.debug(this, "Saving Cache \"" + CACHE_FILE_NAME + "\"");
            }
            else
            {
                Logger.debug(this, "No Cache \"" + CACHE_FILE_NAME + "\" changes to save");
            }
        }

        public function getValue(path:String):Object
        {
            return CACHE["keys"][path] || null;
        }

        public function setValue(path:String, value:Object):void
        {
            CACHE["keys"][path] = value;
            _isDirty = true;
        }

        public function clear():void
        {
            CACHE = getDefaultCacheObject();
            _isDirty = true;
        }

        public function get cacheFound():Boolean
        {
            return _cacheFound;
        }

        public function get keys():Vector.<String>
        {
            var v:Vector.<String> = new <String>[];

            for (var key:String in CACHE["keys"])
            {
                v[v.length] = key;
            }

            return v;
        }

        public function get cache():Object
        {
            return CACHE["keys"];
        }

        private function getDefaultCacheObject():Object
        {
            return {"cache_version": CACHE_FILE_VERSION,
                    "keys": {}};
        }
    }
}
