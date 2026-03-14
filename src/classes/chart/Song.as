package classes.chart
{
    import by.blooddy.crypto.Base64;
    import by.blooddy.crypto.MD5;
    import classes.SongInfo;
    import classes.chart.parse.ChartFFRLegacy;
    import com.flashfla.media.MP3Extraction;
    import com.flashfla.media.SwfSilencer;
    import com.flashfla.net.ForcibleLoader;
    import com.flashfla.utils.TimeUtil;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.MovieClip;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SampleDataEvent;
    import flash.events.SecurityErrorEvent;
    import flash.external.ExternalInterface;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundMixer;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;
    import game.GameOptions;

    public class Song extends EventDispatcher
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;

        public var musicLoader:*;

        public var id:uint;
        public var songInfo:SongInfo;
        public var type:String;

        public var isDirty:Boolean = true;

        private var baseSound:Sound;
        public var sound:Sound;
        public var background:MovieClip;
        public var chart:NoteChart;

        public var noteMod:NoteMod;
        public var options:GameOptions;
        public var soundChannel:SoundChannel;
        public var musicPausePosition:int;
        public var musicIsPlaying:Boolean = false;
        public var mp3Frame:int = 0;
        public var mp3Rate:Number = 1;

        private var rateReverse:Boolean = false;
        private var rateRate:Number = 1;
        private var rateSample:int = 0;
        private var rateSampleCount:int = 0;
        private var rateSamples:ByteArray = new ByteArray();

        private var baseSoundBytes:ByteArray;
        public var isAudioReady:Boolean = true;
        private var _pendingStart:int = -1;
        private var _useJSAudio:Boolean = false;

        public var isLoaded:Boolean = false;
        public var isChartLoaded:Boolean = false;
        public var isMusicLoaded:Boolean = false;
        public var loadFail:Boolean = false;

        public var isMusicLoaderLoading:Boolean = false;

        public var bytesSWF:ByteArray = null;
        public var bytesLoaded:uint = 0;
        public var bytesTotal:uint = 0;

        private var musicForcibleLoader:ForcibleLoader;

        public var musicStartFrames:int = 0;
        public var musicStartTime:int = 0;

        private var localFileData:ByteArray = null;
        private var localFileHash:String = "";

        public function Song(songInfo:SongInfo, doLoad:Boolean = true):void
        {
            this.songInfo = songInfo;
            this.id = songInfo.level;
            this.type = songInfo.chart_type || NoteChart.FFR_MP3;

            options = _gvars.options;

            if (type == "EDITOR")
            {
                chart = new NoteChart(null);
                return;
            }

            if (doLoad)
                load();
        }

        public function unload():void
        {
            removeLoaderListeners();
            isLoaded = isChartLoaded = isMusicLoaded = false;
            loadFail = true;

            if (musicLoader && isMusicLoaderLoading)
            {
                musicLoader.close();
                isMusicLoaderLoading = false;
            }

            background = null;
            chart = null;
        }

        private function load():void
        {
            var cachePath:String = AirContext.getSongCachePath(this) + "data.bin";
            var cacheKey:uint = songInfo.engine ? 0 : id;

            if (_gvars.air_useLocalFileCache && AirContext.doesFileExist(cachePath))
            {
                CONFIG::air
                {
                    localFileData = AirContext.readFileByPath(cachePath, cacheKey);
                    loadWithCacheData();
                    return;
                }
                if (!CONFIG::air)
                {
                    AirContext.readFileByPathAsync(cachePath, cacheKey, function(data:ByteArray):void
                    {
                        if (loadFail)
                            return;
                        localFileData = data;
                        loadWithCacheData();
                    });
                    return;
                }
            }

            loadFromNetwork("");
        }

        private function loadWithCacheData():void
        {
            var url_file_hash:String = "";
            if (localFileData)
            {
                localFileHash = MD5.hashBytes(localFileData);
                url_file_hash = "hash=" + localFileHash + "&";

                if (songInfo.engine)
                {
                    if (localFileHash == songInfo.swf_hash && type == NoteChart.FFR_MP3)
                    {
                        removeLoaderListeners();
                        musicLoader = new Loader();
                        addLoaderListeners(true);
                        musicLoader.loadBytes(localFileData, AirContext.getLoaderContext());
                        return;
                    }
                }
            }

            loadFromNetwork(url_file_hash);
        }

        private function loadFromNetwork(url_file_hash:String):void
        {
            switch (type)
            {
                case NoteChart.FFR_MP3:
                    musicLoader = new URLLoader();
                    addLoaderListeners();
                    musicLoader.dataFormat = URLLoaderDataFormat.BINARY;
                    musicLoader.load(new URLRequest(urlGen(url_file_hash)));
                    isMusicLoaderLoading = true;
                    break;

                default:
                    break;
            }
        }

        public function get progress():int
        {
            if (musicLoader != null)
                return Math.floor(((bytesLoaded / bytesTotal) * 99) + (isChartLoaded ? 1 : 0));

            return 0;
        }

        public function getMusicContentLoader(isLoader:Boolean = false):Object
        {
            if (isLoader)
                return musicLoader.contentLoaderInfo;

            return type == NoteChart.FFR_MP3 ? musicLoader : musicLoader.contentLoaderInfo;
        }

        private function urlGen(fileHash:String = ""):String
        {
            if (songInfo.engine)
                return ChartFFRLegacy.songUrl(songInfo);

            return URLs.resolve(URLs.SONG_DATA_URL) + "?" + fileHash + "id=" + songInfo.play_hash + (_gvars.userSession != "0" ? "&session=" + _gvars.userSession : "");
        }

        private function addLoaderListeners(isLoader:Boolean = false):void
        {
            var music:Object = getMusicContentLoader(isLoader);

            if (music)
            {
                music.addEventListener(Event.COMPLETE, musicCompleteHandler);
                music.addEventListener(IOErrorEvent.IO_ERROR, musicLoadError);
                music.addEventListener(SecurityErrorEvent.SECURITY_ERROR, musicLoadError);
            }

            if (musicLoader)
                musicLoader.addEventListener(ProgressEvent.PROGRESS, musicProgressHandler);
        }

        private function removeLoaderListeners():void
        {
            var music:Object = getMusicContentLoader();

            if (music)
            {
                music.removeEventListener(Event.COMPLETE, musicCompleteHandler);
                music.removeEventListener(IOErrorEvent.IO_ERROR, musicLoadError);
                music.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, musicLoadError);
            }

            if (musicLoader)
                musicLoader.removeEventListener(ProgressEvent.PROGRESS, musicProgressHandler);
        }

        public function loadComplete():void
        {
            if (isChartLoaded && isMusicLoaded)
            {
                removeLoaderListeners();
                isLoaded = true;
                dispatchEvent(new Event(Event.COMPLETE));
            }
        }

        private function musicProgressHandler(e:ProgressEvent):void
        {
            bytesLoaded = e.bytesLoaded;
            bytesTotal = e.bytesTotal;
        }

        private function musicCompleteHandler(e:Event):void
        {
            Logger.success(this, "Music Load Success");
            var chartData:ByteArray;
            if (type == NoteChart.FFR_MP3)
            {
                if (e.target is URLLoader)
                    chartData = e.target.data;
                else if (e.target is LoaderInfo)
                    chartData = e.target.bytes;

                bytesLoaded = bytesTotal = chartData.length; // Update Progress Bar in case.

                // Check 404 Response
                if (chartData.length == 0 || (chartData.length == 3 && chartData.readUTFBytes(3) == "404"))
                {
                    loadFail = true;
                    return;
                }

                // Check for server response for matching hash. Encode Compressed SWF Data
                var storeChartData:ByteArray;
                if (_gvars.air_useLocalFileCache)
                {
                    // Alt Engine has Data
                    if (this.songInfo.engine && localFileData)
                    {

                    }
                    else if (chartData.length == 3)
                    {
                        chartData.position = 0;
                        var code:String = chartData.readUTFBytes(3);
                        if (code == "404")
                        {
                            loadFail = true;
                            return;
                        }
                        if (code == "403")
                        {
                            chartData = localFileData;
                            bytesLoaded = bytesTotal = localFileData.length;
                        }
                    }
                    else
                    {
                        storeChartData = AirContext.encodeData(chartData, (this.songInfo.engine ? 0 : this.id));
                    }
                }

                // Parse Chart
                chart = NoteChart.parseChart(NoteChart.FFR_LEGACY, songInfo, chartData);
                chartLoadComplete(e);

                // Extract MP3 Data and load into Sound.
                var metadata:Object = {};
                loadSoundBytes(MP3Extraction.extractSound(chartData, metadata));
                mp3Frame = metadata.frame - 2;
                mp3Rate = MP3Extraction.formatRate(metadata.format) / 44100;

                // Generate a SWF containing no audio, used as a background.
                var mloader:Loader = new Loader();
                var mbytes:ByteArray = SwfSilencer.stripSound(chartData);
                mloader.contentLoaderInfo.addEventListener(Event.COMPLETE, backgoundCompleteHandler);
                if (!mbytes)
                {
                    loadFail = true;
                    return;
                }
                mloader.loadBytes(mbytes, AirContext.getLoaderContext());

                // Store SWF
                if (_gvars.air_useLocalFileCache && storeChartData)
                {
                    try
                    {
                        Logger.info(this, "Saving Cache File for " + this.id + " / " + this.songInfo.level_id);
                        AirContext.writeFileByPath(AirContext.getSongCachePath(this) + "data.bin", storeChartData);
                    }
                    catch (err:Error)
                    {
                        Logger.error(this, "Cache write failed: " + Logger.exception_error(err));
                    }
                }

                loadComplete();
            }

            bytesSWF = chartData;
        }

        private function backgoundCompleteHandler(e:Event):void
        {
            var info:LoaderInfo = e.currentTarget as LoaderInfo;
            background = info.content as MovieClip;

            isMusicLoaded = true;
            loadComplete();
        }

        private function chartLoadComplete(e:Event = null):void
        {
            Logger.success(this, "Chart Load Success");
            Logger.info(this, "Chart parsed with " + chart.Notes.length + " notes, " + (chart.Notes.length > 0 ? TimeUtil.convertToHHMMSS(chart.Notes[chart.Notes.length - 1].time) : "0:00") + " length.");

            isChartLoaded = true;
            loadComplete();
        }

        private function musicLoadError(err:ErrorEvent = null):void
        {
            Logger.error(this, "Music Load Error: " + Logger.event_error(err));
            isMusicLoaderLoading = false;
            removeLoaderListeners();
            loadFail = true;
        }

        public function handleDirty(options:GameOptions):void
        {
            if (!isDirty)
                return;

            // Remove Old Sound
            if (sound != null)
            {
                sound.removeEventListener("sampleData", onReverseSound);
                sound.removeEventListener("sampleData", onRateSound);
                sound = null;
            }

            if (soundChannel)
            {
                soundChannel.removeEventListener(Event.SOUND_COMPLETE, stopSound);
                soundChannel.stop();
            }

            noteMod = new NoteMod(this, options);
            rateReverse = options.modEnabled("reverse");
            rateRate = options.songRate;

            // Add Sound
            if (rateRate != 1 || rateReverse)
            {
                CONFIG::air
                {
                    sound = new Sound();

                    if (rateReverse)
                        sound.addEventListener("sampleData", onReverseSound);
                    else
                        sound.addEventListener("sampleData", onRateSound);
                }
                if (!CONFIG::air)
                {
                    // Sound.extract() / SampleDataEvent are unimplemented in Ruffle
                    _useJSAudio = true;
                    buildResampledSound();
                }
            }
            else
            {
                _useJSAudio = false;
                sound = baseSound;
                isAudioReady = true;
            }

            isDirty = false;
        }

        public function loadSoundBytes(bytes:ByteArray):void
        {
            bytes.position = 0;
            if (!CONFIG::air)
            {
                baseSoundBytes = new ByteArray();
                baseSoundBytes.writeBytes(bytes, 0, bytes.length);
            }
            baseSound = new Sound();
            baseSound.loadCompressedDataFromByteArray(bytes, bytes.length);
        }

        private function buildResampledSound():void
        {
            if (!baseSoundBytes || !ExternalInterface.available)
            {
                Logger.error(this, "Cannot resample: no MP3 data or ExternalInterface unavailable");
                _useJSAudio = false;
                sound = baseSound;
                return;
            }

            isAudioReady = false;
            _pendingStart = -1;

            ExternalInterface.addCallback("r3_onResampleReady", onResampleReady);
            ExternalInterface.addCallback("r3_onSongComplete", stopSound);

            baseSoundBytes.position = 0;
            var mp3Base64:String = Base64.encode(baseSoundBytes);
            ExternalInterface.call("r3_resampleAudio", mp3Base64, rateRate, rateReverse);
        }

        private function onResampleReady():void
        {
            Logger.success(this, "JS audio buffer ready for playback");
            isAudioReady = true;

            if (_pendingStart >= 0)
            {
                var seek:int = _pendingStart;
                _pendingStart = -1;
                start(seek);
            }
        }

        public function getSoundObject():Sound
        {
            if (rateRate != 1 || rateReverse)
                return baseSound;

            return sound;
        }

        private function onRateSound(e:SampleDataEvent):void
        {
            var osamples:int = 0;
            var sample:int = 0;
            var sampleDiff:int = 0;
            while (osamples < 4096)
            {
                sample = (e.position + osamples) * rateRate;
                sampleDiff = sample - rateSample;
                while (sampleDiff < 0 || sampleDiff >= rateSampleCount)
                {
                    rateSample += rateSampleCount;
                    rateSamples.position = 0;
                    sampleDiff = sample - rateSample;
                    var seekExtract:Boolean = (sampleDiff < 0 || sampleDiff > 8192);
                    rateSampleCount = (baseSound as Object).extract(rateSamples, 4096, seekExtract ? sample * mp3Rate : -1);

                    if (seekExtract)
                    {
                        rateSample = sample;
                        sampleDiff = sample - rateSample;
                    }

                    if (rateSampleCount <= 0)
                        return;
                }
                rateSamples.position = 8 * sampleDiff;
                e.data.writeFloat(rateSamples.readFloat());
                e.data.writeFloat(rateSamples.readFloat());
                osamples++;
            }
        }

        private function onReverseSound(e:SampleDataEvent):void
        {
            var osamples:int = 0;
            while (osamples < 4096)
            {
                var sample:int = (e.position + osamples) * rateRate;
                sample = (chart.Notes[chart.Notes.length - 1].frame * 1470) - sample + (63 - mp3Frame) * 1470 / rateRate;
                if (sample < 0)
                    return;
                var sampleDiff:int = sample - rateSample;
                if (sampleDiff < 0 || sampleDiff >= rateSampleCount)
                {
                    rateSample += rateSampleCount;
                    rateSamples.position = 0;
                    sampleDiff = sample - rateSample;
                    var seekPosition:int = sample - 4095;
                    rateSampleCount = baseSound.extract(rateSamples, 4096, seekPosition * mp3Rate);
                    rateSample = seekPosition;
                    sampleDiff = sample - rateSample;

                    if (rateSampleCount < 4096)
                    {
                        rateSamples.position = rateSampleCount * 8;
                        for (var i:int = rateSampleCount; i < 4096; i++)
                        {
                            rateSamples.writeFloat(0);
                            rateSamples.writeFloat(0);
                        }
                        rateSampleCount = 4096;
                    }
                }
                rateSamples.position = 8 * sampleDiff;
                e.data.writeFloat(rateSamples.readFloat());
                e.data.writeFloat(rateSamples.readFloat());
                osamples++;
            }
        }

        private function stopSound(e:* = null):void
        {
            musicIsPlaying = false;
        }

        ///- Song Function
        public function start(seek:int = 0):void
        {
            updateMusicOffset();

            if (!isAudioReady)
            {
                _pendingStart = seek;
                if (background)
                    background.gotoAndPlay(2 + musicStartFrames + int(seek * 30 / 1000));
                return;
            }

            if (_useJSAudio)
            {
                ExternalInterface.call("r3_playAudio", musicStartTime + seek, SoundMixer.soundTransform.volume);
            }
            else
            {
                if (soundChannel)
                {
                    soundChannel.removeEventListener(Event.SOUND_COMPLETE, stopSound);
                    soundChannel.stop();
                    soundChannel = null;
                }

                if (sound)
                {
                    soundChannel = sound.play(musicStartTime + seek);
                    soundChannel.soundTransform = SoundMixer.soundTransform;
                    soundChannel.addEventListener(Event.SOUND_COMPLETE, stopSound);
                }
            }

            if (background)
                background.gotoAndPlay(2 + musicStartFrames + int(seek * 30 / 1000));

            musicIsPlaying = true;
        }

        public function stop():void
        {
            if (background)
                background.stop();

            if (_useJSAudio)
            {
                ExternalInterface.call("r3_stopAudio");
            }
            else if (soundChannel)
            {
                soundChannel.removeEventListener(Event.SOUND_COMPLETE, stopSound);
                soundChannel.stop();
                soundChannel = null;
            }
            musicPausePosition = 0;
            musicIsPlaying = false;
        }

        public function pause():void
        {
            var pausePosition:int = 0;
            if (_useJSAudio)
                pausePosition = ExternalInterface.call("r3_getPosition");
            else if (soundChannel)
                pausePosition = soundChannel.position;
            stop();
            musicPausePosition = pausePosition;
        }

        public function resume():void
        {
            if (background)
                background.play();

            if (_useJSAudio)
            {
                ExternalInterface.call("r3_playAudio", musicPausePosition, SoundMixer.soundTransform.volume);
            }
            else if (sound)
            {
                soundChannel = sound.play(musicPausePosition);
                soundChannel.addEventListener(Event.SOUND_COMPLETE, stopSound);
            }
            musicIsPlaying = true;
        }

        private function playClips(clip:MovieClip):void
        {
            clip.gotoAndPlay(2 + musicStartFrames);
            for (var i:int = 0; i < clip.numChildren; i++)
            {
                var subclip:MovieClip = clip.getChildAt(i) as MovieClip;
                if (subclip)
                    playClips(subclip);
            }
        }

        public function reset():void
        {
            stop();
            start();
            if (background)
                playClips(background);
        }

        ///- Note Functions
        public function getNote(index:int):Note
        {
            if (noteMod.required())
                return noteMod.transformNote(index);

            return chart.Notes[index];
        }

        public function get totalNotes():int
        {
            if (noteMod.required())
                return noteMod.transformTotalNotes();

            if (!chart.Notes)
                return 0;

            return chart.Notes.length;
        }

        public function get chartTime():Number
        {
            if (noteMod.required())
                return noteMod.transformSongLength();

            if (!chart.Notes || chart.Notes.length <= 0)
                return 0;

            return getNote(totalNotes - 1).time + 1; // 1 second for fadeout.
        }

        public function get chartTimeFormatted():String
        {
            var totalSecs:int = chartTime;
            var minutes:String = Math.floor(totalSecs / 60).toString();
            var seconds:String = (totalSecs % 60).toString();

            if (seconds.length == 1)
                seconds = "0" + seconds;

            return minutes + ":" + seconds;
        }

        public function updateMusicOffset():void
        {
            options = _gvars.options;
            rateReverse = options.modEnabled("reverse");
            rateRate = options.songRate;
            noteMod.start(options);

            if (options.isolation && totalNotes > 0)
            {
                if (rateReverse)
                    musicStartFrames = Math.max(0, chart.Notes[chart.Notes.length - 1].frame - chart.Notes[Math.max(0, chart.Notes.length - 1 - options.isolationOffset)].frame - 60);
                else
                    musicStartFrames = Math.max(0, chart.Notes[options.isolationOffset].frame - 60);
            }
            else
                musicStartFrames = 0;

            musicStartTime = (musicStartFrames / options.songRate * 1000 / 30);
        }

        public function getPosition():int
        {
            if (_useJSAudio)
                return ExternalInterface.call("r3_getPosition") - musicStartTime;

            if (soundChannel != null)
                return soundChannel.position - musicStartTime;

            return 0;
        }
    }
}
