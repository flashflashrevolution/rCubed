package arc
{
    import classes.Playlist;
    import classes.chart.parse.ChartFFRLegacy;
    import flash.events.EventDispatcher;
    import flash.net.SharedObject;
    import classes.SongInfo;

    public class ArcGlobals extends EventDispatcher
    {
        private static var _instance:ArcGlobals = null;

        public var legacyLevelRanks:Object = null;
        public static const legacyLevelRanksName:String = "90579262-509d-4370-9c2e-835a38cf0387";

        public var configMusicOffset:int = 0;
        public var configLegacy:Object = null;
        public var legacyEngines:Array = [];
        public var legacyDefaultEngine:Object = null;

        public var configIsolation:Boolean = false;
        public var configIsolationStart:int = 0;
        public var configIsolationLength:int = 0;

        public var configJudge:Array;

        public var configInterface:Object = {};

        public var configMPSize:int = 10;

        public function ArcGlobals(en:SingletonEnforcer)
        {
            if (en == null)
            {
                throw Error("Multi-Instance Blocked");
            }

            load();
        }

        public function legacyEngine(id:String):Object
        {
            for each (var engine:Object in legacyEngines)
            {
                if (engine.id == id)
                    return engine;
            }
            return null;
        }

        public function legacyLoad():void
        {
            var legacyEngineArray:* = LocalOptions.getVariable("legacy_engines", null);
            for each (var engine:Object in legacyEngineArray)
            {
                ChartFFRLegacy.setEngineSync(engine);
                if (engine.level_ranks)
                {
                    // TODO: check type on this `levelid` (should be int ?)
                    for (var levelid:String in engine.level_ranks)
                    {
                        var songInfo:SongInfo = new SongInfo();
                        songInfo.engine = engine;
                        songInfo.levelId = levelid;
                        legacyLevelRanksSet(songInfo, engine.level_ranks[levelid]);
                    }

                    delete engine.level_ranks;
                }
                legacyEngines.push(engine);
            }
        }

        public function legacySave():void
        {
            LocalOptions.setVariable("legacy_engines", legacyEngines);
        }

        public function legacyDefaultSave():void
        {
            LocalOptions.setVariable("legacy_default_engine", legacyDefaultEngine);
        }

        /**
         * Creates a new `engine` object from the song's fields
         */
        public function legacyEncode(song:SongInfo):Object
        {
            if (!song || !song.engine)
                return null;

            var engine:Object = {"engineID": song.engine.id,
                    "songLevel": song.level,
                    "songID": song.levelId,
                    "songName": song.name,
                    "songAuthor": song.author,
                    "stepAuthor": song.stepauthor,
                    "ffrlURL": song.engine.songURL,
                    "type": song.chartType};

            if (song.sync)
                engine["sync"] = song.sync;

            return engine;
        }

        public function legacyDecode(data:Object):SongInfo
        {
            var playlist:Playlist = Playlist.instance;
            if (playlist.engine && playlist.engine.id == data["engineID"])
                return playlist.playList[data["songLevel"]];

            var engine:Object = legacyEngine(data.engineID);
            if (!engine)
                engine = {id: data.engineID, songURL: data.ffrlURL};

            var songInfo:SongInfo = new SongInfo();
            songInfo.engine = engine;
            songInfo.level = data["songLevel"];
            songInfo.name = data["songName"];
            songInfo.author = data["songAuthor"];
            songInfo.authorwithurl = data["songAuthor"];
            songInfo.stepauthor = data["stepAuthor"];
            songInfo.stepauthorwithurl = data["stepAuthor"];
            songInfo.levelId = data["songID"];
            songInfo.chartType = data["type"];
            songInfo.sync = data["sync"];
            songInfo.noteCount = 0;

            return songInfo;
        }

        public function interfaceSave():void
        {
            LocalOptions.setVariable("layouts", configInterface);
        }

        public function musicOffsetSave():void
        {
            LocalOptions.setVariable("rolling_music_offset", configMusicOffset);
        }

        public function mpSave():void
        {
            LocalOptions.setVariable("mp_text_size", configMPSize);
        }

        public function legacyLevelRanksGet(songInfo:SongInfo):Object
        {
            if (!legacyLevelRanks)
                return null;
            var ranks:Object = legacyLevelRanks[songInfo.engine.id];
            if (!ranks)
                return null;
            return ranks[songInfo.levelId || songInfo.level];
        }

        public function legacyLevelRanksSet(songInfo:SongInfo, value:Object):void
        {
            if (!legacyLevelRanks)
                legacyLevelRanks = {};
            var ranks:Object = legacyLevelRanks[songInfo.engine.id];
            if (!ranks)
                legacyLevelRanks[songInfo.engine.id] = ranks = {};
            ranks[songInfo.levelId || songInfo.level] = value;
        }

        public function legacyLevelRanksLoad():void
        {
            var save:SharedObject = SharedObject.getLocal(legacyLevelRanksName);
            legacyLevelRanks = save.data.legacyLevelRanks;
        }

        public function legacyLevelRanksSave():void
        {
            var save:SharedObject = SharedObject.getLocal(legacyLevelRanksName);
            save.data.legacyLevelRanks = legacyLevelRanks;
            try
            {
                save.flush();
            }
            catch (e:Error)
            {
            }
        }

        public function load():void
        {
            legacyLevelRanksLoad();
            legacyLoad();

            legacyDefaultEngine = LocalOptions.getVariable("legacy_default_engine", null);
            configMusicOffset = LocalOptions.getVariable("rolling_music_offset", 0);
            configInterface = LocalOptions.getVariable("layouts", {});
            configMPSize = LocalOptions.getVariable("mp_text_size", 10);
        }

        public function resetSettings():void
        {
            LocalOptions.deleteVariable("mp_text_size");
            LocalOptions.deleteVariable("rolling_music_offset");
            LocalOptions.deleteVariable("layouts");

            resetConfig();
            configJudge = null;

            load();
        }

        public function resetConfig():void
        {
            configIsolation = false;
            configIsolationStart = 0;
            configIsolationLength = 0;
        }

        public static function get instance():ArcGlobals
        {
            if (_instance == null)
            {
                _instance = new ArcGlobals(new SingletonEnforcer());
            }
            return _instance;
        }

    }
}

class SingletonEnforcer
{
}
