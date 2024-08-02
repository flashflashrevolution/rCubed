package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSongPlayable implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var canPlay:Boolean;

        public var id:uint;
        public var level_id:String;
        public var engine:Object;

        public function MPCFFRSongPlayable(room:MPRoomFFR):void
        {
            this.room = room;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "song_playable",
                    "d": {
                        "uid": room.uid,
                        "playable": canPlay,
                        "id": id,
                        "level_id": level_id,
                        "engine": engine
                    }});
        }
    }
}
