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
        public var rep_notes:Array;
        public var rep_boos:Array;
        public var checksum:uint;
        public var rechecksum:uint;
        public var replay_bin:ByteArray;
    }

}
