package it.gotoandplay.smartfoxserver.SFSEvents
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import it.gotoandplay.smartfoxserver.SFSEvent;
    import classes.User;

    public class UserVariablesUpdateSFSEvent extends TypedSFSEvent
    {
        public var user:User;
        public var changedVars:Array;

        public function UserVariablesUpdateSFSEvent(params:Object)
        {
            super(SFSEvent.onUserVariablesUpdate);
            user = params.user;
            changedVars = params.changedVars;
        }
    }
}
