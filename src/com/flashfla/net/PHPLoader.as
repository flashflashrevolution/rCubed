/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.net
{
    import flash.display.*;
    import flash.events.*;
    import flash.net.*;

    public class PHPLoader extends EventDispatcher
    {

        private var _loader:URLLoader;
        private var _request:URLRequest;
        private var _data:Object;
        private var _loaded:Boolean = false;

        public function PHPLoader(url:String, init:Boolean = true, format:String = "text")
        {
            this._loader = new URLLoader();
            this._loader.dataFormat = format;
            this._loader.addEventListener(Event.COMPLETE, completeHandler);
            this._loader.addEventListener(Event.OPEN, openHandler);
            this._loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            this._loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            this._loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
            this._loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            this._request = new URLRequest(url);

            if (init)
            {
                try
                {
                    this._loader.load(this._request);
                }
                catch (error:Error)
                {
                    dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
                }
            }
        }

        public function getLoader():URLLoader
        {
            return this._loader;
        }

        public function getLoadedData():Object
        {
            return this._data;
        }

        // Class Listeners
        private function completeHandler(e:Event):void
        {
            this._data = e.target.data;
            this._loaded = true;
            dispatchEvent(e);
        }

        private function openHandler(e:Event):void
        {
            dispatchEvent(e);
        }

        private function progressHandler(e:ProgressEvent):void
        {
            dispatchEvent(e);
        }

        private function securityErrorHandler(e:SecurityErrorEvent):void
        {
            dispatchEvent(e);
        }

        private function httpStatusHandler(e:HTTPStatusEvent):void
        {
            dispatchEvent(e);
        }

        private function ioErrorHandler(e:IOErrorEvent):void
        {
            dispatchEvent(e);
        }
    }
}
