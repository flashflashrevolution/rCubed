package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnConnection extends TypedSFSEvent
    {
        public var success:Boolean;
        public var error:String;

        public function OnConnection(params:Object)
        {
            success = params.success;
            error = params.error;
        }
    }
}
