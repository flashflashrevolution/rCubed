package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class LogoutSFSEvent extends TypedSFSEvent
    {

        public function LogoutSFSEvent()
        {
            super(SFSEvent.onLogout);
        }
    }
}
