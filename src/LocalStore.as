package
{
    import flash.net.SharedObject;

    public class LocalStore
    {
        public static function getVariable(name:String, defaultValue:*):*
        {
            var gameSave:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            if (gameSave.data[name] != null)
            {
                return gameSave.data[name];
            }
            return defaultValue;
        }

        public static function setVariable(name:String, value:*, minSize:int = 0):void
        {
            var gameSave:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            gameSave.data[name] = value;
            try
            {
                gameSave.flush(minSize);
            }
            catch (e:Error)
            {
            }
        }

        public static function deleteVariable(name:String):void
        {
            var gameSave:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            delete gameSave.data[name];
            try
            {
                gameSave.flush();
            }
            catch (e:Error)
            {
            }
        }
    }
}
