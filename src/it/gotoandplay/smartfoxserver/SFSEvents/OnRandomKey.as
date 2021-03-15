package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnRandomKey extends TypedSFSEvent
    {
        public var key:String;

        public function OnRandomKey(params:Object)
        {
            key = params.key;
        }
    }
}
