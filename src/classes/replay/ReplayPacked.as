package classes.replay
{
    import flash.utils.ByteArray;

    public class ReplayPacked
    {
        public var MAGIC:String;
        public var MAJOR_VER:uint;
        public var MINOR_VER:uint;
        public var user_id:uint;
        public var song_id:uint;
        public var song_rate:Number;
        public var timestamp:uint;
        public var judgements:Object;
        public var raw_judgements:String;
        public var settings:Object;
        public var raw_settings:String;
        public var rep_notes:Vector.<ReplayBinFrame>;
        public var rep_boos:Vector.<ReplayBinFrame>;
        public var checksum:uint;
        public var rechecksum:uint;
        public var replay_bin:ByteArray;

        public var error:String;

        public function get VERSION():uint
        {
            return MAJOR_VER * 1000 + MINOR_VER;
        }

        public function update():void
        {
            var i:int;

            // 1.0 -> 1.1:
            // Judge ms Inversion
            if (MAJOR_VER == 1 && MINOR_VER == 0)
            {
                for (i = 0; i < rep_notes.length; i++)
                {
                    rep_notes[i].time = rep_notes[i].time * -1;
                }

                MAJOR_VER = 1;
                MINOR_VER = 1;
            }
        }
    }
}
