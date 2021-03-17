package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import it.gotoandplay.smartfoxserver.data.SFSRoom;

    public class SpectatorSwitchedSFSEvent extends TypedSFSEvent
    {
        public var success:String;
        public var newId:int;
        public var userId:int;
        public var room:SFSRoom;

        public function SpectatorSwitchedSFSEvent(params:Object)
        {
            super(SFSEvent.onSpectatorSwitched);
            success = params.success;
            newId = params.newId;
            userId = params.userId;
            room = params.room;
        }
    }
}
