package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class RoundTripResponseSFSEvent extends TypedSFSEvent
    {
        public var elapsed:int;

        public function RoundTripResponseSFSEvent(params:Object)
        {
            super(SFSEvent.onRoundTripResponse);
            elapsed = params.elapsed;
        }
    }
}
