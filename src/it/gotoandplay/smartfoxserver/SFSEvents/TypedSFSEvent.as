package it.gotoandplay.smartfoxserver.SFSEvents
{
    import flash.events.Event;

    public class TypedSFSEvent extends Event
    {
        public function TypedSFSEvent(type:String)
        {
            super(type);
        }
    }
}
