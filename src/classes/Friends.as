package classes
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;

    public class Friends extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:Friends = null;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _loader:URLLoader;
        private var _isLoaded:Boolean = false;
        private var _isLoading:Boolean = false;
        private var _loadError:Boolean = false;

        ///- Public Locals
        public var list:Object = {};

        ///- Constructor
        public function Friends(en:SingletonEnforcer)
        {
            if (en == null)
                throw Error("Multi-Instance Blocked");
        }

        public static function get instance():Friends
        {
            if (_instance == null)
                _instance = new Friends(new SingletonEnforcer());
            return _instance;
        }

        public function isLoaded():Boolean
        {
            return _isLoaded && !_loadError;
        }

        public function isError():Boolean
        {
            return _loadError;
        }

        ///- Friends Loading
        public function load():void
        {
            // Kill old Loading Stream
            if (_loader && _isLoading)
            {
                removeLoaderListeners();
                _loader.close();
            }

            // Load New
            _isLoaded = false;
            _loadError = false;
            _loader = new URLLoader();
            addLoaderListeners();

            var req:URLRequest = new URLRequest(Constant.USER_FRIENDS_URL + "?d=" + new Date().getTime());
            var requestVars:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(requestVars);
            requestVars.session = _gvars.userSession;
            req.data = requestVars;
            req.method = URLRequestMethod.POST;
            _loader.load(req);
            _isLoading = true;
        }

        private function friendsLoadComplete(e:Event):void
        {
            removeLoaderListeners();
            try
            {
                list = JSON.parse(e.target.data);
                _isLoaded = true;
                _loadError = false;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_COMPLETE));
            }
            catch (e:Error)
            {
                _loadError = true;
                this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
            }
        }

        private function friendsLoadError(e:Event = null):void
        {
            removeLoaderListeners();
            this.dispatchEvent(new Event(GlobalVariables.LOAD_ERROR));
        }

        private function addLoaderListeners():void
        {
            _loader.addEventListener(Event.COMPLETE, friendsLoadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, friendsLoadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, friendsLoadError);
        }

        private function removeLoaderListeners():void
        {
            _loadError = true;
            _loader.removeEventListener(Event.COMPLETE, friendsLoadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, friendsLoadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, friendsLoadError);
        }
    }
}

class SingletonEnforcer
{
}
