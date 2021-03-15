package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnCreateRoomError extends TypedSFSEvent
    {
        public var error:String;

        public function OnCreateRoomError(params:Object)
        {
            error = params.error;
        }
    }
}
