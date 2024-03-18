package classes.mp.components.chatlog
{
    import classes.Language;
    import classes.mp.MPSong;
    import classes.mp.MPUser;
    import classes.mp.Multiplayer;
    import classes.mp.commands.MPCFFRSong;
    import classes.mp.room.MPRoom;
    import classes.mp.room.MPRoomFFR;
    import classes.ui.BoxButton;
    import classes.ui.Text;
    import com.flashfla.utils.sprintf;
    import flash.events.Event;

    public class MPChatLogEntrySong extends MPChatLogEntry
    {
        private static const _lang:Language = Language.instance;
        private static const _mp:Multiplayer = Multiplayer.instance;

        private var room:MPRoom;
        private var user:MPUser;
        private var song:MPSong;

        private var btn:BoxButton;

        public function MPChatLogEntrySong(room:MPRoom, user:MPUser, song:MPSong):void
        {
            this.room = room;
            this.user = user;
            this.song = song;
        }

        override public function build(width:Number):void
        {
            if (built)
                return;

            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.beginFill(0xFFFFFF, 0.1);
            this.graphics.drawRect(5, 5, width - 11, 45);
            this.graphics.endFill();

            new Text(this, 10, 7, sprintf(_lang.string("mp_room_ffr_song_request"), {user: user.name}), 10, "#c3c3c3").setAreaParams(width - 120, 22);
            new Text(this, 9, 25, song.name, 12).setAreaParams(width - 110, 22);

            btn = new BoxButton(this, width - 96, 14, 85, 26, _lang.string("mp_room_ffr_song_request_select"), 11, e_songSelect);

            _height = 52;
            built = true;
        }

        private function e_songSelect(e:Event):void
        {
            if (room.owner == _mp.currentUser)
            {
                var cmd:MPCFFRSong = new MPCFFRSong(room as MPRoomFFR);
                cmd.name = song.name;
                cmd.author = song.author;
                cmd.time = song.time;
                cmd.note_count = song.note_count;
                cmd.difficulty = song.difficulty;
                cmd.engine = song.engine;
                cmd.id = song.id;
                cmd.level_id = song.level_id;

                // File Loader
                if (song.engine && song.engine.id == "fileloader")
                    cmd.engine = {"id": "fileloader",
                            "cacheID": song.engine.cache_id,
                            "chartID": song.engine.chart_id};

                _mp.sendCommand(cmd);
            }
        }
    }
}
