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

        public static function get instance():ArcGlobals
        {
            if (_instance == null)
            {
                _instance = new ArcGlobals(new SingletonEnforcer());
            }
            return _instance;
        }

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
        public var configLegacy:Object = null;
        public var legacyEngines:Array = [];
        public var legacyDefaultEngine:Object = null;

        public function legacyLoad():void
        {
            var legacyEngineArray:* = LocalStore.getVariable("legacyEngines", null);
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
            LocalStore.setVariable("legacyEngines", legacyEngines);
            LocalStore.flush();
        }

        public function legacyDefaultLoad():void
        {
            legacyDefaultEngine = LocalStore.getVariable("legacyDefaultEngine", null);
        }

        public function legacyDefaultSave():void
        {
            LocalStore.setVariable("legacyDefaultEngine", legacyDefaultEngine);
            LocalStore.flush();
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

        public function resetIsolation():void
        {
            configIsolation = false;
            configIsolationStart = 0;
            configIsolationLength = 0;
        }
        public var configIsolation:Boolean = false;
        public var configIsolationStart:int = 0;
        public var configIsolationLength:int = 0;

        public var configJudge:Array;

        public var configInterface:Object = {};

        public function interfaceLoad():void
        {
            configInterface = LocalStore.getVariable("arcLayout", {});
        }

        public function interfaceSave():void
        {
            LocalStore.setVariable("arcLayout", configInterface);
            LocalStore.flush();
        }

        public var configMusicOffset:int = 0;

        public function musicOffsetLoad():void
        {
            configMusicOffset = LocalStore.getVariable("arcMusicOffset", 0);
        }

        public function musicOffsetSave():void
        {
            LocalStore.setVariable("arcMusicOffset", configMusicOffset);
            LocalStore.flush();
        }

        public var filterLevelLow:int = 1;
        public var filterLevelHigh:int = 120;

        public var configMPSize:int = 10;

        public static const divisionColor:Array = [0xC27BA0, 0x8E7CC3, 0x6D9EEB, 0x93C47D, 0xFFD966, 0xE06666, 0x919C86, 0xD2C7AC, 0xBF0000];
        public static const divisionTitle:Array = ["Novice", "Intermediate", "Advanced", "Expert", "Master", "Guru", "Legendary", "Godly", "Developer"];
        public static const divisionLevel:Array = [0, 26, 50, 59, 69, 83, 94, 101, 122];

        public static function getDivisionColor(level:int):int
        {
            return divisionColor[getDivisionNumber(level)];
        }

        public static function getDivisionTitle(level:int):String
        {
            return divisionTitle[getDivisionNumber(level)];
        }

        public static function getDivisionNumber(level:int):int
        {
            var div:int;
            for (div = divisionLevel.length - 1; div >= 0; --div)
            {
                if (level >= divisionLevel[div])
                {
                    break;
                }
            }
            return div;
        }

        public function mpLoad():void
        {
            configMPSize = LocalStore.getVariable("arcMPSize", 10);
        }

        public function mpSave():void
        {
            LocalStore.setVariable("arcMPSize", configMPSize);
            LocalStore.flush();
        }

        public var legacyLevelRanks:Object = null;
        public static const legacyLevelRanksName:String = "90579262-509d-4370-9c2e-835a38cf0387";

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
            legacyDefaultLoad();
            musicOffsetLoad();
            interfaceLoad();
            mpLoad();
        }

        public function resetSettings():void
        {
            LocalStore.deleteVariable("arcMPSize");
            LocalStore.deleteVariable("arcMPTimestamp");
            LocalStore.deleteVariable("arcMPMask");
            LocalStore.deleteVariable("arcMusicOffset");
            LocalStore.deleteVariable("arcLayout");

            LocalStore.flush();

            load();
            configJudge = null;
            configIsolation = false;
            configIsolationStart = configIsolationLength = 0;
        }

        public function resetConfig():void
        {
            resetIsolation();
        }
    }
}

class SingletonEnforcer
{
}
