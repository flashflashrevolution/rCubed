package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnRoundTripResponse extends TypedSFSEvent
    {
        public var elapsed:int;

        public function OnRoundTripResponse(params:Object)
        {
            elapsed = params.elapsed;
        }
    }
}
