package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class LoginEvent extends TypedSFSEvent
    {
        public var success:Boolean;
        public var name:String;
        public var error:String;

        public function LoginEvent(params:Object)
        {
            super(SFSEvent.onLogin);
            success = params.success;
            name = params.name;
            error = params.error;
        }
    }
}
