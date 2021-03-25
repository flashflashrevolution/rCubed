package classes
{

    public class SongInfo
    {
        public static const SONG_TYPE_PUBLIC:int = 0;
        public static const SONG_TYPE_TOKEN:int = 1;
        public static const SONG_TYPE_PURCHASED:int = 2;
        public static const SONG_TYPE_SECRET:int = 3;

        public var access:int; //GlobalVariables.SONG_ACCESS_PLAYABLE
        public var noteCount:int; //0
        public var author:String = ""; //"Luka Megurine"
        public var authorURL:String = ""; //""
        public var authorwithurl:String = ""; //"Luka Megurine"
        public var chartType:String; //"ChartFFRL"
        public var credits:int; //0
        public var difficulty:int; //84
        public var engine:Object; //Object@cd01419
        public var genre:int; //2
        public var index:int; //513
        public var length:int; //0
        public var level:int; //1139
        public var minNps:int; //0
        public var maxNps:int; //0
        public var name:String; //"Excalibur"
        public var order:int; //0
        public var playhash:String; //""
        public var prerelease:Boolean;
        public var previewhash:String; //""
        public var price:int; //0
        public var releasedate:uint;
        public var scoreRaw:int; //0
        public var scoreTotal:int; //0
        public var songType:int;
        public var stepauthor:String = ""; //"Condoct"
        public var stepauthorURL:String = ""; //""
        public var stepauthorwithurl:String = ""; //"<a href="https://www.flashflashrevolution.com/profile/Condoct">Condoct</a>"
        public var style:String; //"other"
        public var sync:int; //0
        public var time:String; //"2:12"
        public var timeSecs:int; //132

        public var levelid:int;
        public var songRating:Number;

        public function SongInfo()
        {

        }
    }
}
