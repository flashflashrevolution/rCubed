package com.flashfla.net
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLVariables;

    dynamic public class WebRequest
    {
        private var _loader:URLLoader;

        private var _url:String;
        private var _funOnComplete:Function;
        private var _funOnError:Function;

        public var active:Boolean = false;
        public var loaded:Boolean = false;

        public function WebRequest(url:String, funOnComplete:Function = null, funOnError:Function = null):void
        {
            this._url = url;
            this._funOnComplete = funOnComplete;
            this._funOnError = funOnError;
        }

        public function load(params:Object = null):void
        {
            _loader = new URLLoader();
            _addListeners();

            var req:URLRequest = new URLRequest(_url);
            if (params)
            {
                req.method = "POST";
                var variables:URLVariables = new URLVariables();
                Constant.addDefaultRequestVariables(variables);
                for (var key:String in params)
                {
                    variables[key] = String(params[key]);
                }
                req.data = variables;
            }
            else
            {
                req.method = "GET";
            }

            _loader.load(req);
        }

        public function get loader():URLLoader
        {
            return _loader;
        }

        protected function e_loadComplete(e:Event):void
        {
            _removeListeners();
            if (_funOnComplete != null)
            {
                _funOnComplete(e);
            }
        }

        protected function e_loadError(e:Event):void
        {
            _removeListeners();
            if (_funOnError != null)
            {
                _funOnError(e);
            }
        }

        //- Listeners
        private function _addListeners():void
        {
            active = true;
            loaded = false;
            _loader.addEventListener(Event.COMPLETE, e_loadComplete);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, e_loadError);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_loadError);
        }

        private function _removeListeners():void
        {
            active = false;
            loaded = true;
            _loader.removeEventListener(Event.COMPLETE, e_loadComplete);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, e_loadError);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, e_loadError);
        }
    }
}
