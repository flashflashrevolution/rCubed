package
{
    import flash.data.SQLConnection;
    import flash.data.SQLStatement;
    import flash.events.Event;
    import flash.events.SQLErrorEvent;
    import flash.events.SQLEvent;
    import classes.chart.Song;
    import sql.SQLSongDetails;
    import flash.data.SQLResult;

    public class SQLQueries
    {

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /**
         * Refresh created statments to use a new sql connection, if previously created.
         * @param	conn new SQL connection
         */
        public static function refreshStatements(conn:SQLConnection):void
        {
            refreshStatement(conn, sqlState_getSongDetails);
            refreshStatement(conn, sqlState_saveSongDetails);
        }

        private static function refreshStatement(conn:SQLConnection, stat:SQLStatement):void
        {
            if (stat != null)
                stat.sqlConnection = conn;
        }

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        public static function getSongDetailsFromSong(conn:SQLConnection, song:Song, callback:Function = null):void
        {
            var params:Object = {"engine": (song.entry.engine != null ? song.entry.engine : Constant.BRAND_NAME_SHORT_LOWER()), "song_id": song.entry.level};
            getSongDetails(conn, params, callback);
        }

        /**
         * Gets stored song details using the following params structure:
           {
           "engine": Constant.BRAND_NAME_SHORT_LOWER(), 			// Engine ID - String [250]
           "song_id": 1,				// Song ID - String [250]
           }
         *
         * @param	conn
         * @param	params See Structure
         */
        public static function getSongDetails(conn:SQLConnection, params:Object, callback:Function = null):void
        {
            if (!conn.connected)
                return;

            if (!sqlState_getSongDetails)
            {
                sqlState_getSongDetails = new SQLStatement();
                sqlState_getSongDetails.sqlConnection = conn;
                sqlState_getSongDetails.text = "SELECT * FROM song_details WHERE `engine` = :engine AND `song_id` = :song_id;";
            }
            sqlState_getSongDetails.addEventListener(SQLEvent.RESULT, resultHandler);
            sqlState_getSongDetails.addEventListener(SQLErrorEvent.ERROR, errorHandler);

            sqlState_getSongDetails.clearParameters();

            for (var key:String in params)
                sqlState_getSongDetails.parameters[":" + key] = params[key];

            sqlState_getSongDetails.execute();

            // Statement Events
            function resultHandler(event:SQLEvent):void
            {
                sqlState_getSongDetails.removeEventListener(SQLEvent.RESULT, resultHandler);
                sqlState_getSongDetails.removeEventListener(SQLErrorEvent.ERROR, errorHandler);

                if (callback != null)
                {
                    var tmp:SQLResult = sqlState_getSongDetails.getResult();
                    var len:int = 0;
                    var results:Vector.<SQLSongDetails>;
                    if (tmp.data != null)
                    {
                        len = tmp.data.length;
                        results = new Vector.<SQLSongDetails>(true, len);
                        for (var i:int = 0; i < len; i++)
                        {
                            results[i] = new SQLSongDetails(tmp.data[i]);
                        }
                    }
                    callback(results);
                }
            }

            function errorHandler(event:SQLErrorEvent):void
            {
                sqlState_getSongDetails.removeEventListener(SQLEvent.RESULT, resultHandler);
                sqlState_getSongDetails.removeEventListener(SQLErrorEvent.ERROR, errorHandler);

                if (callback != null)
                    callback(null);
            }
        }
        private static var sqlState_getSongDetails:SQLStatement;

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        /**
         * Updates a stored song details using the following params structure:
           {
           "engine": Constant.BRAND_NAME_SHORT_LOWER(), 			// Engine ID - String [250]
           "song_id": 1,				// Song ID - String [250]
           "offset_music": 1,			// Music Offset - Number
           "offset_judge": 1,			// Judge Offset - Number
           "set_mirror_invert": 0,		// Mirror Invert - Boolean (0 / 1)
           "set_custom_offsets": 1,	// Custom Offsets - Boolean (0 / 1)
           "notes": "testing"			// Song Notes - String
           }
         *
         * @param	conn
         * @param	params See Structure
         */
        public static function saveSongDetails(conn:SQLConnection, params:Object, callback:Function = null):void
        {
            if (!conn.connected)
                return;

            if (!sqlState_saveSongDetails)
            {
                sqlState_saveSongDetails = new SQLStatement();
                sqlState_saveSongDetails.sqlConnection = conn;
                sqlState_saveSongDetails.text = "INSERT OR REPLACE INTO `song_details` " + "	(`engine`, `song_id`, `offset_music`, `offset_judge`, `set_mirror_invert`, `set_custom_offsets`, `notes`) " + "VALUES " + "	(:engine, :song_id, :offset_music, :offset_judge, :set_mirror_invert, :set_custom_offsets, :notes)";
            }
            sqlState_saveSongDetails.addEventListener(SQLEvent.RESULT, resultHandler);
            sqlState_saveSongDetails.addEventListener(SQLErrorEvent.ERROR, resultHandler);

            sqlState_saveSongDetails.clearParameters();

            for (var key:String in params)
                sqlState_saveSongDetails.parameters[":" + key] = params[key];

            sqlState_saveSongDetails.execute();

            // Statement Events
            function resultHandler(event:Event):void
            {
                sqlState_saveSongDetails.removeEventListener(SQLEvent.RESULT, resultHandler);
                sqlState_saveSongDetails.removeEventListener(SQLErrorEvent.ERROR, resultHandler);

                if (callback != null)
                    callback(event);
            }
        }
        private static var sqlState_saveSongDetails:SQLStatement;

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
}
