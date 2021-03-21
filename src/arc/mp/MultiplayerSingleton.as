package arc.mp
{
    import arc.mp.MultiplayerPanel;
    import classes.Playlist;
    import classes.Room;
    import classes.User;
    import classes.Gameplay;
    import classes.chart.Song;
    import classes.replay.Replay;
    import com.flashfla.net.Multiplayer;
    import com.flashfla.net.events.ErrorEvent;
    import com.flashfla.net.events.ConnectionEvent;
    import com.flashfla.net.events.LoginEvent;
    import com.flashfla.net.events.RoomListEvent;
    import com.flashfla.net.events.RoomJoinedEvent;
    import com.flashfla.net.events.RoomLeftEvent;
    import com.flashfla.net.events.RoomUserEvent;
    import com.flashfla.net.events.MessageEvent;
    import com.flashfla.net.events.GameResultsEvent;
    import com.flashfla.net.events.GameStartEvent;
    import com.flashfla.net.events.GameUpdateEvent;
    import com.flashfla.net.events.RoomUserStatusEvent;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.utils.Timer;
    import game.GameOptions;
    import game.GameScoreResult;
    import menu.MainMenu;
    import menu.MenuPanel;
    import menu.MenuSongSelection;

    public class MultiplayerSingleton extends Object
    {
        private var _gvars:GlobalVariables = GlobalVariables.instance;

        public var connection:Multiplayer;

        public var username:String;
        public var password:String;

        private var autoJoin:Boolean;

        private var currentRoom:Room = null;
        private var currentSong:Object = null;
        private var currentSongFile:Song = null;
        private var currentStatus:int = 0;

        private var panel:MultiplayerPanel = null;

        private static var instance:MultiplayerSingleton = null;

        public static function getInstance():MultiplayerSingleton
        {
            if (instance == null)
                instance = new MultiplayerSingleton();
            return instance;
        }

        public static function destroyInstance():void
        {
            if (instance && instance.connection && instance.connection.connected)
                instance.connection.disconnect();
            instance = null;
        }

        public function getPanel(parent:MenuPanel):MultiplayerPanel
        {
            if (panel == null)
                panel = new MultiplayerPanel(parent);
            panel.setParent(parent);
            panel.hideBackground(true);
            panel.setRoomsVisibility(true);
            return panel;
        }

        public function MultiplayerSingleton()
        {
            var self:MultiplayerSingleton = this;

            username = _gvars.activeUser.name;
            password = _gvars.activeUser.hash;

            connection = new Multiplayer();

            connection.addEventListener(Multiplayer.EVENT_ERROR, onError);
            connection.addEventListener(Multiplayer.EVENT_CONNECTION, onConnection);
            connection.addEventListener(Multiplayer.EVENT_LOGIN, onLogin);
            connection.addEventListener(Multiplayer.EVENT_ROOM_LIST, onRoomList);
            connection.addEventListener(Multiplayer.EVENT_ROOM_JOINED, onRoomJoined);
            connection.addEventListener(Multiplayer.EVENT_ROOM_LEFT, onRoomLeft);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER, onRoomUser);
            connection.addEventListener(Multiplayer.EVENT_ROOM_USER_STATUS, onRoomUserStatus);
            connection.addEventListener(Multiplayer.EVENT_MESSAGE, onMessage);
            connection.addEventListener(Multiplayer.EVENT_GAME_RESULTS, onGameResults);
            connection.addEventListener(Multiplayer.EVENT_GAME_START, onGameStart);
        }

        public function get currentUser():User
        {
            return connection.currentUser
        }

        private function onError(event:ErrorEvent):void
        {
            _gvars.gameMain.addAlert("MP Error: " + event.message);
        }

        private function onConnection(event:ConnectionEvent):void
        {
            if (connection.connected)
            {
                autoJoin = false;
                connection.login(username, password);
            }
        }

        private function onLogin(event:LoginEvent):void
        {
            if (!connection.currentUser.loggedIn)
                connection.disconnect();
        }

        private function onRoomList(event:RoomListEvent):void
        {
            if (!autoJoin)
                connection.joinLobby();
        }

        private function onRoomJoined(event:RoomJoinedEvent):void
        {
            if (event.room == connection.lobby)
            {
                if (autoJoin)
                {
                    connection.refreshRooms();
                }

                autoJoin = true;
            }
            else
            {
                currentRoom = event.room;
            }
        }

        private function onRoomLeft(event:RoomLeftEvent):void
        {
            currentRoom = null;
        }

        private function onRoomUser(event:RoomUserEvent):void
        {
            updateRoomUser(event.room, event.user);
        }

        private function onRoomUserStatus(event:RoomUserStatusEvent):void
        {
            updateRoomUser(event.room, event.user);
        }

        private function updateRoomUser(room:Room, user:User):void
        {
            if (user != null && room.isGameRoom && user.id != currentUser.id && room.isPlayer(currentUser) && room.isPlayer(user))
                _gvars.gameMain.addAlert("A Challenger Appears! " + user.name);
        }

        private function onMessage(event:MessageEvent):void
        {
            if (event.msgType == Multiplayer.MESSAGE_PRIVATE)
                _gvars.gameMain.addAlert("*** " + event.user.name + ": " + event.message);
        }

        private function forEachRoom(func:Function):void
        {
            if (!connection.connected)
                return;
            for each (var room:Room in connection.rooms)
            {
                if (room.isGameRoom)
                    func(room);
            }
        }

        private function gameplayUpdateRoom(gameplay:Gameplay = null):void
        {
            if (gameplay == null)
                gameplay = new Gameplay();

            if (gameplay.status)
                gameplay.status = currentStatus;

            if (gameplay.songName == null || gameplay.songID)
            {
                gameplay.song = currentSong;
                if (currentSong == null)
                    gameplay.songName = "No Song Selected";
            }

            if (currentSongFile != null && !currentSongFile.isLoaded)
                gameplay.statusLoading = currentSongFile.progress;

            forEachRoom(function(room:Room):void
            {
                connection.setRoomGameplay(room, gameplay);
            });
        }

        // Should be called in MenuSongSelection whenever the selection changes.
        public function gameplayPicking(song:Object):void
        {
            currentSong = song;
            currentSongFile = null;

            currentStatus = Multiplayer.STATUS_PICKING;
            gameplayUpdateRoom();
        }

        public function gameplayCanPick():Boolean
        {
            var isPlayer:Boolean = false;
            forEachRoom(function(room:Room):void
            {
                if (room.isPlayer(currentUser))
                    isPlayer = true;
            });
            return isPlayer;
        }

        // Called by MultiplayerPlayer when you click on the song label/name
        public function gameplayPick(song:Object):void
        {
            if (currentStatus >= Multiplayer.STATUS_PLAYING || song == null)
                return;

            var playlistEngineID:Object = Playlist.instance.engine ? Playlist.instance.engine.id : null;
            if (playlistEngineID == (song.engine ? song.engine.id : null))
            {
                var mmenu:MainMenu = _gvars.gameMain.activePanel as MainMenu;
                mmenu.switchTo(MainMenu.MENU_SONGSELECTION);
                (mmenu._MenuSingleplayer as MenuSongSelection).multiplayerSelect(song.name, song);
            }
            else
            {
                if (gameplayCompareSong(song, currentSong))
                    gameplayLoading();
                else
                {
                    if (song.engine)
                        gameplayPicking(song);
                    else if (_gvars.checkSongAccess(song) == GlobalVariables.SONG_ACCESS_PLAYABLE)
                        gameplayPicking(song);
                }
            }
        }

        private function gameplayCompareSong(s1:Object, s2:Object):Boolean
        {
            if (!s1 || !s2)
                return false;

            if (s1.engine && s2.engine && s1.engine.id != s2.engine.id)
                return false;

            if (s1.level > 0 && s2.level > 0 && s1.level != s2.level)
                return false;

            if (s1.levelid && s2.levelid && s1.levelid != s2.levelid)
                return false;

            return true;
        }

        // Starts loading the selected song.
        public function gameplayLoading():void
        {
            _gvars.options = new GameOptions();
            _gvars.options.fill();
            currentSongFile = _gvars.getSongFile(currentSong);

            currentStatus = Multiplayer.STATUS_LOADING;
            gameplayUpdateRoom();

            if (gameplayLoadingStatus())
            {
                gameplayReady();
            }
            else
            {
                var songFile:Song = currentSongFile;
                songFile.addEventListener(Event.COMPLETE, function(event:Event):void
                {
                    songFile.removeEventListener(Event.COMPLETE, arguments.callee);
                    if (gameplayLoadingStatus() && currentSongFile == songFile)
                    {
                        gameplayReady();
                    }
                });

                var timer:Timer = new Timer(400);
                timer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void
                {
                    if (currentStatus != Multiplayer.STATUS_LOADING || gameplayLoadingStatus())
                        timer.stop();
                    else
                    {
                        if (currentSongFile && currentSongFile.loadFail)
                        {
                            _gvars.removeSongFile(currentSongFile);
                            _gvars.gameMain.addAlert(currentSong.name + " failed to load");
                            currentSongFile = null;
                            currentStatus = Multiplayer.STATUS_PICKING;
                            timer.stop();
                        }
                        gameplayUpdateRoom();
                    }
                });
                timer.start();
            }
        }

        // Used to check if the song is done loading yet
        public function gameplayLoadingStatus():Boolean
        {
            return currentSongFile != null && currentSongFile.isLoaded;
        }

        public function gameplayPlayingStatus():Boolean
        {
            return currentStatus == Multiplayer.STATUS_PLAYING;
        }

        public function gameplayPlayingStatusResults():Boolean
        {
            return currentStatus == Multiplayer.STATUS_RESULTS;
        }

        public function gameplayHasOpponent():Boolean
        {
            var ret:Boolean = false;
            forEachRoom(function(room:Room):void
            {
                if (room.isPlayer(currentUser) && room.playerCount > 1)
                    ret = true;
            });
            return ret;
        }

        // Should be called once a song is finished loading
        public function gameplayReady():void
        {
            currentStatus = Multiplayer.STATUS_LOADED;
            gameplayUpdateRoom();
        }

        public function isInRoom():Boolean
        {
            return currentRoom != null;
        }

        private function onGameResults(event:GameResultsEvent):void
        {
            var room:Room = event.room;
            if (room.getPlayerIndex(currentUser) == 1 && (connection.mode == Multiplayer.GAME_LEGACY || room.variables["gameScoreRecorded"] != "y"))
                gameplaySubmit(room);

            for each (var player:User in room.match.players)
            {
                if (player.id == connection.currentUser.id)
                    continue;

                var gameplay:Object = room.match.gameplay[player.id];
                if (gameplay && gameplay.replay)
                {
                    var replay:Replay = new Replay(new Date().getTime());
                    replay.parseEncode(gameplay.replay);
                    if (!replay.isEdited && replay.isValid())
                        _gvars.replayHistory.unshift(replay);
                }
            }
        }

        private function onGameStart(event:GameStartEvent):void
        {
            var room:Room = event.room;
            if (room.isPlayer(currentUser))
                gameplayStart(room);
        }

        public function spectateGame(room:Room):void
        {
            var song:Object = room.match.song;
            _gvars.songQueue = [song];
            _gvars.options = new GameOptions();
            _gvars.options.mpRoom = room;
            _gvars.options.fill();
            if (_gvars.options.frameRate <= 30)
                _gvars.options.frameRate = 60;
            _gvars.options.isAutoplay = true;
            _gvars.options.songRate = 1;
            _gvars.options.isolationOffset = _gvars.options.isolationLength = 0;
            _gvars.options.loadPreview = true;
            _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
        }

        public function gameplayStart(room:Room):void
        {
            if (connection.mode == Multiplayer.GAME_VELOCITY)
            {
                var newGameplay:Gameplay = new Gameplay();
                newGameplay.gameScoreRecorded = false; // "n"
                gameplayUpdateRoom(newGameplay);
            }
            else
            {
                gameplayUpdateRoom();
            }

            currentStatus = Multiplayer.STATUS_PLAYING;

            _gvars.options = new GameOptions();
            _gvars.options.mpRoom = room;
            _gvars.options.fill();
            _gvars.options.song = currentSongFile;
            _gvars.options.judgeWindow = null;
            _gvars.options.isolationOffset = _gvars.options.isolationLength = 0;
            _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
        }

        public function gameplayPlaying(play:Object):Boolean
        {
            if (!_gvars.options.mpRoom || currentStatus != Multiplayer.STATUS_PLAYING)
                return false;

            play.addEventListener(Multiplayer.EVENT_GAME_UPDATE, onGameUpdate);
            return true;
        }

        private function onGameUpdate(event:GameUpdateEvent):void
        {
            if (!_gvars.options.mpRoom || currentStatus != Multiplayer.STATUS_PLAYING)
                return;

            var updatedGameplay:Gameplay = new Gameplay();
            updatedGameplay.score = event.gameScore;
            updatedGameplay.life = event.gameLife;
            updatedGameplay.maxCombo = event.hitMaxCombo;
            updatedGameplay.combo = event.hitCombo;
            updatedGameplay.amazing = event.hitAmazing;
            updatedGameplay.perfect = event.hitPerfect;
            updatedGameplay.good = event.hitGood;
            updatedGameplay.average = event.hitAverage;
            updatedGameplay.miss = event.hitMiss;
            updatedGameplay.boo = event.hitBoo;

            gameplayUpdateRoom(updatedGameplay);
        }

        public function gameplayResults(gameResults:MenuPanel, songResults:Vector.<GameScoreResult>):void
        {
            var room:Room = _gvars.options.mpRoom;

            if (!room || !room.isPlayer(currentUser) || currentStatus != Multiplayer.STATUS_PLAYING)
                return;

            currentStatus = Multiplayer.STATUS_RESULTS;

            var sendingScore:Boolean = (room.match.status == Multiplayer.STATUS_RESULTS && ((connection.mode == Multiplayer.GAME_LEGACY && room.getPlayerIndex(currentUser) == 1) || (connection.mode == Multiplayer.GAME_VELOCITY && room.variables["gameScoreRecorded"] != "y")));

            var replay:Replay = null;
            var results:GameScoreResult = null;
            for each (var result:GameScoreResult in songResults)
            {
                if (result.song_entry == currentSong)
                {
                    results = result;
                    break;
                }
            }
            if (results && results.song)
            {
                for each (var r:Replay in _gvars.replayHistory)
                {
                    if (r.level == results.song.id && r.score == results.score)
                    {
                        replay = r;
                        break;
                    }
                }
            }
            var data:Gameplay = new Gameplay();
            if (results)
            {
                data.score = results.score, data.life = 24, data.maxCombo = results.max_combo, data.combo = results.combo, data.amazing = results.amazing, data.perfect = results.perfect, data.good = results.good, data.average = results.average, data.miss = results.miss, data.boo = results.boo
            }

            if (sendingScore)
                data.gameScoreRecorded = true; // "y"
            if (replay)
                data.encodedReplay = replay.getEncode();
            gameplayUpdateRoom(data);

            var panel:MultiplayerPanel = getPanel(gameResults);
            gameResults.addChild(panel);
            panel.hideBackground(false);
            panel.setRoomsVisibility(false);
            panel.hideRoom(room, true);

            if (sendingScore)
                gameplaySubmit(room);
        }

        public function gameplaySubmit(room:Room):void
        {
            var matchSong:Object = currentSong || room.match.song;

            if (matchSong != null && matchSong.engine != null)
                return;

            var convertNumber:Function = function(value:int):String
            {
                return velocity ? Multiplayer.dec2hex(value) : value.toString();
            };

            var currentUserIdx:int = room.getPlayerIndex(currentUser)
            var velocity:Boolean = (connection.mode == Multiplayer.GAME_VELOCITY);
            var results1:Object = room.match.gameplay[(room.match.players[1] || {}).userID];
            var results2:Object = room.match.gameplay[(room.match.players[2] || {}).userID];
            var currentOpponent:User = (currentUserIdx == 1 ? room.match.players[2] : room.match.players[1]);
            var resultsOpponent:Object = (currentUserIdx == 1 ? results2 : results1);

            if (!currentOpponent)
                return;

            if (results1 == null)
                results1 = {score: 1, life: 0, maxcombo: 0, combo: 0, amazing: 0, perfect: 0, good: 0, average: 0, miss: 0, boo: 0};
            if (results2 == null)
                results2 = {score: 1, life: 0, maxcombo: 0, combo: 0, amazing: 0, perfect: 0, good: 0, average: 0, miss: 0, boo: 0};

            var data:URLVariables = new URLVariables();
            data.gamestats = matchSong.name + ":" + convertNumber(results1.score) + ":" + convertNumber(results1.life) + ":" + convertNumber(results1.maxcombo) + ":" + convertNumber(results1.combo) + ":" + convertNumber(results1.amazing + results1.perfect) + ":" + convertNumber(results1.good) + ":" + convertNumber(results1.average) + ":" + convertNumber(results1.miss) + ":" + convertNumber(results1.boo) + ":" + matchSong.name + ":" + convertNumber(results2.score) + ":" + convertNumber(results2.life) + ":" + convertNumber(results2.maxcombo) + ":" + convertNumber(results2.combo) + ":" + convertNumber(results2.amazing + results2.perfect) + ":" + convertNumber(results2.good) + ":" + convertNumber(results2.average) + ":" + convertNumber(results2.miss) + ":" + convertNumber(results2.boo);
            if (results1.score != results2.score && results1.score > 0 && results2.score > 0)
            {
                data.winner = results1.score > results2.score ? 1 : 2;
                data.loser = results1.score < results2.score ? 1 : 2;
            }
            data["player" + currentUserIdx + "id"] = (velocity ? connection.currentUser.id : connection.currentUser.name);
            data["player" + room.getPlayerIndex(currentOpponent) + "id"] = (velocity ? resultsOpponent.siteID : currentOpponent.name);

            var loader:URLLoader = new URLLoader();
            var request:URLRequest = new URLRequest(velocity ? Constant.MULTIPLAYER_SUBMIT_URL_VELOCITY : Constant.MULTIPLAYER_SUBMIT_URL);
            request.method = URLRequestMethod.POST;
            request.data = data;
            loader.load(request);

            if (velocity)
                connection.sendRoomVariables(room, {"gameScoreRecorded": "y"});
        }

        // Call after results screen / on main menu
        public function gameplayReset():void
        {
            currentSong = null;
            currentSongFile = null;
            currentStatus = Multiplayer.STATUS_CLEANUP;
            gameplayUpdateRoom();
        }
    }
}
