package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class JoinRoomErrorSFSEvent extends TypedSFSEvent
    {
        public var error:String;

        public function JoinRoomErrorSFSEvent(params:Object)
        {
            super(SFSEvent.onJoinRoomError);
            error = params.error;
        }
    }
}
