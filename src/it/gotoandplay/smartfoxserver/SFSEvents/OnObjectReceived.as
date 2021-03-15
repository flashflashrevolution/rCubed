package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class OnObjectReceived extends TypedSFSEvent
    {
        public var obj:Object;
        public var sender:User;

        public function OnObjectReceived(params:Object)
        {
            obj = params.obj;
            sender = params.sender;
        }
    }
}
