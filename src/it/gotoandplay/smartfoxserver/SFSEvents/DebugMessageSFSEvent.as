package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class DebugMessageSFSEvent extends TypedSFSEvent
    {
        public var message:String;

        public function DebugMessageSFSEvent(params:Object)
        {
            super(SFSEvent.onDebugMessage);
            message = params.message;
        }
    }
}
