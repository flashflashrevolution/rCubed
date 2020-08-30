package classes
{
    import classes.replay.Replay;

    public class SongPreview extends Replay
    {
        public function SongPreview(song_id:int)
        {
            super(song_id);
            this.level = song_id;
        }

        public function setupSongPreview(songData:Object = null):void
        {
            var _gvars:GlobalVariables = GlobalVariables.instance;

            if (!songData)
                songData = Playlist.instanceCanon.playList[this.level];

            if (!songData)
                return;

            this.level = songData.level;

            this.user = new User(false, false, 1743546);
            this.user.id = 1743546;
            this.user.name = "Song Preview";
            this.user.skillLevel = _gvars.MAX_DIFFICULTY;
            this.user.loadAvatar();

            this.timestamp = Math.floor((new Date()).getTime() / 1000);
            this.settings = _gvars.playerUser.settings;

            this.isPreview = true;
            this.isLoaded = true;

            _gvars.options.loadPreview = true;
            _gvars.options.fill();
        }
    }

}
