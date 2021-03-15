package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ConnectionEvent extends TypedSFSEvent
    {
        public var success:Boolean;
        public var error:String;

        public function ConnectionEvent(params:Object)
        {
            super(SFSEvent.onConnection);
            success = params.success;
            error = params.error;
        }
    }
}
