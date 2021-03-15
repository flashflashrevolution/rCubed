package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class OnUserEnterRoom extends TypedSFSEvent
    {
        public var roomId:int;
        public var user:User;

        public function OnUserEnterRoom(params:Object)
        {
            roomId = params.roomId;
            user = params.user;
        }
    }
}
