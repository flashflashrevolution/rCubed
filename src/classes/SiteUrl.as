package classes
{

    /**
     * Responsible for serving the proper FFR site URLs.
     * Additionally can switch between HTTP and HTTPS.
     */
    public class SiteUrl
    {
        /**
         * Toggle class between using HTTP or HTTPS.
         * @param useTls
         */
        public static function UseTls(useTls:Boolean):void
        {
            SiteUrl.useTls = useTls;
        }

        private static const ROOT_URL:String = R3::ROOT_URL + "/";

        private static var useTls:Boolean = true;

        public static function get prefix():String
        {
            return (useTls ? "https://" : "http://") + ROOT_URL;
        }

        public static function get SITE_DATA_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-siteData.v2.php";
        }

        public static function get SITE_PLAYLIST_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-playlist.php";
        }

        public static function get SITE_LANGUAGE_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-language.php";
        }

        public static function get SITE_HISCORES_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-hiscores.php";
        }

        public static function get SITE_REPLAYS_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-replays.php";
        }

        public static function get LEVEL_STATS_URL():String
        {
            return SiteUrl.prefix + "levelstats.php?level=";
        }

        public static function get DEBUG_LOG_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-debugLog.php";
        }

        public static function get SONG_DATA_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-songLoad.php";
        }

        public static function get SONG_START_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-songStart.php";
        }

        public static function get SONG_SAVE_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-songSave.php";
        }

        public static function get SONG_RATING_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-songRating.php";
        }

        public static function get SONG_PURCHASE_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-songPurchase.php";
        }

        public static function get ALT_SONG_SAVE_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-songSaveOther.php";
        }

        public static function get MULTIPLAYER_SUBMIT_URL():String
        {
            return SiteUrl.prefix + "game/ffr-legacy_multiplayer.php";
        }

        public static function get USER_REGISTER_URL():String
        {
            return SiteUrl.prefix + "vbz/register.php";
        }

        public static function get USER_LOGIN_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-siteLogin.php";
        }

        public static function get USER_INFO_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-userInfo.php";
        }

        public static function get USER_INFO_LITE_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-userSmallInfo.php";
        }

        public static function get USER_AVATAR_URL():String
        {
            return SiteUrl.prefix + "avatar_imgembedded.php";
        }

        public static function get USER_RANKS_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-userRanks.v2.php";
        }

        public static function get USER_RANKS_UPDATE_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-userRankUpdate.php";
        }

        public static function get USER_FRIENDS_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-userFriends.php";
        }

        public static function get USER_SAVE_REPLAY_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-userReplay.php";
        }

        public static function get USER_LOAD_REPLAY_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-siteReplay.php";
        }

        public static function get USER_SAVE_SETTINGS_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-userSettings.php";
        }

        public static function get SHOP_URL():String
        {
            return SiteUrl.prefix + "tools/ffrshop.php";
        }

        public static function get NOTESKIN_SWF_URL():String
        {
            return SiteUrl.prefix + "game/r3/noteskins/";
        }

        public static function get NOTESKIN_URL():String
        {
            return SiteUrl.prefix + "game/r3/r3-noteSkins.xml";
        }

        public static function get NOTESKIN_EDITOR_URL():String
        {
            return SiteUrl.prefix + "~velocity/ffrjs/noteskin";
        }
    }
}
