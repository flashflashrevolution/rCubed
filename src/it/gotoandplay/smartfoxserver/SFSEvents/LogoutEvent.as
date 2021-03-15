package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class LogoutEvent extends TypedSFSEvent
    {

        public function LogoutEvent()
        {
            super(SFSEvent.onLogout);
        }
    }
}
