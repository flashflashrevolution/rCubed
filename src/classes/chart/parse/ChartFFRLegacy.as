package classes.chart.parse
{
    import arc.ArcGlobals;
    import by.blooddy.crypto.MD5;
    import classes.Alert;
    import classes.Site;
    import classes.SongInfo;
    import classes.chart.Note;
    import classes.chart.NoteChart;
    import com.flashfla.media.Beatbox;
    import com.flashfla.utils.StringUtil;
    import com.flashfla.utils.sprintf;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.utils.ByteArray;

    public class ChartFFRLegacy extends NoteChart
    {
        private var songInfo:SongInfo;

        public function ChartFFRLegacy(songInfo:SongInfo, inData:Object, framerate:int = 30):void
        {
            type = NoteChart.FFR_LEGACY;

            super(null, framerate);

            this.songInfo = songInfo;

            parseChart(ByteArray(inData));
        }

        public static function songUrl(songInfo:SongInfo, engine:Object = null):String
        {
            if (engine == null)
                engine = songInfo.engine;
            if (engine.songURLMode != null && engine.songURLMode == "replace")
            {
                var song_variables:Object = {"level": songInfo.level_id,
                        "playhash": songInfo.play_hash};

                return sprintf(engine.songURL, song_variables);
            }
            return engine.songURL + "level_" + songInfo.level_id + ".swf";
        }

        public static function validURL(url:String):Boolean
        {
            var pieces:Array = StringUtil.getURLPieces(url);
            var urls:Array = Site.instance.data["alt_engine_list"];

            if (urls.indexOf("c1de69f4b4e024a4a943348b8e5e56d6") != -1)
                return false;

            for each (var item:String in pieces)
            {
                if (urls.indexOf(MD5.hash(item.toLowerCase())) != -1)
                    return false;
            }
            return true;
        }

        public static function parseEngine(url:String, handler:Function):void
        {
            if (!validURL(url))
            {
                Alert.add("Incorrect legacy URL");
                return;
            }

            var time:Number = new Date().getTime();
            var loader:URLLoader = new URLLoader();

            loader.addEventListener(Event.COMPLETE, function(event:Event):void
            {
                try
                {
                    var xml:XML = new XML(event.target.data);
                    if (xml.localName() != "arc_engines")
                    {
                        Alert.add("Incorrect legacy URL");
                        return;
                    }
                    for each (var node:XML in xml.children())
                    {
                        if (node.id == null)
                            continue;
                        var engine:Object = {};
                        engine.level_ranks = {};
                        engine.config_url = url;
                        engine.id = node.id.toString();
                        engine.name = node.name.toString();
                        engine.domain = node.domain.toString();
                        engine.songURL = node.songURL.toString();
                        engine.playlistURL = node.playlistURL.toString();
                        engine.ignoreCache = Boolean(node.@ignoreCache.toString());
                        engine.legacySync = Boolean(node.@legacySync.toString());
                        if (node.songURLMode != null)
                            engine.songURLMode = node.songURLMode.toString();
                        if (engine.legacySync)
                        {
                            engine.legacySyncLevel = parseInt(node.@legacySyncLevel.toString());
                            engine.legacySyncLow = parseInt(node.@legacySyncLow.toString());
                            engine.legacySyncHigh = parseInt(node.@legacySyncHigh.toString());
                            setEngineSync(engine);
                        }
                        if (CONFIG::debug || node.@nocrossdomain != "true")
                            handler(engine);
                    }
                }
                catch (e:Error)
                {
                    parseEngineError();
                }
            });
            loader.addEventListener(IOErrorEvent.IO_ERROR, parseEngineError);
            loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, parseEngineError);
            loader.load(new URLRequest(url + (url.indexOf("?") == -1 ? "?d=" + time : "&d=" + time)));
        }

        public static function setEngineSync(engine:Object):void
        {
            engine.sync = engineLegacySync(engine.legacySyncLevel, engine.legacySyncLow, engine.legacySyncHigh);
        }

        public static function engineLegacySync(level:int, low:int, high:int):Function
        {
            return function(songInfo:SongInfo):int
            {
                return (songInfo.level > level ? high : low);
            };
        }

        private static function parseEngineError(event:Event = null):void
        {
            Alert.add("Error loading legacy engine");
        }

        public static function parsePlaylist(data:Object, engine:Object = null):Array
        {
            if (engine == null)
                engine = ArcGlobals.instance.configLegacy;

            var xml:XML = new XML(data);
            var nodes:XMLList = xml.children();
            var count:int = nodes.length();
            var songs:Array = [];

            for (var i:int = 0; i < count; i++)
            {
                var node:XML = nodes[i];
                var songInfo:SongInfo = new SongInfo();

                songInfo.genre = int(node.@genre.toString());
                songInfo.name = node.songname.toString();
                songInfo.difficulty = int(node.songdifficulty.toString());
                songInfo.style = node.songstyle.toString();
                songInfo.time = node.songlength.toString();
                songInfo.level_id = node.level.toString();
                songInfo.level = i + 1;
                songInfo.order = int(node.order.toString());
                songInfo.note_count = int(node.arrows.toString());
                songInfo.author = node.songauthor.toString();
                songInfo.author_url = node.songauthorURL.toString();
                songInfo.stepauthor = node.songstepauthor.toString();
                songInfo.play_hash = node.playhash.toString();
                songInfo.swf_hash = node.swfhash.toString();
                songInfo.min_nps = int(node.min_nps.toString());
                songInfo.max_nps = int(node.max_nps.toString());
                songInfo.credits = int(node.secretcredits.toString());
                songInfo.price = int(node.price.toString());
                songInfo.background = node.background.toString();
                songInfo.engine = engine;

                if (Boolean(node.arc_sync.toString()))
                    songInfo.sync = int(node.arc_sync.toString());
                else if (engine.sync)
                    songInfo.sync = engine.sync(songInfo);

                songs.push(songInfo);
            }
            return songs;
        }

        public function parseChart(data:ByteArray):void
        {
            var validDirections:Array = ['L', 'D', 'U', 'R'];

            var beatbox:Array = Beatbox.parseBeatbox(data);
            if (beatbox && beatbox.length > 0)
            {
                for each (var beat:Array in beatbox)
                {
                    if (validDirections.indexOf(beat[1]) >= 0)
                    {
                        var beatPos:int = beat[0] + (songInfo.sync || 0);
                        var beatPosMS:Number = beatPos / framerate;

                        // has ms timing data
                        if (beat.length >= 4)
                            beatPosMS = (beat[3] / 1000);

                        Notes.push(new Note(beat[1], beatPosMS, beat[2] || "blue", beatPos));
                    }
                }
            }
        }
    }
}
