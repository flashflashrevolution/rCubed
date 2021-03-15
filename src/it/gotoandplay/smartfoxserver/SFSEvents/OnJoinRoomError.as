package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;

    public class OnJoinRoomError extends TypedSFSEvent
    {
        public var error:String;

        public function OnJoinRoomError(params:Object)
        {
            error = params.error;
        }
    }
}
