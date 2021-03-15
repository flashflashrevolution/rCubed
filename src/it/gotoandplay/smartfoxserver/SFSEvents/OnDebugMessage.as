package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnDebugMessage extends TypedSFSEvent
    {
        public var message:String;

        public function OnDebugMessage(params:Object)
        {
            message = params.message;
        }
    }
}
