package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ConnectionLostSFSEvent extends TypedSFSEvent
    {

        public function ConnectionLostSFSEvent()
        {
            super(SFSEvent.onConnectionLost);
        }
    }
}
