package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnExtensionResponse extends TypedSFSEvent
    {
        public var dataObj:Object;
        public var type:String;

        public function OnExtensionResponse(params:Object)
        {
            dataObj = params.dataObj;
            type = params.type;
        }
    }
}
