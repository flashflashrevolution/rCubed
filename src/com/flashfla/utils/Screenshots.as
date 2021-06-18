/**
 * @author Zageron
 */

package com.flashfla.utils
{
    import classes.Language;
    import flash.display.BitmapData;
    import flash.net.FileReference;
    import by.blooddy.crypto.image.PNGEncoder;
    import classes.Alert;
    import Main;

    public class Screenshots
    {
        //- ScreenShot Handling
        /**
         * Takes a screenshot of the stage and saves it to disk.
         */
        public static function takeScreenshot(gameMain:Main, filename:String = null):void
        {
            // Create Bitmap of Stage
            var b:BitmapData = new BitmapData(Main.GAME_WIDTH, Main.GAME_HEIGHT, false, 0x000000);
            b.draw(gameMain.stage);

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
    }
}
