package classes.chart
{
    import arc.NoteMod;
    import by.blooddy.crypto.MD5;
    import classes.chart.parse.ChartFFRLegacy;
    import com.flashfla.media.MP3Extraction;
    import com.flashfla.media.SwfSilencer;
    import com.flashfla.net.ForcibleLoader;
    import com.flashfla.utils.Crypt;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SampleDataEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filesystem.File;
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundMixer;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;
    import game.GameOptions;
    import classes.SongInfo;

    public class Song extends EventDispatcher
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;

        public var musicLoader:*;
        private var chartLoader:URLLoader;

        public var id:uint;
        public var songInfo:SongInfo;
        public var type:String;
        public var chartType:String;
        public var preview:Boolean;
        public var sound:Sound;
        public var music:MovieClip;
        public var chart:NoteChart;
        public var noteMod:NoteMod;
        public var options:GameOptions;
        public var soundChannel:SoundChannel;
        public var musicPausePosition:int;
        public var musicIsPlaying:Boolean = false;
        public var mp3Frame:int = 0;
        public var mp3Rate:Number = 1;

        public var isLoaded:Boolean = false;
        public var isChartLoaded:Boolean = false;
        public var isMusicLoaded:Boolean = false;
        public var isMusic2Loaded:Boolean = true;
        public var loadFail:Boolean = false;

        public var isMusicLoaderLoading:Boolean = false;
        public var isChartLoaderLoading:Boolean = false;

        public var bytesSWF:ByteArray = null;
        public var bytesLoaded:uint = 0;
        public var bytesTotal:uint = 0;

        private static const LOAD_MUSIC:String = "music";
        private static const LOAD_CHART:String = "chart";
        private var musicForcibleLoader:ForcibleLoader;
        public var musicDelay:int = 0;

        private var localFileData:ByteArray = null;
        private var localFileHash:String = "";

        public function Song(songInfo:SongInfo, isPreview:Boolean = false):void
        {
            this.songInfo = songInfo;
            this.id = songInfo.level;
            this.preview = isPreview;
            this.type = (songInfo.chartType != null ? songInfo.chartType : NoteChart.FFR);
            this.chartType = songInfo.chartType || NoteChart.FFR_LEGACY;

            options = _gvars.options;
            noteMod = new NoteMod(this, options);
            rateReverse = options.modEnabled("reverse");
            rateRate = options.songRate;

            if (type == "EDITOR")
            {
                var editorSongInfo:SongInfo = new SongInfo();
                editorSongInfo.chartType = NoteChart.FFR_BEATBOX;
                editorSongInfo.level = this.id;

                chart = NoteChart.parseChart(NoteChart.FFR_BEATBOX, editorSongInfo, '_root.beatBox = [];');
            }
            else if (options.songRate != 1 || options.frameRate > 30 || rateReverse || options.forceNewJudge)
                this.type = NoteChart.FFR_MP3;

            load();
        }

        public function unload():void
        {
            removeLoaderListeners();
            isLoaded = isChartLoaded = isMusicLoaded = false;
            isMusic2Loaded = true;
            loadFail = true;
            if (musicLoader && isMusicLoaderLoading)
            {
                musicLoader.close();
                isMusicLoaderLoading = false;
            }
            if (chartLoader && isChartLoaderLoading)
            {
                chartLoader.close();
                isChartLoaderLoading = false;
            }
            music = null;
            chart = null;
        }

        private function load():void
        {
            if (type == NoteChart.FFR_MP3)
                musicLoader = new URLLoader();
            else
                musicLoader = new Loader();
            chartLoader = new URLLoader();

            addLoaderListeners();

            // Load Stored SWF
            var url_file_hash:String = "";
            if ((_gvars.air_useLocalFileCache) && AirContext.doesFileExist(AirContext.getSongCachePath(this) + "data.bin"))
            {
                localFileData = AirContext.readFile(AirContext.getAppPath(AirContext.getSongCachePath(this) + "data.bin"), (this.songInfo.engine ? 0 : this.id));
                localFileHash = MD5.hashBytes(localFileData);
                url_file_hash = "hash=" + localFileHash + "&";

                if (this.songInfo.engine && localFileData && type == NoteChart.FFR_MP3)
                {
                    removeLoaderListeners();
                    musicLoader = new Loader();
                    addLoaderListeners(true);
                    musicLoader.loadBytes(localFileData, AirContext.getLoaderContext());
                    return;
                }
            }

            switch (type)
            {
                case NoteChart.FFR:
                case NoteChart.FFR_RAW:
                case NoteChart.FFR_LEGACY:
                    musicForcibleLoader = new ForcibleLoader(musicLoader);
                    musicForcibleLoader.load(new URLRequest(urlGen(LOAD_MUSIC)));
                    break;
                case NoteChart.FFR_MP3:
                    musicLoader.dataFormat = URLLoaderDataFormat.BINARY;
                    musicLoader.load(new URLRequest(urlGen(LOAD_MUSIC, url_file_hash)));
                    isMusicLoaderLoading = true;
                    break;
                default:
                    break;
            }

            switch (chartType)
            {
                case NoteChart.FFR:
                case NoteChart.FFR_BEATBOX:
                case NoteChart.FFR_RAW:
                    chartLoader.load(new URLRequest(urlGen(LOAD_CHART)));
                    isChartLoaderLoading = true;
                    break;
                default:
                    break;
            }
        }

        public function get progress():int
        {
            if (musicLoader != null)
            {
                return Math.floor(((bytesLoaded / bytesTotal) * 99) + (isChartLoaded ? 1 : 0));
            }

            return 0;
        }

        public function getMusicContentLoader(isLoader:Boolean = false):Object
        {
            if (isLoader)
                return musicLoader.contentLoaderInfo;
            return type == NoteChart.FFR_MP3 ? musicLoader : musicLoader.contentLoaderInfo;
        }

        private function urlGen(fileType:String, fileHash:String = ""):String
        {
            switch (songInfo.chartType || type)
            {
                case NoteChart.FFR:
                case NoteChart.FFR_RAW:
                case NoteChart.FFR_MP3:
                    return Constant.SONG_DATA_URL + "?" + fileHash + "id=" + (preview ? songInfo.previewhash : songInfo.playhash) + (preview ? "&mode=2" : "") + (_gvars.userSession != "0" ? "&session=" + _gvars.userSession : "") + "&type=" + NoteChart.FFR + "_" + fileType;

                case NoteChart.FFR_LEGACY:
                    return ChartFFRLegacy.songUrl(songInfo);

                default:
                    return Constant.SONG_DATA_URL;
            }
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
            if (chartLoader)
            {
                chartLoader.addEventListener(Event.COMPLETE, chartLoadComplete);
                chartLoader.addEventListener(IOErrorEvent.IO_ERROR, chartLoadError);
                chartLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, chartLoadError);
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
            if (chartLoader)
            {
                chartLoader.removeEventListener(Event.COMPLETE, chartLoadComplete);
                chartLoader.removeEventListener(IOErrorEvent.IO_ERROR, chartLoadError);
                chartLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, chartLoadError);
            }
            if (musicLoader)
                musicLoader.removeEventListener(ProgressEvent.PROGRESS, musicProgressHandler);
        }

        public function loadComplete():void
        {
            if (isChartLoaded && isMusicLoaded && isMusic2Loaded)
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
            var chartData:ByteArray;
            if (type == NoteChart.FFR_MP3)
            {

                if (e.target is URLLoader)
                    chartData = e.target.data;
                else if (e.target is LoaderInfo)
                    chartData = e.target.bytes;

                bytesLoaded = bytesTotal = chartData.length; // Update Progress Bar in case.
                isMusic2Loaded = false;

                // Check for server response for matching hash. Encode Compressed SWF Data
                var storeChartData:ByteArray;
                if (_gvars.air_useLocalFileCache)
                { // && !this.entry.engine) {
                    // Alt Engine has Data
                    if (this.songInfo.engine && localFileData)
                    {

                    }
                    else if (chartData.length == 3)
                    {
                        chartData.position = 0;
                        var code:String = chartData.readUTFBytes(3);
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

                // Generate SWF Containing a MP3 as class "SoundClass".
                var metadata:Object = {};
                var bytes:ByteArray = MP3Extraction.extractSound(chartData, metadata);
                bytes.position = 0;
                mp3Frame = metadata.frame - 2;
                mp3Rate = MP3Extraction.formatRate(metadata.format) / 44100;
                sound = new Sound();
                sound.loadCompressedDataFromByteArray(bytes, bytes.length);
                if (rateRate != 1 || rateReverse)
                {
                    rateSound = sound;
                    sound = new Sound();
                    if (rateReverse)
                        sound.addEventListener("sampleData", onReverseSound);
                    else
                        sound.addEventListener("sampleData", onRateSound);
                }

                isMusic2Loaded = true;

                // Generate a SWF containing no audio, used as a background.
                var mloader:Loader = new Loader();
                var mbytes:ByteArray = SwfSilencer.stripSound(chartData);
                mloader.contentLoaderInfo.addEventListener(Event.COMPLETE, mp3MusicCompleteHandler);
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
                        var cacheFile:File = AirContext.writeFile(AirContext.getAppPath(AirContext.getSongCachePath(this) + "data.bin"), storeChartData);
                        trace("Saving SWF for " + this.id + ": " + cacheFile.nativePath);
                    }
                    catch (e:Error)
                    {
                    }
                }

                loadComplete();

            }
            else
            {
                music = e.target.content as MovieClip;

                stop();

                chartData = musicForcibleLoader.inputBytes;
                musicForcibleLoader = null;

                isMusicLoaded = true;
                loadComplete();
            }

            if (chartType == NoteChart.FFR_LEGACY)
            {
                chart = NoteChart.parseChart(chartType, songInfo, chartData);
                chartLoadComplete(e);
            }

            bytesSWF = chartData;
        }

        private function mp3MusicCompleteHandler(e:Event):void
        {
            var info:LoaderInfo = e.currentTarget as LoaderInfo;
            music = info.content as MovieClip;

            isMusicLoaded = true;
            loadComplete();
        }

        public function getSoundObject():Sound
        {
            if (rateRate != 1 || rateReverse)
                return rateSound;
            return sound;
        }

        private var rateReverse:Boolean = false;
        private var rateRate:Number = 1;
        private var rateSound:Sound;
        private var rateSample:int = 0;
        private var rateSampleCount:int = 0;
        private var rateSamples:ByteArray = new ByteArray();

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
                    rateSampleCount = (rateSound as Object).extract(rateSamples, 4096, seekExtract ? sample * mp3Rate : -1);

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
                    rateSampleCount = (rateSound as Object).extract(rateSamples, 4096, seekPosition * mp3Rate);
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

        private function stopSound(e:*):void
        {
            musicIsPlaying = false;
        }

        private function chartLoadComplete(e:Event):void
        {
            isChartLoaderLoading = false;
            switch (chartType)
            {
                case NoteChart.FFR:
                case NoteChart.FFR_MP3:
                    chart = NoteChart.parseChart(NoteChart.FFR, songInfo, Crypt.ROT255(Crypt.B64Decode(e.target.data)));
                    break;

                case NoteChart.FFR_BEATBOX:
                case NoteChart.FFR_RAW:
                    chart = NoteChart.parseChart(chartType, songInfo, e.target.data);
                    break;

                case NoteChart.FFR_LEGACY:
                    if (songInfo.noteCount == 0)
                        songInfo.noteCount = chart.Notes.length;
                    break;

                case NoteChart.THIRDSTYLE:
                    chart = NoteChart.parseChart(chartType, songInfo, e.target.data);
                    break;

                default:
                    throw Error("Unsupported NoteChart type!");
            }
            isChartLoaded = true;

            if (noteMod.required() && chartType != NoteChart.FFR_LEGACY)
            {
                generateModNotes();
            }

            loadComplete();
        }

        private function musicLoadError(e:Event = null):void
        {
            isMusicLoaderLoading = false;
            //_gvars.gameMain.addPopup(new PopupMessage(_gvars.gameMain, "An error occured while loading the music.", "ERROR"));
            removeLoaderListeners();
            loadFail = true;
        }

        private function chartLoadError(e:Event = null):void
        {
            //_gvars.gameMain.addPopup(new PopupMessage(_gvars.gameMain, "An error occured while loading the chart file.", "ERROR"));
            isChartLoaderLoading = false;
            removeLoaderListeners();
            loadFail = true;
        }

        ///- Song Function
        public function start(seek:int = 0):void
        {
            updateMusicDelay();
            if (soundChannel)
            {
                soundChannel.removeEventListener(Event.SOUND_COMPLETE, stopSound);
                soundChannel.stop();
            }
            if (sound)
            {
                soundChannel = sound.play(musicDelay * 1000 / options.songRate / 30 + seek);
                soundChannel.soundTransform = SoundMixer.soundTransform;
                soundChannel.addEventListener(Event.SOUND_COMPLETE, stopSound);
            }
            if (music)
                music.gotoAndPlay(2 + musicDelay + int(seek * 30 / 1000));
            musicIsPlaying = true;
        }

        public function stop():void
        {
            if (music)
                music.stop();
            if (soundChannel)
            {
                soundChannel.removeEventListener(Event.SOUND_COMPLETE, stopSound);
                soundChannel.stop();
                musicPausePosition = 0;
                soundChannel = null;
            }
            musicIsPlaying = false;
        }

        public function pause():void
        {
            var pausePosition:int = 0;
            if (soundChannel)
                pausePosition = soundChannel.position;
            stop();
            musicPausePosition = pausePosition;
        }

        public function resume():void
        {
            if (music)
                music.play();
            if (sound)
            {
                soundChannel = sound.play(musicPausePosition);
                soundChannel.addEventListener(Event.SOUND_COMPLETE, stopSound);
            }
            musicIsPlaying = true;
        }

        private function playClips(clip:MovieClip):void
        {
            clip.gotoAndPlay(2 + musicDelay);
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
            if (music)
                playClips(music);
        }

        ///- Note Functions
        private var ModNotes:Array = new Array();

        public function generateModNotes():void
        {
            for (var i:int = chart.Notes.length - 1; i >= 0; i--)
            {
                ModNotes[i] = noteMod.transformNote(chart.Notes[i]);
            }
        }

        public function getNote(index:int):Note
        {
            if (noteMod.required())
            {
                if (NoteChart.FFR_LEGACY)
                {
                    return noteMod.transformNote(index);
                }

                return ModNotes[index];
            }
            else
            {
                return chart.Notes[index];
            }
        }

        public function get totalNotes():int
        {
            if (noteMod.required())
            {
                return noteMod.transformTotalNotes();
            }

            if (!chart.Notes)
            {
                return 0;
            }

            return chart.Notes.length;
        }

        public function get chartTime():Number
        {
            if (noteMod.required())
            {
                return noteMod.transformSongLength();
            }

            if (!chart.Notes || chart.Notes.length <= 0)
            {
                return 0;
            }

            return getNote(totalNotes - 1).time + 1; // 1 second for fadeout.
        }

        public function get chartTimeFormatted():String
        {
            var totalSecs:int = chartTime;
            var minutes:String = Math.floor(totalSecs / 60).toString();
            var seconds:String = (totalSecs % 60).toString();

            if (seconds.length == 1)
            {
                seconds = "0" + seconds;
            }

            return minutes + ":" + seconds;
        }

        public function get noteSteps():int
        {
            return chart.framerate + 1;
        }

        public function get frameRate():int
        {
            return type == NoteChart.FFR_MP3 ? _gvars.activeUser.frameRate : chart.framerate;
        }

        public function updateMusicDelay():void
        {
            options = _gvars.options;
            rateReverse = options.modEnabled("reverse");
            rateRate = options.songRate;
            noteMod.start(options);
            if (options.isolation && totalNotes > 0)
            {
                if (rateReverse)
                    musicDelay = Math.max(0, chart.Notes[chart.Notes.length - 1].frame - chart.Notes[Math.max(0, chart.Notes.length - 1 - options.isolationOffset)].frame - 60);
                else
                    musicDelay = Math.max(0, chart.Notes[options.isolationOffset].frame - 60);
            }
            else
                musicDelay = 0;
        }

        public function getPosition():int
        {
            switch (type)
            {
                case NoteChart.FFR:
                case NoteChart.FFR_RAW:
                case NoteChart.FFR_LEGACY:
                    return (music.currentFrame - 2 - musicDelay) * 1000 / 30;

                case NoteChart.FFR_MP3:
                case NoteChart.THIRDSTYLE:
                    return soundChannel ? soundChannel.position - musicDelay / options.songRate * 1000 / 30 : 0;

                default:
                    return 0;
            }
        }
    }
}
