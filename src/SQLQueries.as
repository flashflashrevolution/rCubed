package
{
    import flash.data.SQLConnection;
    import flash.data.SQLStatement;
    import flash.events.Event;
    import flash.events.SQLErrorEvent;
    import flash.events.SQLEvent;
    import sql.SQLSongDetails;
    import flash.data.SQLResult;
    import flash.filesystem.File;
    import com.flashfla.utils.ObjectUtil;

    public class SQLQueries
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
                            parsed_data.song_details[engine_id][level_id] = new SQLSongDetails(engine_id, level_id, engine[level_id]);
                    }
                }
            }

            sql_data = parsed_data;
        }

        public static function getSongDetailsEntry(entry:Object):SQLSongDetails
        {
            if (entry.engine != null)
                return getSongDetails(entry.engine.id, entry.level);

            return getSongDetails(Constant.BRAND_NAME_SHORT_LOWER, entry.level);
        }

        /**
         * Returns the Song Details for the given song and engine, or null if missing.
         * @param engine_id
         * @param level_id
         * @return
         */
        public static function getSongDetails(engine_id:String, level_id:String):SQLSongDetails
        {
            if (sql_data.song_details[engine_id] == null || sql_data.song_details[engine_id][level_id] == null)
                return null;

            return (sql_data.song_details[engine_id][level_id] as SQLSongDetails);
        }

        /**
         * Safe version of the getSongDetails that only returns a SQLSongDetails.
         * This also creates the entries in the song details and engine objects.
         * @param engine_id
         * @param level_id
         * @return
         */
        public static function getSongDetailsSafe(engine_id:String, level_id:String):SQLSongDetails
        {
            if (sql_data.song_details[engine_id] == null)
                sql_data.song_details[engine_id] = {};

            if (sql_data.song_details[engine_id][level_id] == null)
                sql_data.song_details[engine_id][level_id] = new SQLSongDetails(engine_id, level_id, null);

            return (sql_data.song_details[engine_id][level_id] as SQLSongDetails);
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

        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        /**
         * Helper function to convert the SQL style Song Details into the new JSON style.
         * This will be removed in 1.4.0
         * @param db_file SQLite DB File
         * @param callback
         */
        public static function exportToJSON(db_file:File, callback:Function):void
        {
            var out:Object = getTemplate();

            // Create Connection
            var sql_conn:SQLConnection = new SQLConnection();
            sql_conn.addEventListener(SQLEvent.OPEN, sql_openHandler);
            sql_conn.addEventListener(SQLErrorEvent.ERROR, sql_openErrorHandler);

            sql_conn.openAsync(db_file);

            function sql_openHandler(event:SQLEvent):void
            {
                sql_conn.removeEventListener(SQLEvent.OPEN, sql_openHandler);
                sql_conn.removeEventListener(SQLErrorEvent.ERROR, sql_openErrorHandler);

                trace("Database was connected successfully");

                doQuery(sql_conn);
            }

            function sql_openErrorHandler(event:SQLErrorEvent):void
            {
                sql_conn.removeEventListener(SQLEvent.OPEN, sql_openHandler);
                sql_conn.removeEventListener(SQLErrorEvent.ERROR, sql_openErrorHandler);
                trace("Database failed to connect!");
                trace("Error message:", event.error.message);
                trace("Details:", event.error.details);
            }

            // Export db_info:
            function doQuery(conn:SQLConnection):void
            {
                var state:SQLStatement = new SQLStatement();
                state.sqlConnection = conn;
                state.text = "SELECT * FROM 'song_details'";
                state.addEventListener(SQLEvent.RESULT, resultHandler);
                state.addEventListener(SQLErrorEvent.ERROR, resultHandler);
                state.execute();
            }

            function resultHandler(event:Event):void
            {
                var state:SQLStatement = (event.target as SQLStatement);
                state.removeEventListener(SQLEvent.RESULT, resultHandler);
                state.removeEventListener(SQLErrorEvent.ERROR, resultHandler);

                if (event.type == SQLEvent.RESULT)
                {
                    var results:SQLResult = state.getResult();
                    if (results.data != null && results.data.length > 0)
                    {
                        var res_data:Array = results.data;
                        var res_count:int = res_data.length;

                        // Dump Data
                        for (var index:int = 0; index < res_count; index++)
                        {
                            var row:Object = res_data[index];
                            var eid:* = row["engine"];
                            var sid:String = row["song_id"];
                            if (row["engine"] != Constant.BRAND_NAME_SHORT_LOWER)
                            {
                                eid = row["engine"]["id"];
                            }

                            delete row["song_id"];
                            delete row["engine"];

                            if (out["song_details"][eid] == null)
                                out["song_details"][eid] = {};

                            out["song_details"][eid][sid] = row;
                        }
                    }
                }
                else
                {
                    trace("Error dumping song details table");
                }

                sql_conn.close();
                if (callback != null)
                    callback(out);
            }
        }
    }
}
