package classes
{

    public class SongInfo
    {
        public static const SONG_TYPE_PUBLIC:int = 0;
        public static const SONG_TYPE_TOKEN:int = 1;
        public static const SONG_TYPE_PURCHASED:int = 2;
        public static const SONG_TYPE_SECRET:int = 3;

        // Engine Variables
        public var access:int;
        public var chart_type:String;
        public var song_type:int;
        public var index:int;

        public var score_raw:int;
        public var score_total:int;

        // Song Variables
        public var genre:int;
        public var level:int;
        public var name:String;
        public var name_original:String;
        public var name_explicit:String;
        public var subtitle:String;
        public var difficulty:int;
        public var note_count:int;
        public var order:int;
        public var style:String;
        public var tags:String;

        public var author:String;
        public var author_original:String;
        public var author_url:String;
        public var author_html:String;

        public var stepauthor:String;
        public var stepauthor_html:String;

        public var play_hash:String;
        public var swf_hash:String;

        public var prerelease:Boolean;
        public var release_date:uint;

        public var min_nps:int;
        public var max_nps:int;

        public var time:String;
        public var time_secs:int;
        public var time_end:Number;

        public var is_unranked:Boolean = false;
        public var is_explicit:Boolean = false;
        public var is_legacy:Boolean = false;
        public var is_disabled:Boolean = false;

        // Song - Optional
        public var price:int;
        public var credits:int;

        // Alt Engines Variables
        public var engine:Object;
        public var level_id:String;
        public var sync:int;

        public function SongInfo()
        {

        }

        public function compareTo(s2:SongInfo):Boolean
        {
            return compare(this, s2);
        }

        public static function compare(s1:SongInfo, s2:SongInfo):Boolean
        {
            if (!s1 || !s2)
                return false;

            if (s1.engine && s2.engine && s1.engine.id != s2.engine.id)
                return false;

            if (s1.level > 0 && s2.level > 0 && s1.level != s2.level)
                return false;

            if (s1.level_id && s2.level_id && s1.level_id != s2.level_id)
                return false;

            return true;
        }
    }
}
