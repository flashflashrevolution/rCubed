package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RoundTripResponseEvent extends TypedSFSEvent
    {
        public var elapsed:int;

        public function RoundTripResponseEvent(params:Object)
        {
            super(SFSEvent.onRoundTripResponse);
            elapsed = params.elapsed;
        }
    }
}
