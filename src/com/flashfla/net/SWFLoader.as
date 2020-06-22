/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.net
{
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.URLRequest;

    public class SWFLoader extends MovieClip
    {
        // Init Vars
        private var mLoader:Loader;
        private var urlRequest:URLRequest;

        // Event Callbacks
        private var callBackComplete:Function;
        private var callBackProgress:Function;
        private var callBackError:Function;

        // Main Constructor
        public function SWFLoader(fileUrl:String, callCompleteBack:Function = null, callProgressBack:Function = null, callError:Function = null)
        {
            callBackComplete = callCompleteBack;
            callBackProgress = callProgressBack;
            callBackError = callError;

            // Load URL Provided
            startLoad(fileUrl);
        }

        // Loads the url provided.
        private function startLoad(fUrl:String):void
        {
            mLoader = new Loader();
            urlRequest = new URLRequest(fUrl);
            mLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteHandler);
            mLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgressHandler);
            mLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            mLoader.load(urlRequest);
        }

        // Removes Loader Listeners
        private function removeListeners():void
        {
            mLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCompleteHandler);
            mLoader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgressHandler);
            mLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
        }

        // Handle IOError Event
        private function ioErrorHandler(event:IOErrorEvent):void
        {
            if (callBackError != null)
                callBackError(event);
            removeListeners();
        }

        // Handles the Complete Event
        private function onCompleteHandler(loadEvent:Event):void
        {
            // Get loaded object data.
            var loadedCont:* = loadEvent.currentTarget.content;

            // Add to stage.
            this.addChild(loadedCont);

            if (callBackComplete != null)
                callBackComplete(loadedCont);
            removeListeners();
        }

        // Handles the Progress Event
        private function onProgressHandler(mProgress:ProgressEvent):void
        {
            var percent:Number = mProgress.bytesLoaded / mProgress.bytesTotal;
            if (callBackProgress != null)
                callBackProgress(percent);
        }
    }
}
