package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.SFSEvents.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.data.User;

    public class OnUserVariablesUpdate extends TypedSFSEvent
    {
        public var user:User;
        public var changedVars:Array;

        public function OnUserVariablesUpdate(params:Object)
        {
            user = params.user;
            changedVars = params.changedVars;
        }
    }
}
