package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnConfigLoadFailure extends TypedSFSEvent
    {
        public var message:String;

        public function OnConfigLoadFailure(params:Object)
        {
            message = params.message;
        }
    }
}
