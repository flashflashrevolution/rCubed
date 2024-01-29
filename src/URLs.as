package
{

    public class URLs
    {
        public static var ROOT_URL:String = R3::ROOT_URL;

        public static var HTTP_PROTOCOL:String;
        public static var BASE_PATH:String;

        // Static Init
        {
            protocol = "https";
        }

        /**
         * URL builder for base url and appended path.
         * @param path
         * @return Full URL
         */
        public static function resolve(path:String = ""):String
        {
            return BASE_PATH + path;
        }

        /**
         * Set the protocol used for url building. Only `http` and `https` are valid.
         * @param val Protocol
         */
        public static function set protocol(val:String):void
        {
            // Only http/https are valid.
            if (val != "http" && val != "https")
                val = "https";

            // Set
            HTTP_PROTOCOL = val;
            BASE_PATH = HTTP_PROTOCOL + "://" + ROOT_URL + "/";
        }

        // Site URLs
        public static var SITE_DATA_URL:String = "game/r3/r3-siteData.v2.php";
        public static var SITE_PLAYLIST_URL:String = "game/r3/r3-playlist.php";
        public static var SITE_LANGUAGE_URL:String = "game/r3/r3-language.php";
        public static var SITE_HISCORES_URL:String = "game/r3/r3-hiscores.php";
        public static var SITE_REPLAYS_URL:String = "game/r3/r3-replays.php";
        public static var LEVEL_STATS_URL:String = "levelstats.php?level=";
        public static var DEBUG_LOG_URL:String = "game/r3/r3-debugLog.php";

        // Song & Gameplay URLs
        public static var SONG_DATA_URL:String = "game/r3/r3-songLoad.php";
        public static var SONG_START_URL:String = "game/r3/r3-songStart.php";
        public static var SONG_SAVE_URL:String = "game/r3/r3-songSave.php";
        public static var SONG_RATING_URL:String = "game/r3/r3-songRating.php";
        public static var SONG_PURCHASE_URL:String = "game/r3/r3-songPurchase.php";
        public static var ALT_SONG_SAVE_URL:String = "game/r3/r3-songSaveOther.php";
        public static var MULTIPLAYER_SUBMIT_URL:String = "game/ffr-legacy_multiplayer.php";

        // User URLs
        public static var USER_REGISTER_URL:String = "vbz/register.php";
        public static var USER_LOGIN_URL:String = "game/r3/r3-siteLogin.php";
        public static var USER_INFO_URL:String = "game/r3/r3-userInfo.php";
        public static var USER_INFO_LITE_URL:String = "game/r3/r3-userSmallInfo.php";
        public static var USER_AVATAR_URL:String = "avatar_imgembedded.php";
        public static var USER_RANKS_URL:String = "game/r3/r3-userRanks.v2.php";
        public static var USER_RANKS_UPDATE_URL:String = "game/r3/r3-userRankUpdate.php";
        public static var USER_FRIENDS_URL:String = "game/r3/r3-userFriends.php";
        public static var USER_SAVE_REPLAY_URL:String = "game/r3/r3-userReplay.php";
        public static var USER_LOAD_REPLAY_URL:String = "game/r3/r3-siteReplay.php";
        public static var USER_SAVE_SETTINGS_URL:String = "game/r3/r3-userSettings.php";
        public static var USER_STATS_URL:String = "game/r3/r3-userStats.php";

        // Multiplayer
        public static var MP_HOST:String = "www.flashflashrevolution.com";
        public static var MP_PORT:int = 8084;

        // Unused URLs
        public static var SHOP_URL:String = "tools/ffrshop.php";
        public static var NOTESKIN_SWF_URL:String = "game/r3/noteskins/";
        public static var NOTESKIN_URL:String = "game/r3/r3-noteSkins.xml";
    }
}
