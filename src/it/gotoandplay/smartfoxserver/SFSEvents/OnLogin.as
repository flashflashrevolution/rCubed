package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnLogin extends TypedSFSEvent
    {
        public var success:Boolean;
        public var name:String;
        public var error:String;

        public function OnLogin(params:Object)
        {
            success = params.success;
            name = params.name;
            error = params.error;
        }
    }
}
