package classes.user
{
    import classes.SongInfo;
    import classes.user.UserSongData;
    import com.flashfla.utils.ObjectUtil;
    import flash.filesystem.File;

    public class UserSongNotes
    {
        public static var sql_data:Object = getTemplate();

        /**
         * Get default JSON template as a new object.
         * @return
         */
        public static function getTemplate():Object
        {
            return {"db_info": {
                        "version": 1
                    },
                    "song_details": {}};
        }

        /**
         * Load a parsed JSON object into the song details.
         * @param obj Source Object
         */
        public static function loadFromObject(obj:Object):void
        {
            if (obj == null)
            {
                sql_data = getTemplate();
                return;
            }

            var parsed_data:Object = getTemplate();

            // DB Info
            if (obj.db_info != null)
            {
                for (var info_key:String in obj.db_info)
                {
                    parsed_data.db_info[info_key] = obj.db_info[info_key];
                }
            }

            // Song Details
            if (obj.song_details != null)
            {
                for (var engine_id:String in obj.song_details)
                {
                    parsed_data.song_details[engine_id] = {};
                    var engine:Object = obj.song_details[engine_id];
                    for (var level_id:String in engine)
                    {
                        if (engine[level_id] != null && ObjectUtil.count(engine[level_id]) > 0)
                            parsed_data.song_details[engine_id][level_id] = new UserSongData(engine_id, level_id, engine[level_id]);
                    }
                }
            }

            sql_data = parsed_data;
        }

        public static function getSongUserInfo(songInfo:SongInfo):UserSongData
        {
            if (songInfo.engine != null)
                return getSongDetails(songInfo.engine.id, songInfo.level_id);

            return getSongDetails(Constant.BRAND_NAME_SHORT_LOWER, songInfo.level.toString());
        }

        /**
         * Returns the Song Details for the given song and engine, or null if missing.
         * @param engine_id
         * @param level_id
         * @return
         */
        public static function getSongDetails(engine_id:String, level_id:String):UserSongData
        {
            if (sql_data.song_details[engine_id] == null || sql_data.song_details[engine_id][level_id] == null)
                return null;

            return (sql_data.song_details[engine_id][level_id] as UserSongData);
        }

        /**
         * Safe version of the getSongDetails that only returns a SQLSongDetails.
         * This also creates the entries in the song details and engine objects.
         * @param engine_id
         * @param level_id
         * @return
         */
        public static function getSongDetailsSafe(engine_id:String, level_id:String):UserSongData
        {
            if (sql_data.song_details[engine_id] == null)
                sql_data.song_details[engine_id] = {};

            if (sql_data.song_details[engine_id][level_id] == null)
                sql_data.song_details[engine_id][level_id] = new UserSongData(engine_id, level_id, null);

            return (sql_data.song_details[engine_id][level_id] as UserSongData);
        }

        /**
         * Writes the Song Details DB into a JSON file.
         * @param db_file
         */
        public static function writeFile(db_file:File):void
        {
            var my_data:Object = sql_data;
            AirContext.writeTextFile(db_file, JSON.stringify(sql_data, null, 2));
        }
    }
}
