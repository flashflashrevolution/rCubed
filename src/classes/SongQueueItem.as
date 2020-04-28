package classes
{

    public class SongQueueItem
    {
        public var name:String;
        public var items:Array;

        public function SongQueueItem(name:String, items:Array)
        {
            this.name = name;
            this.items = items;
        }

        public function toString():String
        {
            return JSON.stringify(this);
        }

        public static function fromString(json:String):SongQueueItem
        {
            try
            {
                var obj:Object = JSON.parse(json);
                return new SongQueueItem(obj.name, obj.items);
            }
            catch (e:Error)
            {

            }

            return new SongQueueItem("invalid", []);
        }
    }
}
