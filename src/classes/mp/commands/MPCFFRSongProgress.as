package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSongProgress implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var progress:Number;

        public function MPCFFRSongProgress(room:MPRoomFFR, progress:Number):void
        {
            this.room = room;
            this.progress = progress;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "song_progress",
                    "d": {
                        "uid": room.uid,
                        "progress": progress
                    }});
        }
    }
}
