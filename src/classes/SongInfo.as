package classes
{

    public class SongInfo
    {
        public static const SONG_TYPE_PUBLIC:int = 0;
        public static const SONG_TYPE_TOKEN:int = 1;
        public static const SONG_TYPE_PURCHASED:int = 2;
        public static const SONG_TYPE_SECRET:int = 3;

        public var access:int;
        public var noteCount:int;
        public var author:String;
        public var authorURL:String;
        public var authorwithurl:String;
        public var chartType:String;
        public var credits:int;
        public var difficulty:int;
        public var engine:Object;
        public var genre:int;
        public var index:int;
        public var length:int;
        public var level:int;
        public var minNps:int;
        public var maxNps:int;
        public var name:String;
        public var order:int;
        public var playhash:String;
        public var prerelease:Boolean;
        public var previewhash:String;
        public var price:int;
        public var releasedate:uint;
        public var scoreRaw:int;
        public var scoreTotal:int;
        public var songType:int;
        public var stepauthor:String;
        public var stepauthorURL:String;
        public var stepauthorwithurl:String;
        public var style:String;
        public var sync:int;
        public var time:String;
        public var timeSecs:int;

        public var levelId:String;
        public var songRating:Number;

        public function SongInfo()
        {

        }
    }
}
