package classes.mp.commands
{
    import classes.mp.room.MPRoomFFR;

    public class MPCFFRSongRate implements IMPCommand
    {
        public var room:MPRoomFFR;
        public var rate:Number;

        public function MPCFFRSongRate(room:MPRoomFFR, rate:Number):void
        {
            this.room = room;
            this.rate = rate;
        }

        public function toJSON():String
        {
            return JSON.stringify({"t": "mode",
                    "a": "song_rate",
                    "d": {
                        "uid": room.uid,
                        "rate": rate
                    }});
        }
    }
}
