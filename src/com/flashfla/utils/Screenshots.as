/**
 * @author Zageron
 */

package com.flashfla.utils
{
    import by.blooddy.crypto.image.PNGEncoder;
    import classes.Alert;
    import classes.Language;
    import flash.desktop.Clipboard;
    import flash.desktop.ClipboardFormats;
    import flash.display.BitmapData;
    import flash.net.FileReference;
    import Main;

    public class Screenshots
    {
        /**
         * Capture the bitmap of the stage.
         * @param gameMain Reference to the main sprite.
         * @return Bitmap data representation of the entire stage.
         */
        private static function captureStage(gameMain:Main):BitmapData
        {
            // Create Bitmap of Stage
            var b:BitmapData = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            b.draw(gameMain.stage);
            return b;
        }

        /**
         * Takes a screenshot of the stage and saves it to disk.
         * @param gameMain
         * @param filename
         */
        public static function takeScreenshot(gameMain:Main, filename:String = null):void
        {
            var b:BitmapData = captureStage(gameMain);

            try
            {
                var _file:FileReference = new FileReference();
                _file.save(PNGEncoder.encode(b), AirContext.createFileName((filename != null ? filename : "R^3 - " + DateUtil.toRFC822(new Date()).replace(/:/g, ".")) + ".png"));
            }
            catch (e:Error)
            {
                Alert.add(Language.instance.string("save_image_error"), 120);
            }
        }

        /**
         * Takes a screenshot of the stage and saves it to clipboard.
         * @param gameMain
         */
        public static function saveToClipboard(gameMain:Main):void
        {
            var b:BitmapData = captureStage(gameMain);
            Clipboard.generalClipboard.clear();
            Clipboard.generalClipboard.setData(ClipboardFormats.BITMAP_FORMAT, b, false);
            Alert.add(Language.instance.string("copy_image_to_clipboard"), 120, Alert.GREEN);
        }
    }
}
