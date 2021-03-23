package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RandomKeySFSEvent extends TypedSFSEvent
    {
        public var key:String;

        public function RandomKeySFSEvent(params:Object)
        {
            super(SFSEvent.onRandomKey);
            key = params.key;
        }
    }
}
