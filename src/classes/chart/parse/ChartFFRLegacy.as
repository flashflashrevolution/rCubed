package classes.chart.parse
{
    import arc.ArcGlobals;
    import by.blooddy.crypto.MD5;
    import classes.chart.Note;
    import classes.chart.NoteChart;
    import classes.Site;
    import com.flashfla.utils.StringUtil;
    import com.flashfla.utils.sprintf;
    import flash.utils.ByteArray;
    import flash.net.URLRequest;
    import flash.net.URLLoader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import com.flashfla.media.Beatbox;

    public class ChartFFRLegacy extends NoteChart
    {
        private var song:Object;

        public function ChartFFRLegacy(entry:Object, inData:Object, framerate:int = 30):void
        {
            type = NoteChart.FFR_LEGACY;

            super(entry.level, null, framerate);

            song = entry;

            parseChart(ByteArray(inData));
        }

        override public function noteToTime(note:Note):int
        {
            return Math.floor(note.time * framerate);
        }

        public static function songUrl(songEntry:Object, engine:Object = null):String
        {
            if (engine == null)
                engine = songEntry.engine;
            if (engine.songURLMode != null && engine.songURLMode == "replace")
            {
                var u:String = sprintf(engine.songURL, songEntry);
                return sprintf(engine.songURL, songEntry);
            }
            return engine.songURL + "level_" + songEntry.levelid + ".swf";
        }

        public static function validURL(url:String):Boolean
        {
            var pieces:Array = StringUtil.getURLPieces(url);
            var urls:Array = Site.instance.data["alt_engine_list"];
            if (urls.indexOf("c1de69f4b4e024a4a943348b8e5e56d6") != -1)
            {
                return false;
            }
            for each (var item:String in pieces)
            {
                if (urls.indexOf(MD5.hash(item.toLowerCase())) != -1)
                {
                    return false;
                }
            }
            return true;
        }

        public static function parseEngine(url:String, handler:Function):void
        {
            if (!validURL(url))
            {
                GlobalVariables.instance.gameMain.addAlert("Incorrect legacy URL");
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
                        GlobalVariables.instance.gameMain.addAlert("Incorrect legacy URL");
                        return;
                    }
                    for each (var node:XML in xml.children())
                    {
                        if (node.id == null)
                            continue;
                        var engine:Object = new Object();
                        engine.level_ranks = new Object();
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
                            engine.legacySyncLevel = int(node.@legacySyncLevel.toString());
                            engine.legacySyncLow = int(node.@legacySyncLow.toString());
                            engine.legacySyncHigh = int(node.@legacySyncHigh.toString());
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
            return function(song:Object):int
            {
                return (song.level > level ? high : low);
            };
        }

        private static function parseEngineError(event:Event = null):void
        {
            GlobalVariables.instance.gameMain.addAlert("Error loading legacy engine");
        }

        public static function parsePlaylist(data:Object, engine:Object = null):Array
        {
            if (engine == null)
                engine = ArcGlobals.instance.configLegacy;
            var xml:XML = new XML(data);
            var nodes:XMLList = xml.children();
            var count:int = nodes.length();
            var songs:Array = new Array();
            for (var i:int = 0; i < count; i++)
            {
                var node:XML = nodes[i];
                var song:Object = new Object();
                song.genre = int(node.@genre.toString());
                song.name = node.songname.toString();
                song.difficulty = int(node.songdifficulty.toString());
                song.style = node.songstyle.toString();
                song.time = node.songlength.toString();
                song.levelid = node.level.toString();
                if (isNaN(song.levelid))
                    song.level = i + 1;
                else
                    song.level = int(song.levelid);
                song.order = int(node.order.toString());
                song.arrows = int(node.arrows.toString());
                song.author = node.songauthor.toString();
                song.authorURL = node.songauthorURL.toString();
                song.stepauthor = node.songstepauthor.toString();
                song.stepauthorURL = node.songstepauthorurl.toString();
                song.playhash = node.playhash.toString();
                song.previewhash = node.previewhash.toString();
                song.min_nps = int(node.min_nps.toString());
                song.max_nps = int(node.max_nps.toString());
                song.credits = int(node.secretcredits.toString());
                song.price = int(node.price.toString());
                song.type = NoteChart.FFR_LEGACY;
                song.engine = engine;

                if (Boolean(node.arc_sync.toString()))
                    song.sync = int(node.arc_sync.toString());
                else if (engine.sync)
                    song.sync = engine.sync(song);

                songs.push(song);
            }
            return songs;
        }

        public function parseChart(data:ByteArray):void
        {
            var beatbox:Array = Beatbox.parseBeatbox(data);
            if (beatbox)
            {
                for each (var beat:Object in beatbox)
                {
                    var beatPos:int = beat[0] + (song.sync || 0);
                    if (ChartFFRBeatbox.isValidDirection(beat[1]))
                        Notes.push(new Note(beat[1], beatPos / framerate, beat[2] || "blue", beatPos));
                }
            }
        }
    }
}
