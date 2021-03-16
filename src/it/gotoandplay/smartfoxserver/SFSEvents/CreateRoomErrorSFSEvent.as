package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class CreateRoomErrorSFSEvent extends TypedSFSEvent
    {
        public var error:String;

        public function CreateRoomErrorSFSEvent(params:Object)
        {
            super(SFSEvent.onCreateRoomError);
            error = params.error;
        }
    }
}
