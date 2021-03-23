package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class ExtensionResponseSFSEvent extends TypedSFSEvent
    {
        public var dataObj:Object;
        public var protocol:String;

        public function ExtensionResponseSFSEvent(params:Object)
        {
            super(SFSEvent.onExtensionResponse);
            dataObj = params.dataObj;
            protocol = params.protocol;
        }
    }
}
