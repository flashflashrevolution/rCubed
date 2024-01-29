package classes.mp.mode.ffr
{
    import classes.Playlist;
    import classes.SongInfo;
    import classes.mp.MPSong;
    import classes.mp.room.MPRoomFFR;
    import com.flashfla.utils.TimeUtil;
    import menu.FileLoader;

    public class MPMatchResultsFFR
    {
        public var room:MPRoomFFR;

        public var index:int;
        public var teamMode:Boolean = false;
        public var songData:MPSong = new MPSong();
        public var songInfo:SongInfo = new SongInfo();
        public var teams:Vector.<MPMatchResultsTeam> = new <MPMatchResultsTeam>[];
        public var users:Vector.<MPMatchResultsUser> = new <MPMatchResultsUser>[];

        private var _winnerText:String;

        public function MPMatchResultsFFR(room:MPRoomFFR, index:int):void
        {
            this.room = room;
            this.index = index;
        }

        public function update(info:Object):void
        {
            if (info.song != undefined)
            {
                songData.update(info.song);
                updateSongInfo();
            }

            if (info.teamMode != undefined)
                teamMode = info.teamMode;

            if (info.teams != undefined)
            {
                teams.length = 0;
                users.length = 0;

                for each (var mp_team:Object in info.teams)
                {
                    const team:MPMatchResultsTeam = new MPMatchResultsTeam();
                    team.update(mp_team);
                    teams.push(team);

                    for each (var user:Object in mp_team.users)
                    {
                        const mpuser:MPMatchResultsUser = new MPMatchResultsUser();
                        mpuser.update(user);
                        mpuser.team = team;
                        mpuser.index = users.length;

                        mpuser.score.songInfo = songInfo;

                        team.users.push(mpuser);
                        users.push(mpuser);
                    }
                }

                _winnerText = _generateWinnerText();
            }

            if (info.timestamp != undefined)
            {
                for each (var score_user:MPMatchResultsUser in users)
                {
                    score_user.score.end_time = TimeUtil.getFormattedDate(new Date(info.timestamp));
                }
            }
        }

        private function updateSongInfo():void
        {
            songInfo = null;

            if (songData == null)
                return;

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
                        return;
                    }
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

                    songInfo.time_end = 0;
                    songInfo.time_secs = (Number(songInfo.time.split(":")[0]) * 60) + Number(songInfo.time.split(":")[1]);
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
            }
        }

        public function get winnerText():String
        {
            return _winnerText
        }

        private function _generateWinnerText():String
        {
            if ((teamMode && teams.length == 0) || (!teamMode && users.length == 0))
            {
                return "Missingno????";
            }

            var winnerText:String = "";

            if (teamMode)
            {
                const teamList:Vector.<MPMatchResultsTeam> = teams.filter(function(item:MPMatchResultsTeam, index:int, vec:Vector.<MPMatchResultsTeam>):Boolean
                {
                    return item.position == 1;
                });

                for each (var team:MPMatchResultsTeam in teamList)
                    winnerText += team.name + ", ";
            }
            else
            {
                var userWinner:String = "";
                const userList:Vector.<MPMatchResultsUser> = users.filter(function(item:MPMatchResultsUser, index:int, vec:Vector.<MPMatchResultsUser>):Boolean
                {
                    return item.position == 1;
                });

                for each (var user:MPMatchResultsUser in userList)
                    winnerText += user.name + ", ";
            }

            return winnerText.substr(0, winnerText.length - 2);
        }
    }
}
