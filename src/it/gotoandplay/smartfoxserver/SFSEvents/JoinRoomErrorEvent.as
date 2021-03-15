package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class JoinRoomErrorEvent extends TypedSFSEvent
    {
        public var error:String;

        public function JoinRoomErrorEvent(params:Object)
        {
            super(SFSEvent.onJoinRoomError);
            error = params.error;
        }
    }
}
