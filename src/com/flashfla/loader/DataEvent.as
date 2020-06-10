package com.flashfla.loader
{
    import flash.events.Event;

    public class DataEvent extends Event
    {
        public var data:*;

        public function DataEvent(type:String, data:*, bubbles:Boolean = false, cancelable:Boolean = false):void
        {
            this.data = data;
            super(type, bubbles, cancelable);
        }
    }
}
