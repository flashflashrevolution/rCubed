package
{
    import classes.Language;
    import flash.geom.Matrix;
    import flash.net.URLVariables;
    import flash.text.StyleSheet;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    public class Constant
    {
        // Engine Brand Name
        public static const BRAND_NAME_LONG:String = R3::BRAND_NAME_LONG;
        public static const BRAND_NAME_SHORT:String = R3::BRAND_NAME_SHORT;
        public static var BRAND_NAME_LONG_UPPER:String = BRAND_NAME_LONG.toLocaleUpperCase();
        public static var BRAND_NAME_LONG_LOWER:String = BRAND_NAME_LONG.toLocaleLowerCase();
        public static var BRAND_NAME_SHORT_UPPER:String = BRAND_NAME_SHORT.toLocaleUpperCase();
        public static var BRAND_NAME_SHORT_LOWER:String = BRAND_NAME_SHORT.toLocaleLowerCase();

        public static const AIR_VERSION:String = R3::VERSION;
        public static const AIR_WINDOW_TITLE:String = R3::BRAND_NAME_SHORT + " R^3 [" + AIR_VERSION + "]";
        public static const LOCAL_SO_NAME:String = "90579262-509d-4370-9c2e-564667e511d7";
        public static const ENGINE_VERSION:int = 3;

        public static const ROOT_URL:String = "http://" + R3::ROOT_URL + "/";

        // Site URLs
        public static const SITE_DATA_URL:String = ROOT_URL + "game/r3/r3-siteData.v2.php";
        public static const SITE_PLAYLIST_URL:String = ROOT_URL + "game/r3/r3-playlist.php";
        public static const SITE_LANGUAGE_URL:String = ROOT_URL + "game/r3/r3-language.php";
        public static const SITE_HISCORES_URL:String = ROOT_URL + "game/r3/r3-hiscores.php";
        public static const LEVEL_STATS_URL:String = ROOT_URL + "levelstats.php?level=";
        public static const DEBUG_LOG_URL:String = ROOT_URL + "game/r3/r3-debugLog.php";

        // Song & Gameplay URLs
        public static const SONG_DATA_URL:String = ROOT_URL + "game/r3/r3-songLoad.php";
        public static const SONG_START_URL:String = ROOT_URL + "game/r3/r3-songStart.php";
        public static const SONG_SAVE_URL:String = ROOT_URL + "game/r3/r3-songSave.php";
        public static const SONG_RATING_URL:String = ROOT_URL + "game/r3/r3-songRating.php";
        public static const SONG_PURCHASE_URL:String = ROOT_URL + "game/r3/r3-songPurchase.php";
        public static const ALT_SONG_SAVE_URL:String = ROOT_URL + "game/r3/r3-songSaveOther.php";
        public static const MULTIPLAYER_SUBMIT_URL:String = ROOT_URL + "game/ffr-legacy_multiplayer.php";
        public static const MULTIPLAYER_SUBMIT_URL_VELOCITY:String = ROOT_URL + "game/ffr-velocity_multiplayer.php";

        // User URLs
        public static const USER_REGISTER_URL:String = ROOT_URL + "vbz/register.php";
        public static const USER_LOGIN_URL:String = ROOT_URL + "game/r3/r3-siteLogin.php";
        public static const USER_INFO_URL:String = ROOT_URL + "game/r3/r3-userInfo.php";
        public static const USER_INFO_LITE_URL:String = ROOT_URL + "game/r3/r3-userSmallInfo.php";
        public static const USER_AVATAR_URL:String = ROOT_URL + "avatar_imgembedded.php";
        public static const USER_RANKS_URL:String = ROOT_URL + "game/r3/r3-userRanks.v2.php";
        public static const USER_RANKS_UPDATE_URL:String = ROOT_URL + "game/r3/r3-userRankUpdate.php";
        public static const USER_FRIENDS_URL:String = ROOT_URL + "game/r3/r3-userFriends.php";
        public static const USER_SAVE_REPLAY_URL:String = ROOT_URL + "game/r3/r3-userReplay.php";
        public static const USER_LOAD_REPLAY_URL:String = ROOT_URL + "game/r3/r3-siteReplay.php";
        public static const USER_SAVE_SETTINGS_URL:String = ROOT_URL + "game/r3/r3-userSettings.php";

        // Unused URLs
        public static const SHOP_URL:String = ROOT_URL + "tools/ffrshop.php";
        public static const NOTESKIN_SWF_URL:String = ROOT_URL + "game/r3/noteskins/";
        public static const NOTESKIN_URL:String = ROOT_URL + "game/r3/r3-noteSkins.xml";

        // File Constants
        public static const MENU_MUSIC_PATH:String = "menu_music.swf";
        public static const MENU_MUSIC_MP3_PATH:String = "menu_music.mp3"
        public static const REPLAY_PATH:String = "replays/";
        public static const SONG_CACHE_PATH:String = "song_cache/";

        // Embed Fonts
        BreeSerif;
        Ultra;
        BebasNeue;
        Xolonium.Bold;
        Xolonium.Regular;
        HussarBold.Italic;
        HussarBold.Regular;
        NotoSans.CJKBold;
        NotoSans.Bold;

        public static const TEXT_FORMAT:TextFormat = new TextFormat(Language.FONT_NAME, 14, 0xFFFFFF, true);
        public static const TEXT_FORMAT_12:TextFormat = new TextFormat(Language.FONT_NAME, 12, 0xFFFFFF, true);
        public static const TEXT_FORMAT_CENTER:TextFormat = new TextFormat(Language.FONT_NAME, 14, 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        public static const TEXT_FORMAT_UNICODE:TextFormat = new TextFormat(Language.UNI_FONT_NAME, 14, 0xFFFFFF, true);

        // Other
        public static const NOTESKIN_EDITOR_URL:String = ROOT_URL + "~velocity/ffrjs/noteskin";
        public static const WEBSOCKET_OVERLAY_URL:String = "https://github.com/flashflashrevolution/web-stream-overlay";
        public static const LEGACY_GENRE:int = 13;
        public static const JUDGE_WINDOW:Array = [{t: -118, s: 5, f: -3},
            {t: -85, s: 25, f: -2},
            {t: -51, s: 50, f: -1},
            {t: -18, s: 100, f: 0},
            {t: 17, s: 50, f: 1},
            {t: 50, s: 25, f: 2},
            {t: 84, s: 25, f: 3},
            {t: 117, s: 0}];

        // Static Initializer
        public static var GRADIENT_MATRIX:Matrix;
        public static var STYLESHEET:StyleSheet;
        {
            GRADIENT_MATRIX = new Matrix();
            GRADIENT_MATRIX.createGradientBox(100, 100, (Math.PI / 180) * 225);

            STYLESHEET = new StyleSheet();
            STYLESHEET.setStyle("A", {textDecoration: "underline", fontWeight: "bold"});
        }

        // Functions
        /**
         * Cleans the scroll direction from older engine names to the current names.
         * Only used on loaded replays to understand older scroll direction values.
         * @param dir
         * @return
         */
        public static function cleanScrollDirection(dir:String):String
        {
            dir = dir.toLowerCase();

            switch (dir)
            {
                case "slideright":
                    return "right"; // Legacy/Velocity
                case "slideleft":
                    return "left"; // Legacy/Velocity
                case "rising":
                    return "up"; // Legacy/Velocity
                case "falling":
                    return "down"; // Legacy/Velocity
                case "diagonalley":
                    return "diagonalley"; // Legacy/Velocity
            }
            return dir;
        }

        /**
         * Adds default URLVariables to the passed requestVars.
         * @param requestVars
         */
        public static function addDefaultRequestVariables(requestVars:URLVariables):void
        {
            requestVars['ver'] = Constant.ENGINE_VERSION;
            requestVars['is_air'] = true;
            requestVars['air_ver'] = Constant.AIR_VERSION;
        }
    }
}
