package
{

    import flash.filesystem.File;

    public class LocalOptions
    {
        private static const FILE_NAME:String = "options.json";

        private static var SO_OBJECT:Object = {};

        public static function init():void
        {
            var json_file:File = AirContext.getAppFile(FILE_NAME);

            // Use JSON first
            if (json_file.exists)
            {
                var json_str:String = AirContext.readTextFile(json_file);
                if (json_str != null)
                {
                    try
                    {
                        SO_OBJECT = JSON.parse(json_str);
                        Logger.info("LocalOptions", "Loaded \"" + FILE_NAME + "\"")
                    }
                    catch (e:Error)
                    {
                        Logger.error("LocalOptions", "Error parsing \"" + FILE_NAME + "\"");
                    }
                }
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
            AirContext.writeTextFile(AirContext.getAppFile(FILE_NAME), JSON.stringify(SO_OBJECT, null, 2));
        }
    }
}
