package sql
{

    public class SQLSongDetails
    {
        public var notes:String = "";
        public var set_mirror_invert:Boolean = false;
        public var set_custom_offsets:Boolean = false;
        public var offset_music:Number = 0;
        public var offset_judge:Number = 0;

        public function SQLSongDetails(source:Object):void
        {
            if (source == null)
                return;

            if (source.notes != null)
                notes = source.notes;

            if (source.set_mirror_invert != null)
                set_mirror_invert = source.set_mirror_invert;

            if (source.set_custom_offsets != null)
                set_custom_offsets = source.set_custom_offsets;

            if (source.offset_music != null)
                offset_music = source.offset_music;

            if (source.offset_judge != null)
                offset_judge = source.offset_judge;
        }

        /**
         * Called when `JSON.stringify` is called on this object automatically.
         * @param k
         * @return Object representing this class.
         */
        public function toJSON(k:*):Object
        {
            var out:Object = {};

            if (notes.length > 0)
                out["notes"] = notes;

            if (offset_music != 0)
                out["offset_music"] = offset_music;

            if (offset_judge != 0)
                out["offset_judge"] = offset_judge;

            if (set_mirror_invert)
                out["set_mirror_invert"] = set_mirror_invert;

            if (set_custom_offsets)
                out["set_custom_offsets"] = set_custom_offsets;

            return out;
        }
    }
}
