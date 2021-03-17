package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSUser;

    public class ObjectReceivedSFSEvent extends TypedSFSEvent
    {
        public var obj:Object;
        public var sender:SFSUser;

        public function ObjectReceivedSFSEvent(params:Object)
        {
            super(SFSEvent.onObjectReceived);
            obj = params.obj;
            sender = params.sender;
        }
    }
}
