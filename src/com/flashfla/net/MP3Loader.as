/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.net
{
    import flash.display.MovieClip;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.media.Sound;
    import flash.net.URLRequest;

    public class MP3Loader extends MovieClip
    {
        private var _sound:Sound;
        private var _request:URLRequest;
        private var _loaded:Boolean = false;

        public function MP3Loader(url:String, init:Boolean = true)
        {
            this._sound = new Sound();
            this._sound.addEventListener(Event.OPEN, openHandler);
            this._sound.addEventListener(Event.COMPLETE, completeHandler);
            this._sound.addEventListener(Event.ID3, id3Handler);
            this._sound.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            this._sound.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            this._request = new URLRequest(url);

            if (init)
            {
                try
                {
                    this._sound.load(this._request);
                }
                catch (error:Error)
                {
                    dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
                }
            }
        }

        public function loadMusic()
        {
            this._sound.load(this._request);
        }

        public function isLoaded()
        {
            return this._loaded;
        }

        public function getSound()
        {
            return this._sound;
        }

        // Class Listeners
        private function openHandler(e:Event):void
        {
            dispatchEvent(e);
        }

        private function completeHandler(e:Event):void
        {
            this._loaded = true;
            dispatchEvent(e);
        }

        private function id3Handler(e:Event):void
        {
            dispatchEvent(e);
        }

        private function progressHandler(e:ProgressEvent):void
        {
            dispatchEvent(e);
        }

        private function ioErrorHandler(e:IOErrorEvent):void
        {
            dispatchEvent(e);
        }
    }
}
