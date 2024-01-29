package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSongLoadError implements IMPCommand
    {
        public var room:MPRoomFFR;

        public function MPCFFRSongLoadError(room:MPRoomFFR):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "loading_error",
                    "d": {
                        "uid": room.uid
                    }});
        }
    }
}
