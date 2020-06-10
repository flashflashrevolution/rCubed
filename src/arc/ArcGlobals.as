package arc
{
    import classes.Playlist;
    import classes.chart.parse.ChartFFRLegacy;
    import flash.events.EventDispatcher;
    import com.bit101.components.Style;
    import flash.net.SharedObject;

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
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            for each (var engine:Object in save.data.legacyEngines)
            {
                ChartFFRLegacy.setEngineSync(engine);
                if (engine.level_ranks)
                {
                    for (var levelid:String in engine.level_ranks)
                        legacyLevelRanksSet({engine: engine, levelid: levelid}, engine.level_ranks[levelid]);
                    delete engine.level_ranks;
                }
                legacyEngines.push(engine);
            }
        }

        public function legacySave():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            save.data.legacyEngines = legacyEngines;
            try
            {
                save.flush();
            }
            catch (e:Error)
            {
            }
        }

        public function legacyDefaultLoad():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            legacyDefaultEngine = save.data.legacyDefaultEngine || null;
        }

        public function legacyDefaultSave():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            save.data.legacyDefaultEngine = legacyDefaultEngine;
            save.flush();
        }

        public function legacyEncode(song:Object):Object
        {
            if (!song || !song.engine)
                return null;

            var engine:Object = {"engineID": song.engine.id,
                    "songLevel": song.level,
                    "songID": song.levelid,
                    "songName": song.name,
                    "songAuthor": song.author,
                    "stepAuthor": song.stepauthor,
                    "ffrlURL": song.engine.songURL,
                    "type": song.type};

            if (song.sync)
                engine["sync"] = song.sync;

            return engine;
        }

        public function legacyDecode(data:Object):Object
        {
            var playlist:Playlist = Playlist.instance;
            if (playlist.engine && playlist.engine.id == data["engineID"])
                return playlist.playList[data["songLevel"]];

            var engine:Object = legacyEngine(data.engineID);
            if (!engine)
                engine = {id: data.engineID, songURL: data.ffrlURL};

            return {engine: engine,
                    level: data["songLevel"],
                    name: data["songName"],
                    author: data["songAuthor"],
                    authorwithurl: data["songAuthor"],
                    stepauthor: data["stepAuthor"],
                    stepauthor: data["stepAuthor"],
                    levelid: data["songID"],
                    type: data["type"],
                    sync: data["sync"],
                    arrows: 0};
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
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            configInterface = save.data.arcLayout || {};
        }

        public function interfaceSave():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            save.data.arcLayout = configInterface;
            save.flush();
        }

        public var configMusicOffset:int = 0;

        public function musicOffsetLoad():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            configMusicOffset = save.data.arcMusicOffset || 0;
        }

        public function musicOffsetSave():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            save.data.arcMusicOffset = configMusicOffset;
            try
            {
                save.flush();
            }
            catch (e:Error)
            {
            }
        }

        public var filterLevelLow:int = 1;
        public var filterLevelHigh:int = 120;

        public var configMPSize:int = 10;
        
        public static var divisionColor:Array = [0xC27BA0, 0x8E7CC3, 0x6D9EEB, 0x93C47D, 0xFFD966, 0xE06666, 0x919C86, 0xD2C7AC, 0xBF0000];
        public static var divisionTitle:Array = ["Novice", "Intermediate", "Advanced", "Expert", "Master", "Guru", "Legendary", "Godly", "Developer"];

        public function mpLoad():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            configMPSize = save.data.arcMPSize || 10;
        }

        public function mpSave():void
        {
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            save.data.arcMPSize = configMPSize;
            save.flush();
        }

        public var legacyLevelRanks:Object = null;
        public static const legacyLevelRanksName:String = "90579262-509d-4370-9c2e-835a38cf0387";

        public function legacyLevelRanksGet(song:Object):Object
        {
            if (!legacyLevelRanks)
                return null;
            var ranks:Object = legacyLevelRanks[song.engine.id];
            if (!ranks)
                return null;
            return ranks[song.levelid || song.level];
        }

        public function legacyLevelRanksSet(song:Object, value:Object):void
        {
            if (!legacyLevelRanks)
                legacyLevelRanks = new Object();
            var ranks:Object = legacyLevelRanks[song.engine.id];
            if (!ranks)
                legacyLevelRanks[song.engine.id] = ranks = new Object();
            ranks[song.levelid || song.level] = value;
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
            var save:SharedObject = SharedObject.getLocal(Constant.LOCAL_SO_NAME);
            delete save.data.arcMPSize;
            delete save.data.arcMPTimestamp;
            delete save.data.arcMPMask;
            delete save.data.arcMusicOffset;
            delete save.data.arcLayout;
            save.flush();

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
