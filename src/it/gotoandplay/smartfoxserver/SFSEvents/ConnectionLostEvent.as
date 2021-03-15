package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ConnectionLostEvent extends TypedSFSEvent
    {

        public function ConnectionLostEvent()
        {
            super(SFSEvent.onConnectionLost);
        }
    }
}
