package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ConfigLoadSuccessSFSEvent extends TypedSFSEvent
    {

        public function ConfigLoadSuccessSFSEvent()
        {
            super(SFSEvent.onConfigLoadSuccess);
        }
    }
}
