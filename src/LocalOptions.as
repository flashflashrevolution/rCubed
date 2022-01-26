package
{

    import flash.filesystem.File;

    public class LocalOptions
    {
        private static const FILE_NAME:String = "options.json";

        private static var SO_OBJECT:Object = {};

        public static function init():void
        {
            var json_file:File = File.applicationStorageDirectory.resolvePath(FILE_NAME);

            // Use JSON first
            if (json_file.exists)
            {
                var json_str:String = AirContext.readTextFile(json_file);
                if (json_str != null)
                {
                    try
                    {
                        SO_OBJECT = JSON.parse(json_str);
                        Logger.debug("LocalOptions", "Loaded \"" + json_file.nativePath + "\"")
                    }
                    catch (e:Error)
                    {
                        Logger.error("LocalOptions", "Error parsing \"" + json_file.nativePath + "\"");
                    }
                }
            }
            else
            {
                importFromLocalStore();
            }
        }

        /**
         * Returns a top-level cloned object of all SharedObject variables.
         * @return Object
         */
        public static function getAllVariables():Object
        {
            var out:Object = {};
            for (var key:String in SO_OBJECT)
            {
                out[key] = SO_OBJECT[key];
            }
            return out;
        }

        /**
         * Gets a locally stored value if it exist, if not returns the provided default value.
         * @param key Variable Key
         * @param defaultValue Default Value
         */
        public static function getVariable(key:String, defaultValue:*):*
        {
            if (SO_OBJECT[key] != null)
            {
                return SO_OBJECT[key];
            }
            return defaultValue;
        }

        /**
         * Sets a value into the local store.
         * @param key Variable Key
         * @param value Value
         * @param minDiskSize Minimum Local Store Size
         */
        public static function setVariable(key:String, value:*):void
        {
            SO_OBJECT[key] = value;
        }

        /**
         * Deletes a variable from the local store.
         * @param key Variable Key
         */
        public static function deleteVariable(key:String):void
        {
            delete SO_OBJECT[key];
        }

        /**
         * Writes shared object to file.
         * @param minDiskSize Minimum Local Store Size
         */
        public static function flush(minDiskSize:int = 0):void
        {
            AirContext.writeTextFile(File.applicationStorageDirectory.resolvePath(FILE_NAME), JSON.stringify(SO_OBJECT, null, 2));
        }

        public static function importFromLocalStore():void
        {
            Logger.debug("LocalOptions", "Importing from LocalStore");

            SO_OBJECT["legacy_engines"] = LocalStore.getVariable("legacyEngines", null);
            SO_OBJECT["legacy_default_engine"] = LocalStore.getVariable("legacyDefaultEngine", null);
            SO_OBJECT["rolling_music_offset"] = LocalStore.getVariable("arcMusicOffset", 0);
            SO_OBJECT["mp_text_size"] = LocalStore.getVariable("arcMPSize", 10);
            SO_OBJECT["layouts"] = LocalStore.getVariable("arcLayout", {});
        }
    }
}
