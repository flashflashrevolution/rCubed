package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ConfigLoadFailureSFSEvent extends TypedSFSEvent
    {
        public var message:String;

        public function ConfigLoadFailureSFSEvent(params:Object)
        {
            super(SFSEvent.onConfigLoadFailure);
            message = params.message;
        }
    }
}
