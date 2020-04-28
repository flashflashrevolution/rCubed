/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.media
{
    import com.flashfla.net.MP3Loader;
    import flash.display.*;
    import flash.events.*;
    import flash.media.*;
    import flash.net.*;

    public class MP3Controller extends MovieClip
    {
        private var _sound:Sound;
        private var _channel:SoundChannel;
        private var _soundTransform:SoundTransform = new SoundTransform(1, 1);
        private var _loaded:Boolean = false;
        private var _loader:MP3Loader;

        public function MP3Controller(url:String, init:Boolean = true)
        {
            this._loader = new MP3Loader(url, init);
            this._loader.addEventListener(Event.OPEN, openHandler);
            this._loader.addEventListener(Event.COMPLETE, completeHandler);
            this._loader.addEventListener(Event.ID3, id3Handler);
            this._loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            this._loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
        }

        public function isLoaded()
        {
            return this._loaded;
        }

        public function getSound()
        {
            if (this._loaded)
            {
                return this._sound;
            }
        }

        public function playSound():void
        {
            this._channel = this._sound.play();
        }

        public function stopSound():void
        {
            this._channel.stop();
        }

        public function setVolume(vol):void
        {
            this._soundTransform.volume = vol;
            this._channel.soundTransform = this._soundTransform;
        }

        public function mute(mute:Boolean):void
        {
            this._soundTransform.volume = (mute == true ? 0 : 1);
            this._channel.soundTransform = this._soundTransform;
        }

        // Class Listeners
        private function openHandler(e:Event):void
        {
            dispatchEvent(e);
        }

        private function completeHandler(e:Event):void
        {
            this._sound = this._loader.getSound();
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
