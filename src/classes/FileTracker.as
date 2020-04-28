package classes
{
    import com.flashfla.utils.NumberUtil;

    public class FileTracker
    {
        public var files:Number = 0;
        public var dirs:Number = 0;
        public var size:Number = 0;
        public var file_paths:Vector.<String> = new Vector.<String>();

        public function get size_human():String
        {
            return NumberUtil.bytesToString(size);
        }

        public function toString():String
        {
            return "[files=" + files + " dirs=" + dirs + " size=" + size + " size_human=" + size_human + "]";
        }
    }

}
