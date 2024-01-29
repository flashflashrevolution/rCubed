package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSongLoadProgress implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var progress:int;
        public var isLoaded:Boolean;

        public function MPCFFRSongLoadProgress(room:MPRoomFFR, progress:int, isLoaded:Boolean):void
        {
            this.room = room;
            this.progress = progress;
            this.isLoaded = isLoaded;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "loading",
                    "d": {
                        "uid": room.uid,
                        "progress": progress,
                        "complete": isLoaded
                    }});
        }
    }
}
