package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RandomKeyEvent extends TypedSFSEvent
    {
        public var key:String;

        public function RandomKeyEvent(params:Object)
        {
            super(SFSEvent.onRandomKey);
            key = params.key;
        }
    }
}
