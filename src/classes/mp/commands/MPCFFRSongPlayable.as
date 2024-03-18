package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSongPlayable implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var canPlay:Boolean;

        public function MPCFFRSongPlayable(room:MPRoomFFR, canPlay:Boolean):void
        {
            this.room = room;
            this.canPlay = canPlay;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "song_playable",
                    "d": {
                        "uid": room.uid,
                        "playable": canPlay
                    }});
        }
    }
}
