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
        public static const AIR_WINDOW_TITLE:String = R3::BRAND_NAME_SHORT + " R^3 [" + R3::VERSION_PREFIX + AIR_VERSION + R3::VERSION_SUFFIX + "]";
        public static const LOCAL_SO_NAME:String = "90579262-509d-4370-9c2e-564667e511d7";
        public static const ENGINE_VERSION:int = 3;

        // File Constants
        public static var MENU_MUSIC_PATH:String = "menu_music.swf";
        public static var MENU_MUSIC_MP3_PATH:String = "menu_music.mp3"
        public static var NOTESKIN_PATH:String = "noteskins/";
        public static var REPLAY_PATH:String = "replays/";
        public static var SONG_CACHE_PATH:String = "song_cache/";

        // Embed Fonts
        AachenLight;
        BreeSerif;
        Ultra;
        BebasNeue;
        Xolonium.Bold;
        Xolonium.Regular;
        HussarBold.Italic;
        HussarBold.Regular;
        NotoSans.CJKBold;
        NotoSans.Bold;

        public static const TEXT_FORMAT:TextFormat = new TextFormat(Fonts.BASE_FONT, 14, 0xFFFFFF, true);
        public static const TEXT_FORMAT_12:TextFormat = new TextFormat(Fonts.BASE_FONT, 12, 0xFFFFFF, true);
        public static const TEXT_FORMAT_CENTER:TextFormat = new TextFormat(Fonts.BASE_FONT, 14, 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        public static const TEXT_FORMAT_UNICODE:TextFormat = new TextFormat(Fonts.BASE_FONT_CJK, 14, 0xFFFFFF, true);

        // Other
        public static const NOTESKIN_EDITOR_URL:String = "https://www.flashflashrevolution.com/~velocity/ffrjs/noteskin/";
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
