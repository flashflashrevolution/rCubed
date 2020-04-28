package sql
{

    public class SQLSongDetails
    {
        public var engine:String = "";
        public var song_id:String = "";
        public var notes:String = "";
        public var set_mirror_invert:Boolean = false;
        public var set_custom_offsets:Boolean = false;
        public var offset_music:Number = 0;
        public var offset_judge:Number = 0;

        public function SQLSongDetails(result:Object):void
        {
            engine = result.engine;
            song_id = result.engine;
            notes = result.notes;
            set_mirror_invert = result.set_mirror_invert == 1;
            set_custom_offsets = result.set_custom_offsets == 1;
            offset_music = result.offset_music;
            offset_judge = result.offset_judge;
        }
    }
}
