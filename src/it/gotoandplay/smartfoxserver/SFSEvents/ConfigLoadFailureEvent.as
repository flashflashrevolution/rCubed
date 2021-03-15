package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ConfigLoadFailureEvent extends TypedSFSEvent
    {
        public var message:String;

        public function ConfigLoadFailureEvent(params:Object)
        {
            super(SFSEvent.onConfigLoadFailure);
            message = params.message;
        }
    }
}
