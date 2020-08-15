package classes
{
    import classes.replay.Replay;
    import classes.replay.ReplayNote;

    public class SongPreview extends Replay
    {
        public function SongPreview(song_id:int)
        {
            super(song_id);
            this.level = song_id;
        }

        public function setupSongPreview():void
        {
            var _gvars:GlobalVariables = GlobalVariables.instance;
            var songData:Object = Playlist.instanceCanon.playList[this.level];

            if (!songData)
                return;

            this.user = new User(false, false, 1743546);
            this.user.id = 1743546;
            this.user.name = "Song Preview";
            this.user.skillLevel = _gvars.MAX_DIFFICULTY;

            this.timestamp = Math.floor((new Date()).getTime() / 1000);
            this.score = songData["arrows"] * 50;
            this.perfect = songData["arrows"];
            this.good = 0;
            this.average = 0
            this.miss = 0;
            this.boo = 0;
            this.maxcombo = songData["arrows"];
            this.settings = _gvars.playerUser.settings;
            this.settings.viewOffset = 0;
            this.settings.judgeOffset = 0;

            this.replay = [];

            var genNotes:Array = [];
            for (var i:int = 0; i < this.maxcombo; i++)
                genNotes.push(0);

            this.generationReplayNotes = genNotes;
            this.needsBeatboxGeneration = true;
            this.isLoaded = true;

            _gvars.options.fill();
        }
    }

}
