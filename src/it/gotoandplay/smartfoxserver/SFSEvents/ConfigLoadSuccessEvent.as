package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ConfigLoadSuccessEvent extends TypedSFSEvent
    {

        public function ConfigLoadSuccessEvent()
        {
            super(SFSEvent.onConfigLoadSuccess);
        }
    }
}
