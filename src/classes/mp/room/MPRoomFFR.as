package classes.mp.room
{

    import classes.Playlist;
    import classes.SongInfo;
    import classes.chart.Song;
    import classes.mp.MPSocketDataRaw;
    import classes.mp.MPSocketDataText;
    import classes.mp.MPSong;
    import classes.mp.MPTeam;
    import classes.mp.MPUser;
    import classes.mp.commands.MPCFFRSongPlayable;
    import classes.mp.commands.MPCFFRSongRate;
    import classes.mp.events.MPEvent;
    import classes.mp.events.MPRoomEvent;
    import classes.mp.events.MPRoomRawEvent;
    import classes.mp.mode.ffr.MPFFRState;
    import classes.mp.mode.ffr.MPMatchFFR;
    import classes.mp.mode.ffr.MPMatchFFRUser;
    import classes.mp.mode.ffr.MPMatchResultsFFR;
    import flash.utils.Dictionary;
    import game.GameScoreResult;
    import menu.FileLoader;

    public class MPRoomFFR extends MPRoom
    {
        public var songData:MPSong = new MPSong();
        public var songInfo:SongInfo;
        public var song:Song;

        public var activeMatch:MPMatchFFR;

        public var lastMatch:MPMatchResultsFFR;
        public var lastMatchHistory:Vector.<MPMatchResultsFFR>;
        public var lastMatchIndex:int = -1;
        public var lastMatchScorePersonal:GameScoreResult;

        public var player_states:Vector.<MPFFRState> = new <MPFFRState>[];
        public var player_state_map:Dictionary = new Dictionary(true);

        public function MPRoomFFR():void
        {
            super();
        }

        override public function update(data:Object):void
        {
            super.update(data);

            if (data.vars != undefined)
            {
                if (data.vars.mode != undefined)
                    updateVarsMode(data.vars.mode);

                if (data.vars.user != undefined)
                    updateVarsUser(data.vars.user);
            }

            if (data.match != undefined)
                updateLastMatch(data.match);
        }

        override public function clearExtra():void
        {
            super.clearExtra();

            activeMatch = null;
            lastMatchHistory = null;
        }

        public function updateVarsMode(modeData:Object):void
        {
            if (modeData.song_details != undefined)
            {
                songData.update(modeData.song_details);
                updateSongInfo();
                updateAccessCheck();
            }
        }

        public function updateVarsUser(userData:Array):void
        {
            for (var i:Number = userData.length - 1; i >= 0; i--)
            {
                var user:MPUser = getUser(userData[i].uid);
                var userVars:MPFFRState = player_state_map[user.uid];

                if (userVars == null)
                {
                    userVars = new MPFFRState(this, user);
                    player_states.push(userVars);
                    player_state_map[user.uid] = userVars;
                }
                userVars.update(userData[i]);
            }

            _clearMissingPlayerData();
        }

        public function updateLastMatch(matchInfo:Object):void
        {
            lastMatch = new MPMatchResultsFFR(this, lastMatchHistory.length);
            lastMatch.update(matchInfo);
            lastMatchHistory.push(lastMatch);
        }

        override public function onJoin():void
        {
            super.onJoin();

            activeMatch = new MPMatchFFR(this);
            lastMatchHistory = new <MPMatchResultsFFR>[];
        }

        override public function userJoinTeam(user:MPUser, teamUID:int, vars:Object = null):void
        {
            super.userJoinTeam(user, teamUID);

            var team:MPTeam = teams_map[teamUID];
            if (team && !team.spectator)
            {
                var needPlayerData:Boolean = true;
                for (var i:Number = player_states.length - 1; i >= 0; i--)
                {
                    if (player_states[i].user === user)
                    {
                        needPlayerData = false;
                    }
                }

                if (needPlayerData)
                {
                    const playerData:MPFFRState = new MPFFRState(this, user);
                    playerData.update(vars);
                    player_states.push(playerData);
                    player_state_map[user.uid] = playerData;
                }

                if (_mp.currentUser == user)
                    updateAccessCheck();
            }
        }

        override public function userLeaveTeam(user:MPUser, teamUID:int):void
        {
            super.userLeaveTeam(user, teamUID);

            var team:MPTeam = teams_map[teamUID];
            if (team && !team.spectator)
            {
                for (var i:Number = player_states.length - 1; i >= 0; i--)
                {
                    if (player_states[i].user === user)
                    {
                        player_states.splice(i, 1);
                    }
                }

                delete player_state_map[user.uid];
            }
        }

        override public function modeCommand(cmd:MPSocketDataText, user:MPUser):void
        {
            switch (cmd.action)
            {
                case "game_state":
                    modeGameState(user, cmd);
                    break;

                case "playable_state":
                    modePlayableState(user, cmd);
                    break;

                case "song_rate":
                    modeSongRate(user, cmd);
                    break;

                case "song_change":
                    modeSongChange(user, cmd);
                    break;

                case "song_request":
                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SONG_REQUEST, cmd, this, user));
                    break;

                case "ready_state":
                    modeReadyState(user, cmd);
                    break;

                case "force_start":
                    update(cmd.data);
                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_FORCE_START, cmd, this, user));
                    break;

                case "loading_start":
                    update(cmd.data);
                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_LOADING_START, cmd, this, user));
                    break;

                case "loading":
                    modeLoadingProgress(user, cmd);
                    break;

                case "loading_abort":
                    update(cmd.data);
                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_LOADING_ABORT, cmd, this, user));
                    break;

                case "countdown":
                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_COUNTDOWN, cmd, this, user));
                    break;

                case "match_start":
                    modeMatchStart(user, cmd);
                    break;

                case "song_start":
                    modeSongStart(user, cmd);
                    break;

                case "score_update":
                    modeScoreUpdate(user, cmd);
                    break;

                case "score_update_users":
                    modeScoreUpdateInProgress(user, cmd);
                    break;

                case "match_end":
                    update(cmd.data);
                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_MATCH_END, cmd, this, user));
                    break;

                default:
                    trace("unknown mode command:");
                    trace(user, cmd);
                    break;
            }
        }

        override public function modeRawCommand(cmd:MPSocketDataRaw, user:MPUser):void
        {
            switch (cmd.action)
            {
                case MPEvent.FFR_RAW_REQUEST_PLAYBACK:
                    _mp.dispatchEvent(new MPRoomRawEvent(MPEvent.FFR_GET_PLAYBACK, cmd, this, user));
                    break;
            }
        }

        private function modeSongChange(user:MPUser, cmd:MPSocketDataText):void
        {
            songData.update(cmd.data);
            updateSongInfo(user, cmd);
            updateAccessCheck();
        }

        private function modeGameState(user:MPUser, cmd:MPSocketDataText):void
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return;

            playerVars.game_state = cmd.data.value;
            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_GAME_STATE, cmd, this, user));
        }

        private function modePlayableState(user:MPUser, cmd:MPSocketDataText):void
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return;

            playerVars.playable_state = cmd.data.value;
            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_PLAYABLE_STATE, cmd, this, user));
        }

        private function modeSongRate(user:MPUser, cmd:MPSocketDataText):void
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return;

            playerVars.song_rate = cmd.data.value;
            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SONG_RATE, cmd, this, user));
        }

        private function modeLoadingProgress(user:MPUser, cmd:MPSocketDataText):void
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return;

            playerVars.loading_state = cmd.data.complete;
            playerVars.loading_percent = cmd.data.value;

            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_LOADING, cmd, this, user));
        }

        private function modeReadyState(user:MPUser, cmd:MPSocketDataText):void
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return;

            playerVars.ready_state = cmd.data.value;
            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_READY_STATE, cmd, this, user));
        }

        private function modeMatchStart(user:MPUser, cmd:MPSocketDataText):void
        {
            activeMatch = new MPMatchFFR(this);
            activeMatch.build(cmd.data);

            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_MATCH_START, cmd, this, user));
        }

        private function modeSongStart(user:MPUser, cmd:MPSocketDataText):void
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return;

            playerVars.game_state = cmd.data.game_state;
            playerVars.settings = cmd.data.settings;
            playerVars.noteskin = cmd.data.noteskin;
            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SONG_START, cmd, this, user));
        }

        private function modeScoreUpdate(user:MPUser, cmd:MPSocketDataText):void
        {
            activeMatch.update(cmd.data);
            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SCORE_UPDATE, cmd, this, user));
        }

        private function modeScoreUpdateInProgress(user:MPUser, cmd:MPSocketDataText):void
        {
            activeMatch.build(cmd.data);
            _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SCORE_UPDATE, cmd, this, user));
        }

        ///////////////////////////////////////////////////////////////////////

        private function updateSongInfo(user:MPUser = null, cmd:MPSocketDataText = null):void
        {
            songInfo = null;

            if (songData == null || !songData.selected)
            {
                _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SONG_CHANGE, cmd, this, user));
                return;
            }

            var loadedPlaylist:Playlist = Playlist.instance;
            var isAltLoaded:Boolean = loadedPlaylist.engine != null;

            // Alt Engine
            if (songData.engine)
            {
                if (songData.engine.id == "fileloader")
                {
                    if (songData.engine.cacheID != undefined)
                    {
                        const chartPath:String = FileLoader.cache.findKey(function(entry:Object):Object
                        {
                            return entry["id"] == songData.engine.cacheID;
                        });

                        songInfo = FileLoader.buildSongInfo(chartPath, songData.engine.chartID, true);
                    }

                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SONG_CHANGE, cmd, this, user));
                    return;
                }
                else
                {
                    songInfo = new SongInfo();
                    songInfo.engine = songData.engine;
                    songInfo.level = songData.id;
                    songInfo.level_id = songData.level_id;
                    songInfo.name = songData.name;
                    songInfo.author = songData.author;
                    songInfo.time = songData.time;
                    songInfo.note_count = songData.note_count;
                    songInfo.difficulty = songData.difficulty;
                    _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SONG_CHANGE, cmd, this, user));
                    return;
                }
            }
            // Canon Engine
            else
            {
                const ffrSongsMatch:Vector.<SongInfo> = Playlist.instanceCanon.indexList.filter(function(item:SongInfo, index:int, vec:Vector.<SongInfo>):Boolean
                {
                    return item.level == songData.id;
                });

                if (ffrSongsMatch.length == 1)
                    songInfo = ffrSongsMatch[0];

                _mp.dispatchEvent(new MPRoomEvent(MPEvent.FFR_SONG_CHANGE, cmd, this, user));
            }
        }

        public function updateAccessCheck():void
        {
            var cmd_play:MPCFFRSongPlayable = new MPCFFRSongPlayable(this);
            if (songInfo != null)
            {
                cmd_play.canPlay = songInfo.access == 0;
                cmd_play.id = songInfo.level;
                cmd_play.level_id = songInfo.level_id;
                cmd_play.engine = songInfo.engine;
            }
            else
                cmd_play.canPlay = false;
            _mp.sendCommand(cmd_play);

            _mp.sendCommand(new MPCFFRSongRate(this, GlobalVariables.instance.playerUser.songRate));
        }

        public function getPlayerVariables(user:MPUser):MPFFRState
        {
            return player_state_map[user.uid];
        }

        public function getPlayerScore(user:MPUser):MPMatchFFRUser
        {
            return activeMatch.users_map[user.uid];
        }

        public function getPlayerState(user:MPUser):String
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return null;

            return playerVars.game_state;
        }

        public function getPlayerSongRate(user:MPUser):Number
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return 1;

            return playerVars.song_rate;
        }

        override public function isPlayerReady(user:MPUser):Boolean
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return false;

            return playerVars.ready_state;
        }

        public function canAllUsersPlay():Boolean
        {
            var canPlay:Boolean = true;

            for (var i:Number = player_states.length - 1; i >= 0; i--)
            {
                const vars:MPFFRState = player_states[i];

                if (vars.playable_state != 1)
                {
                    canPlay = false;
                    break;
                }
            }

            return canPlay;
        }

        public function isAllPlayersReady():Boolean
        {
            var isReady:Boolean = true;

            for (var i:Number = player_states.length - 1; i >= 0; i--)
            {
                const vars:MPFFRState = player_states[i];

                if (vars.user != owner && !vars.ready_state)
                {
                    isReady = false;
                    break;
                }
            }

            return isReady;
        }

        override public function canUserPlaySong(user:MPUser):Boolean
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return false;

            return playerVars.playable_state == 1;
        }

        public function isSongLoaded():Boolean
        {
            return song != null && song.isLoaded;
        }

        public function isPlayerLoaded(user:MPUser):Boolean
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return false;

            return playerVars.loading_state;
        }

        public function getPlayerLoadingProgress(user:MPUser):Number
        {
            const playerVars:MPFFRState = player_state_map[user.uid];
            if (!playerVars)
                return 0;

            return playerVars.loading_percent;
        }

        private function _clearMissingPlayerData():void
        {
            for (var i:Number = player_states.length - 1; i >= 0; i--)
            {
                var playerData:MPFFRState = player_states[i];

                if (!isPlayer(playerData.user))
                {
                    player_states.splice(i, 1);
                    delete player_state_map[playerData.user.uid];
                }
            }
        }

        public function get isCurrentPlayer():Boolean
        {
            return !this.teamSpectator.contains(_mp.currentUser);
        }

        override public function toString():String
        {
            return "[MPRoomFFR uid=" + uid + ", name=" + name + "]";
        }
    }
}
