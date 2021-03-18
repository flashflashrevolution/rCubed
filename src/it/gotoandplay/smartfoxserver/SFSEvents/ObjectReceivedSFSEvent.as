package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.User;

    public class ObjectReceivedSFSEvent extends TypedSFSEvent
    {
        public var obj:Object;
        public var sender:User;

        public function ObjectReceivedSFSEvent(params:Object)
        {
            super(SFSEvent.onObjectReceived);
            obj = params.obj;
            sender = params.sender;
        }
    }
}
