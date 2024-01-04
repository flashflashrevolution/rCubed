package classes.score
{
    import arc.ArcGlobals;
    import by.blooddy.crypto.SHA1;
    import classes.Alert;
    import classes.Language;
    import classes.Playlist;
    import classes.SongInfo;
    import classes.replay.Replay;
    import com.flashfla.net.DynamicURLLoader;
    import com.flashfla.utils.sprintf;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import game.GameScoreResult;
    import game.SkillRating;
    import popups.PopupMessage;
    import popups.PopupTokenUnlock;
    import popups.replays.ReplayHistoryTabLocal;

    public class ScoreHandler extends EventDispatcher
    {
        ///- Singleton Instance
        private static var _instance:ScoreHandler = null;

        ///- Private Locals
        private var _gvars:GlobalVariables = GlobalVariables.instance;
        private var _avars:ArcGlobals = ArcGlobals.instance;
        private var _lang:Language = Language.instance;

        ///- Constructor
        public function ScoreHandler(en:SingletonEnforcer)
        {
            if (en == null)
                throw Error("Multi-Instance Blocked");
        }

        public static function get instance():ScoreHandler
        {
            if (_instance == null)
                _instance = new ScoreHandler(new SingletonEnforcer());
            return _instance;
        }

        //******************************************************************************************//
        // Score Saving
        //******************************************************************************************//

        /**
         * Generates a score has that needs to be matched on the server for
         * a score to be considered valid.
         * @param result PostVars
         * @return SHA1 Hash
         */
        private function getSaveHash(result:Object):String
        {
            var dataSerial:String = "";
            dataSerial += "amazing:" + result.amazing + ",";
            dataSerial += "perfect:" + result.perfect + ",";
            dataSerial += "good:" + result.good + ",";
            dataSerial += "average:" + result.average + ",";
            dataSerial += "miss:" + result.miss + ",";
            dataSerial += "boo:" + result.boo + ",";
            dataSerial += "max_combo:" + result.max_combo + ",";
            dataSerial += "score:" + result.score + ",";
            dataSerial += "replay:" + result.replay + ",";
            dataSerial += "level:" + result.level + ",";
            dataSerial += "session:" + result.session + ",";
            dataSerial += "uid:" + _gvars.playerUser.siteId + ",";
            dataSerial += "ses:" + _gvars.playerUser.hash + ",";
            dataSerial += R3::HASH_STRING;
            return SHA1.hash(dataSerial);
        }

        /**
         * Calculates if a given score is valid and can be saved on the server. Depending on the flags,
         * this checks different criteria.
         * @param result GameScoreSeult to check.
         * @param valid_score Check for mods that aren't valid for highscore.
         * @param valid_replay Check for mods that aren't valid for replays.
         * @param check_replay Check if score was from a replay. Also checks for positive score.
         * @param check_alt_engine Check for Alt Engine. Also checks user isn't guest.
         * @return
         */
        public function canSendScore(result:GameScoreResult, valid_score:Boolean = true, valid_replay:Boolean = true, check_replay:Boolean = true, check_alt_engine:Boolean = true):Boolean
        {
            var ret:Boolean = false;
            ret ||= valid_score && !result.options.isScoreValid(true, false);
            ret ||= valid_replay && !result.options.isScoreValid(false, true);
            ret ||= check_replay && (result.replayData == null || result.replayData.length <= 0 || result.score <= 0 || (result.options.replay && result.options.replay.isEdited) || result.user.siteId != _gvars.playerUser.siteId)
            ret ||= check_alt_engine && (result.user.isGuest || result.songInfo.engine != null);
            return !ret;
        }

        /**
         * Calculates if a given score is valid and can be updated on the server. Depending on the flags,
         * this checks different criteria. This slightly differents from the canSendScore as some mods
         * are allowed to be sent to the server that aren't recorded on the highscores like rates.
         * @param result GameScoreSeult to check.
         * @param valid_score Check for mods that aren't valid for highscore.
         * @param valid_replay Check for mods that aren't valid for replays.
         * @param check_replay Check if score was from a replay. Also checks for positive score.
         * @param check_alt_engine Check for Alt Engine. Also checks user isn't guest.
         * @return
         */
        public function canUpdateScore(result:GameScoreResult, valid_score:Boolean = true, valid_replay:Boolean = true, check_replay:Boolean = true, check_alt_engine:Boolean = true):Boolean
        {
            var ret:Boolean = false;
            ret ||= valid_score && !result.options.isScoreUpdated(true, false);
            ret ||= valid_replay && !result.options.isScoreUpdated(false, true);
            ret ||= check_replay && (result.replayData.length <= 0 || result.score <= 0 || (result.options.replay && result.options.replay.isEdited) || result.user.siteId != _gvars.playerUser.siteId)
            ret ||= check_alt_engine && (result.user.isGuest || result.songInfo.engine != null);
            return !ret;
        }

        /**
         * Submits a score to the website for the given GameScoreResult.
         */
        public function sendScore(gameResult:GameScoreResult):void
        {
            if (gameResult.songInfo.engine)
                sendAltEngineScore(gameResult);
            else
                sendCanonScore(gameResult);
        }

        public function sendCanonScore(gameResult:GameScoreResult):void
        {
            if (gameResult.songInfo.engine)
                return;

            if (!canSendScore(gameResult, true, true, false, false))
            {
                Alert.add(_lang.string("game_result_error_enabled_mods"), 90, Alert.RED);
                return;
            }

            // Loader
            const _loader:URLLoader = new URLLoader();
            addLoaderListeners(_loader, onComplete, onFailure);

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.SONG_SAVE_URL));
            var postData:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(postData);

            // Post Game Data
            postData.level = gameResult.level;
            postData.update = canUpdateScore(gameResult, true, true, false, false);
            postData.rate = gameResult.options.songRate;
            postData.restarts = gameResult.restarts;
            postData.accuracy = gameResult.accuracy_frames;
            postData.amazing = gameResult.amazing;
            postData.perfect = gameResult.perfect;
            postData.good = gameResult.good;
            postData.average = gameResult.average;
            postData.miss = gameResult.miss;
            postData.boo = gameResult.boo;
            postData.max_combo = gameResult.max_combo;
            postData.score = gameResult.score;
            postData.replay = Replay.getReplayString(gameResult.replayData);
            postData.replay_bin = gameResult.replay_bin_encoded;
            postData.save_settings = JSON.stringify(gameResult.options.settingsEncode());
            postData.restart_stats = JSON.stringify(gameResult.restart_stats);
            postData.session = _gvars.userSession;
            postData.start_time = gameResult.start_time;
            postData.start_hash = gameResult.start_hash;
            postData.hashMap = getSaveHash(postData);

            // Set Request
            req.data = postData;
            req.method = URLRequestMethod.POST;
            _loader.load(req);

            function onComplete(e:Event):void
            {
                Logger.info(instance, "Canon Data Loaded");
                removeLoaderListeners(_loader, onComplete, onFailure);

                // Parse Response
                var siteDataString:String = e.target.data;
                var data:Object;
                try
                {
                    data = JSON.parse(siteDataString);
                }
                catch (err:Error)
                {
                    Logger.error(instance, "Canon Parse Failure: " + Logger.exception_error(err));
                    Logger.error(instance, "Wrote invalid response data to log folder. [logs/c_result.txt]");
                    AirContext.writeTextFile(AirContext.getAppFile("logs/c_result.txt"), siteDataString);

                    Alert.add(_lang.string("error_failed_to_save_results") + " (ERR: JSON_ERROR)", 360, Alert.RED);

                    instance.dispatchEvent(new ScoreHandlerEvent(ScoreHandlerEvent.FAILURE, gameResult, _lang.string("results_score_saved_failed"), ""));

                    return;
                }

                // Has Reponse
                Logger.success(instance, "Score Save Result: " + data.result);

                if (data.result == 0)
                {
                    Alert.add(_lang.string("game_result_save_success"), 90, Alert.DARK_GREEN);

                    // Server Message
                    if (data.gServerMessage != null)
                        Alert.add(data.gServerMessage, 360);

                    // Server Message Popup
                    if (data.gServerMessageFull != null)
                    {
                        _gvars.gameMain.addPopupQueue(new PopupMessage(_gvars.gameMain, data.gServerMessageFull, data.gServerMessageTitle ? data.gServerMessageTitle : ""));
                    }

                    // Token Unlock
                    if (data.token_unlocks != null)
                    {
                        for each (var token_item:Object in data.token_unlocks)
                        {
                            _gvars.gameMain.addPopupQueue(new PopupTokenUnlock(_gvars.gameMain, token_item.type, token_item.ID, token_item.text));
                            _gvars.unlockTokenById(token_item.type, token_item.ID);
                        }
                    }
                    else if (data.tUnlock != null)
                    {
                        _gvars.gameMain.addPopupQueue(new PopupTokenUnlock(_gvars.gameMain, data.tType, data.tID, data.tText, data.tName, data.tMessage));
                        _gvars.unlockTokenById(data.tType, data.tID);
                    }

                    // Update Data
                    _gvars.playerUser.grandTotal += gameResult.score_total;
                    _gvars.playerUser.credits += gameResult.credits;

                    Playlist.instanceCanon.updateSongAccess();

                    // Valid Legal Score
                    if (postData.update)
                    {
                        _gvars.songResultRanks[gameResult.game_index] = {error: false, old_ranking: data.old_ranking, new_ranking: data.new_ranking};

                        // Check Old vs New Rankings.
                        if (data.new_ranking < data.old_ranking && data.old_ranking > 0)
                            Alert.add(sprintf(_lang.string("new_best_rank"), {"old": data.old_ranking, "new": data.new_ranking, "diff": ((data.old_ranking - data.new_ranking) * -1)}), 240, Alert.DARK_GREEN);

                        // Check raw score vs level ranks and update.
                        var songInfo:SongInfo = gameResult.songInfo;

                        var previousLevelRanks:Object = _gvars.playerUser.level_ranks[songInfo.level];
                        var newLevelRanks:Object = {"id": songInfo.level,
                                "genre": songInfo.genre,
                                "rank": data.new_ranking,
                                "score": gameResult.score,
                                "results": gameResult.pa_string + "-" + gameResult.max_combo,
                                "perfect": gameResult.amazing + gameResult.perfect,
                                "plays": 1,
                                "aaas": int(gameResult.is_aaa),
                                "fcs": int(gameResult.is_fc),
                                "good": gameResult.good,
                                "average": gameResult.average,
                                "miss": gameResult.miss,
                                "boo": gameResult.boo,
                                "maxcombo": gameResult.max_combo,
                                "rawscore": gameResult.score,
                                "equiv": SkillRating.calcSongWeightFromScore(gameResult.score, songInfo)};

                        // Update Level Ranks is missing or better.
                        if (previousLevelRanks == null || gameResult.score > previousLevelRanks.score)
                        {
                            // Update Counts for Play, FC, AAA from previous.
                            if (previousLevelRanks != null)
                            {
                                newLevelRanks["plays"] += previousLevelRanks["plays"];
                                newLevelRanks["aaas"] += previousLevelRanks["aaas"];
                                newLevelRanks["fcs"] += previousLevelRanks["fcs"];
                            }
                            _gvars.playerUser.level_ranks[songInfo.level] = newLevelRanks;

                            // Update/replace Skill Rating top X song if better than our lowest SR equiv
                            _gvars.playerUser.updateSRList(newLevelRanks);
                        }

                        // Update Counters
                        else
                        {
                            previousLevelRanks["plays"] += newLevelRanks["plays"];
                            previousLevelRanks["aaas"] += newLevelRanks["aaas"];
                            previousLevelRanks["fcs"] += newLevelRanks["fcs"];
                        }

                        instance.dispatchEvent(new ScoreHandlerEvent(ScoreHandlerEvent.SUCCESS, gameResult, sprintf(_lang.string("results_rank"), {rank: _gvars.songResultRanks[gameResult.game_index].new_ranking}), sprintf(_lang.string("results_last_rank"), {rank: _gvars.songResultRanks[gameResult.game_index].old_ranking})));
                    }
                    else
                    {
                        instance.dispatchEvent(new ScoreHandlerEvent(ScoreHandlerEvent.FAILURE, gameResult, _lang.string("results_game_mods_enabled_1"), _lang.string("results_game_mods_enabled_2")));
                    }
                }
                else
                {
                    if (data.ignore)
                    {
                        _gvars.songResultRanks[gameResult.game_index] = {error: true, text1: "", text2: ""};
                        instance.dispatchEvent(new ScoreHandlerEvent(ScoreHandlerEvent.SUCCESS, gameResult, "", ""));
                    }
                    else
                    {
                        _gvars.songResultRanks[gameResult.game_index] = {error: true, text1: _lang.string("results_score_save_failed"), text2: "(ERR: " + data.result + ")"};
                        instance.dispatchEvent(new ScoreHandlerEvent(ScoreHandlerEvent.FAILURE, gameResult, _lang.string("results_score_save_failed"), "(ERR: " + data.result + ")"));
                    }
                }
            }

            function onFailure(e:ErrorEvent = null):void
            {
                Logger.error(instance, "Canon Score Save Failure: " + Logger.event_error(e));
                removeLoaderListeners(_loader, onComplete, onFailure);
                Alert.add(_lang.string("error_server_connection_failure"), 120, Alert.RED);

                _gvars.songResultRanks[gameResult.game_index] = {error: true, text1: _lang.string("results_score_save_failed"), text2: "(ERR: Connect)"};

                instance.dispatchEvent(new ScoreHandlerEvent(ScoreHandlerEvent.FAILURE, gameResult, _lang.string("results_score_save_failed"), ""))
            }
        }

        //******************************************************************************************//
        // Alt Engine Score Saving
        //******************************************************************************************//

        /**
         * Sends a post request to saves score for alt engines. This shouldn't
         * be called directly and instead you shoulkd simple call `sendScore()`
         * which will call this is necessary.
         */
        public function sendAltEngineScore(gameResult:GameScoreResult):void
        {
            if (!gameResult.songInfo.engine)
                return;

            // Update Local Alt Engine Levelranks
            if (((gameResult.legacyLastRank = _avars.legacyLevelRanksGet(gameResult.songInfo)) || {score: 0}).score < gameResult.score)
            {
                _avars.legacyLevelRanksSet(gameResult.songInfo, {"score": gameResult.score,
                        "rank": 0,
                        "perfect": gameResult.amazing + gameResult.perfect,
                        "good": gameResult.good,
                        "average": gameResult.average,
                        "miss": gameResult.miss,
                        "boo": gameResult.boo,
                        "maxcombo": gameResult.max_combo,
                        "rawscore": gameResult.score,
                        "results": gameResult.pa_string + "-" + gameResult.max_combo,
                        "arrows": gameResult.song.totalNotes});
                _avars.legacyLevelRanksSave();
            }

            // Loader
            const _loader:URLLoader = new URLLoader();
            addLoaderListeners(_loader, onComplete, onFailure);

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.ALT_SONG_SAVE_URL));
            var scoreSender:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(scoreSender);
            var sd:Object = {"arrows": gameResult.song.chart.Notes.length, // Playlist XML often lies.
                    "author": gameResult.songInfo.author,
                    "difficulty": gameResult.songInfo.difficulty,
                    "genre": gameResult.songInfo.genre,
                    "level": gameResult.songInfo.level,
                    "levelid": gameResult.songInfo.level_id,
                    "name": gameResult.songInfo.name,
                    "stepauthor": gameResult.songInfo.stepauthor,
                    "time": gameResult.songInfo.time};

            // Post Game Data
            var dataObject:Object = {};
            dataObject.engine = gameResult.songInfo.engine;
            dataObject.song_data = sd;
            dataObject.level = gameResult.level;
            dataObject.rate = gameResult.options.songRate;
            dataObject.restarts = gameResult.restarts;
            dataObject.accuracy = gameResult.accuracy_frames;
            dataObject.amazing = gameResult.amazing;
            dataObject.perfect = gameResult.perfect;
            dataObject.good = gameResult.good;
            dataObject.average = gameResult.average;
            dataObject.miss = gameResult.miss;
            dataObject.boo = gameResult.boo;
            dataObject.max_combo = gameResult.max_combo;
            dataObject.score = gameResult.score;
            dataObject.replay = Replay.getReplayString(gameResult.replayData);
            dataObject.replay_bin = gameResult.replay_bin_encoded;
            dataObject.save_settings = gameResult.options.settingsEncode();
            dataObject.session = _gvars.userSession;
            dataObject.hashMap = getSaveHash(dataObject);
            scoreSender.data = JSON.stringify(dataObject);
            scoreSender.session = _gvars.userSession;

            // Set Request
            req.data = scoreSender;
            req.method = URLRequestMethod.POST;
            _loader.load(req);

            function onComplete(e:Event):void
            {
                Logger.info(instance, "Alt Data Loaded");
                removeLoaderListeners(_loader, onComplete, onFailure);

                // Parse Response
                var siteDataString:String = e.target.data;
                var data:Object;
                try
                {
                    data = JSON.parse(siteDataString);
                }
                catch (err:Error)
                {
                    Logger.error(instance, "Alt Parse Failure: " + Logger.exception_error(err));
                    Logger.error(instance, "Wrote invalid response data to log folder. [logs/a_result.txt]");
                    AirContext.writeTextFile(AirContext.getAppFile("logs/a_result.txt"), siteDataString);
                    return;
                }

                // Has Reponse
                Logger.success(instance, "Alt Score Save Result: " + data.result);

                if (data.result == 0)
                {
                    // Server Message
                    if (data.gServerMessage != null)
                    {
                        Alert.add(data.gServerMessage, 360);
                    }

                    // Server Message Popup
                    if (data.gServerMessageFull != null)
                    {
                        _gvars.gameMain.addPopupQueue(new PopupMessage(_gvars.gameMain, data.gServerMessageFull, data.gServerMessageTitle ? data.gServerMessageTitle : ""));
                    }

                    // Token Unlock
                    if (data.tUnlock != null)
                    {
                        _gvars.gameMain.addPopupQueue(new PopupTokenUnlock(_gvars.gameMain, data.tType, data.tID, data.tText, data.tName, data.tMessage));
                    }

                    // Display Popup Queue
                    _gvars.gameMain.displayPopupQueue();
                }
            }

            function onFailure(err:ErrorEvent = null):void
            {
                Logger.error(instance, "Alt Score Save Failure: " + Logger.event_error(err));
                removeLoaderListeners(_loader, onComplete, onFailure);
            }
        }

        //******************************************************************************************//
        // Replay Saving
        //******************************************************************************************//

        /**
         * Saves a local replays to the session replays in the F2 menu.
         * This will also record the replay into a .txt file if
         * `Auto-Save Replays` is enabled in the settings screen.
         */
        public function saveLocalReplay(result:GameScoreResult):void
        {
            if (!canSendScore(result, true, false, true, false))
                return;

            var nR:Replay = new Replay(_gvars.gameIndex);
            nR.user = _gvars.playerUser;
            nR.level = result.songInfo.level;
            nR.settings = result.options.settingsEncode();
            if (result.songInfo.engine)
                nR.settings.arc_engine = _avars.legacyEncode(result.songInfo);
            nR.score = result.score;
            nR.perfect = (result.amazing + result.perfect);
            nR.good = result.good;
            nR.average = result.average;
            nR.miss = result.miss;
            nR.boo = result.boo;
            nR.maxcombo = result.max_combo;
            nR.replayData = result.replayData;
            nR.replayBin = result.replayBin;
            nR.timestamp = int(new Date().getTime() / 1000);
            nR.song = result.songInfo;
            _gvars.replayHistory.unshift(nR);

            // Display F2 Shortcut key only once per session.
            if (!Flags.VALUES[Flags.F2_REPLAYS])
            {
                Alert.add(_lang.string("replay_save_success"), 150);
                Flags.VALUES[Flags.F2_REPLAYS] = true;
            }

            // Write Local txt Replay Encode
            if (_gvars.air_autoSaveLocalReplays && result.replayBin != null)
            {
                try
                {
                    var path:String = AirContext.getReplayPath(result.song);
                    path += (result.song.songInfo.level_id ? result.song.songInfo.level_id : result.song.id.toString())
                    path += "_" + (new Date().getTime())
                    path += "_" + (result.pa_string + "-" + result.max_combo);
                    path += ".txt";

                    // Store Bin Encoded Replay
                    if (!AirContext.doesFileExist(path))
                    {
                        AirContext.writeTextFile(AirContext.getAppFile(path), nR.getEncode());

                        var cachePath:String = path.substr(Constant.REPLAY_PATH.length);
                        _gvars.file_replay_cache.setValue(cachePath, result.replay_cache_object);
                        _gvars.file_replay_cache.save();

                        ReplayHistoryTabLocal.REPLAYS.push(nR);
                    }
                }
                catch (err:Error)
                {
                    Logger.error(this, "Local Replay Save Error: " + Logger.exception_error(err));
                }
            }
        }

        /**
         * Sends a post for the replay of selected GameScoreResult.
         */
        public function saveServerReplay(gameResult:GameScoreResult):void
        {
            // Loader
            const _loader:URLLoader = new URLLoader();
            addLoaderListeners(_loader, onComplete, onFailure);

            var req:URLRequest = new URLRequest(URLs.resolve(URLs.USER_SAVE_REPLAY_URL));
            var scoreSender:URLVariables = new URLVariables();
            Constant.addDefaultRequestVariables(scoreSender);

            // Post Game Data
            scoreSender.level = gameResult.level;
            scoreSender.update = canUpdateScore(gameResult, true, true, false, false);
            scoreSender.rate = gameResult.options.songRate;
            scoreSender.restarts = gameResult.restarts;
            scoreSender.accuracy = gameResult.accuracy_frames;
            scoreSender.amazing = gameResult.amazing;
            scoreSender.perfect = gameResult.perfect;
            scoreSender.good = gameResult.good;
            scoreSender.average = gameResult.average;
            scoreSender.miss = gameResult.miss;
            scoreSender.boo = gameResult.boo;
            scoreSender.max_combo = gameResult.max_combo;
            scoreSender.score = gameResult.score;
            scoreSender.replay = Replay.getReplayString(gameResult.replayData);
            scoreSender.replay_bin = gameResult.replay_bin_encoded;
            scoreSender.save_settings = JSON.stringify(gameResult.options.settingsEncode());
            scoreSender.session = _gvars.userSession;
            scoreSender.start_time = gameResult.start_time;
            scoreSender.start_hash = gameResult.start_hash;
            scoreSender.hash = SHA1.hash(scoreSender.replay + _gvars.activeUser.siteId);

            // Set Request
            req.data = scoreSender;
            req.method = URLRequestMethod.POST;

            // Saving Vars
            _loader.load(req);

            function onComplete(e:Event):void
            {
                removeLoaderListeners(_loader, onComplete, onFailure);

                var data:Object = JSON.parse(e.target.data);

                Alert.add(_lang.string("replay_save_status_" + data.result), 90, (data.result == 0 ? Alert.GREEN : Alert.RED));
            }

            function onFailure(e:Event = null):void
            {
                removeLoaderListeners(_loader, onComplete, onFailure);
                Alert.add(_lang.string("error_server_connection_failure"), 120, Alert.RED);
            }
        }

        /**
         * Adds the event listeners for the url loader.
         * @param completeHandler On Complete Handler
         * @param errorHandler On Error Handler
         */
        private function addLoaderListeners(_loader:URLLoader, completeHandler:Function, errorHandler:Function):void
        {
            _loader.addEventListener(Event.COMPLETE, completeHandler);
            _loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
        }

        /**
         * Removes the event listeners for the url loader.
         * @param completeHandler On Complete Handler
         * @param errorHandler On Error Handler
         */
        private function removeLoaderListeners(_loader:URLLoader, completeHandler:Function, errorHandler:Function):void
        {
            _loader.removeEventListener(Event.COMPLETE, completeHandler);
            _loader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
            _loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
        }
    }
}

class SingletonEnforcer
{
}
