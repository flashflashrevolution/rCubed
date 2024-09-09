package menu
{
    import by.blooddy.crypto.MD5;
    import classes.SongInfo;
    import classes.chart.Note;
    import classes.chart.NoteChart;
    import classes.chart.Song;
    import classes.chart.parse.ExternalChartBase;
    import flash.filesystem.File;
    import game.GameOptions;

    public class FileLoader
    {
        private static var _gvars:GlobalVariables = GlobalVariables.instance;

        public static var cache:FileCache = new FileCache("chart_cache.json", 1);

        public static var ENGINE_INFO:Object = {name: "File Loader",
                id: "fileloader",
                config_url: "",
                ignoreCache: true,
                legacySync: false,
                playlistURL: "",
                songURL: ""}

        public static function buildSongInfo(loc:String, id:int, isUnique:Boolean = false):SongInfo
        {
            if (loc == null || loc.length == 0)
                return null;

            // Parse Chart
            var emb:ExternalChartBase = new ExternalChartBase();
            if (emb.load(new File(loc)))
            {
                var chartinfo:Object = emb.getInfo();
                var chartData:Object = emb.getValidChartData(id);

                // Build Song Info
                var songInfo:SongInfo = new SongInfo();
                songInfo.access = GlobalVariables.SONG_ACCESS_PLAYABLE;
                songInfo.genre = 14;
                songInfo.author = songInfo.author_html = chartinfo.author;
                songInfo.stepauthor = songInfo.stepauthor_html = chartinfo.stepauthor;
                songInfo.name = chartinfo.display;
                songInfo.level = 1;
                songInfo.level_id = MD5.hash(id + emb.ID);
                songInfo.note_count = chartinfo.arrows;
                songInfo.time = chartinfo.time;
                songInfo.time_secs = chartinfo.time_secs;
                songInfo.time_end = 0;
                songInfo.background = chartinfo.background != "" ? chartinfo.folder + chartinfo.background : null;

                if (isUnique)
                {
                    songInfo.engine = {id: "fileloader", cache_id: emb.ID, chart_id: id};
                }
                else
                {
                    ENGINE_INFO.cache_id = emb.ID;
                    ENGINE_INFO.chart_id = id;
                    songInfo.engine = ENGINE_INFO;
                }

                // File Loader Assistance
                songInfo.is_local = true;
                songInfo.chart_parser = emb;

                return songInfo;
            }

            return null;
        }

        public static function buildSong(info:SongInfo):void
        {
            if (!info.is_local)
                return;

            const emb:ExternalChartBase = info.chart_parser;
            const id:int = info.engine.chart_id;

            emb.parseData();

            var chartData:Object = emb.getValidChartData(id);

            ENGINE_INFO.cache_id = emb.ID;
            ENGINE_INFO.chart_id = id;

            // Build Chart
            var noteChart:NoteChart = new NoteChart();
            noteChart.type = "EXTERNAL";
            for each (var note:Array in chartData.notes)
            {
                noteChart.Notes.push(new Note(note[1], note[0], note[2], Math.floor(note[0] * 30)));
            }

            // Build Song
            var song:Song = new Song(info, false);
            song.chart = noteChart;
            song.loadSoundBytes(emb.getAudioData());
            song.isChartLoaded = song.isMusicLoaded = song.isLoaded = true;

            // Setup Loading
            _gvars.externalSongInfo = info;
            _gvars.externalSong = song;
        }

        public static function setupLocalFile(loc:String, id:int):Boolean
        {
            var info:SongInfo = buildSongInfo(loc, id);
            if (info != null)
            {
                buildSong(info);
                return true;
            }
            return false;
        }

        public static function loadLocalFile(loc:String, id:int):void
        {
            if (setupLocalFile(loc, id))
            {
                _gvars.songQueue = [_gvars.externalSongInfo];

                _gvars.options = new GameOptions();
                _gvars.options.fill();
                _gvars.gameMain.switchTo(Main.GAME_PLAY_PANEL);
            }
        }
    }
}
