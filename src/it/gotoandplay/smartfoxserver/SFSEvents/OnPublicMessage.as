package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class OnPublicMessage extends TypedSFSEvent
    {
        public var message:String;
        public var sender:User;
        public var roomId:int;

        public function OnPublicMessage(params:Object)
        {
            message = params.message;
            sender = params.sender;
            roomId = params.roomId;
        }
    }
}
