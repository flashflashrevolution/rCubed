package com.flashfla.net.events
{

    import it.gotoandplay.smartfoxserver.TypedSFSEvent;
    import com.flashfla.net.Multiplayer;

    public class ExtensionResponseEvent extends TypedSFSEvent
    {
        public var data:Object;

        public function ExtensionResponseEvent(params:Object)
        {
            super(Multiplayer.EVENT_XT_RESPONSE);
            data = params.data;
        }
    }
}
