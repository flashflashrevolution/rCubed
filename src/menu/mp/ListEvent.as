package menu.mp
{
    import flash.events.Event;

    public class ListEvent extends Event
    {
        public var item:Object;
        public var originalType:String;

        public function ListEvent(type:String, originalType:String, item:Object):void
        {
            super(type);
            this.originalType = originalType;
            this.item = item;
        }
    }
}
