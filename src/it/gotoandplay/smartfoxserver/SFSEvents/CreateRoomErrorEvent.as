package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;

    public class CreateRoomErrorEvent extends TypedSFSEvent
    {
        public var error:String;

        public function CreateRoomErrorEvent(params:Object)
        {
            super(SFSEvent.onCreateRoomError);
            error = params.error;
        }
    }
}
