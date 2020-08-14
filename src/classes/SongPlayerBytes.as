package classes
{
    import com.flashfla.media.MP3Extraction;
    import flash.events.Event;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.utils.ByteArray;

    public class SongPlayerBytes
    {
        public var sound:Sound;
        public var soundChannel:SoundChannel;

        public var isPlaying:Boolean = false;
        public var userPaused:Boolean = false;
        public var userStopped:Boolean = false;

        private var pausePosition:int = 0;
        private var _noRepeat:Boolean;

        public function SongPlayerBytes(swfBytes:ByteArray, isMP3File:Boolean = false, noRepeat:Boolean = false)
        {
            if (swfBytes && swfBytes.length > 0)
            {
                if (!isMP3File)
                    swfBytes = MP3Extraction.extractSound(swfBytes);

                swfBytes.position = 0;
                sound = new Sound();
                sound.loadCompressedDataFromByteArray(swfBytes, swfBytes.length);
            }
            _noRepeat = noRepeat;
        }

        public function start():void
        {
            if (!sound || userPaused)
                return;

            stop();
            soundChannel = sound.play(pausePosition);
            soundChannel.soundTransform = GlobalVariables.instance.menuMusicSoundTransform;
            soundChannel.addEventListener(Event.SOUND_COMPLETE, onComplete);
            isPlaying = true;
        }

        private function onComplete(e:Event):void
        {
            SoundChannel(e.target).removeEventListener(e.type, onComplete);
            pausePosition = 0;
            if (_noRepeat)
                isPlaying = false;
            else
                start();
        }

        public function stop():void
        {
            if (soundChannel)
            {
                soundChannel.stop();
                soundChannel.removeEventListener(Event.SOUND_COMPLETE, onComplete);
            }

            isPlaying = false;
        }

        public function userPause():void
        {
            pausePosition = soundChannel.position;
            userPaused = true;
            stop();
        }

        public function userStart():void
        {
            userPaused = userStopped = false;
            start();
        }

        public function userStop():void
        {
            pausePosition = 0;
            userStopped = true;
            stop();
        }
    }

}
