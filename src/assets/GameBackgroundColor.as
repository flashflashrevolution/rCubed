package assets
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.GradientType;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.filesystem.File;
    import flash.geom.Matrix;
    import flash.net.URLRequest;

    public class GameBackgroundColor extends Sprite
    {
        static public var BG_LIGHT:int = 0x1495BD;
        static public var BG_DARK:int = 0x033242;
        static public var BG_STATIC:int = 0x0C6A88;
        static public var BG_POPUP:int = 0x074B62;
        static public var BG_STAGE:int = 0x000000;

        static public var BG_IMAGE_EXT:Array = [".png", ".jpg", ".jpeg", ".gif"];
        static public var BG_IMG_MENU:Bitmap;
        static public var BG_IMG_GAME:Bitmap;

        public function GameBackgroundColor()
        {
            super();

            this.cacheAsBitmap = true;

            redraw();
            reloadImages();
        }

        public function redraw():void
        {
            if (BG_IMG_MENU != null)
            {
                this.graphics.clear();
                return;
            }

            // Create Background
            var _matrix:Matrix = new Matrix();
            _matrix.createGradientBox(Main.GAME_WIDTH, Main.GAME_HEIGHT, 5.75);
            this.graphics.clear();
            this.graphics.beginGradientFill(GradientType.LINEAR, [BG_LIGHT, BG_DARK], [1, 1], [0x00, 0xFF], _matrix);
            this.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            this.graphics.endFill();
            this.cacheAsBitmap = true;
            this.cacheAsBitmapMatrix = _matrix;

            var bt:BitmapData = new GameBackgroundStripes();
            this.graphics.beginBitmapFill(bt, null, false);
            this.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            this.graphics.endFill();
        }

        public function updateDisplay(gameMode:Boolean = false):void
        {
            if (gameMode)
            {
                if (BG_IMG_MENU != null)
                    BG_IMG_MENU.visible = false;

                if (BG_IMG_GAME != null)
                {
                    this.visible = true;
                    BG_IMG_GAME.visible = true;
                }
                else
                    this.visible = false;
            }
            else
            {
                this.visible = true;

                if (BG_IMG_MENU != null)
                    BG_IMG_MENU.visible = true;

                if (BG_IMG_GAME != null)
                    BG_IMG_GAME.visible = false;
            }
        }

        public function reloadImages():void
        {
            var path:String;
            var imageLoader:Loader;
            var file:File;

            // Menu Background
            for (var i:int = 0; i < BG_IMAGE_EXT.length; i++)
            {
                file = AirContext.getAppFile("bg_menu" + BG_IMAGE_EXT[i]);
                if (file.exists)
                {
                    Logger.debug(this, "Found " + file.name);
                    path = "file:///" + file.nativePath;
                    imageLoader = new Loader();
                    imageLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_bgMenuLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, e_bgMenuLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_bgMenuLoaded);
                    imageLoader.load(new URLRequest(path), AirContext.getLoaderContext());
                    break;
                }
            }

            // Gameplay Background
            for (i = 0; i < BG_IMAGE_EXT.length; i++)
            {
                file = AirContext.getAppFile("bg_game" + BG_IMAGE_EXT[i]);

                if (file.exists)
                {
                    Logger.debug(this, "Found " + file.name);
                    path = "file:///" + file.nativePath;
                    imageLoader = new Loader();
                    imageLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, e_bgGameLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, e_bgGameLoaded);
                    imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, e_bgGameLoaded);
                    imageLoader.load(new URLRequest(path), AirContext.getLoaderContext());
                    break;
                }
            }
        }

        private function e_bgMenuLoaded(e:Event):void
        {
            // Position Loaded Banner Image
            if (e.type == Event.COMPLETE && e.target != null && ((e.target as LoaderInfo).content) != null)
            {
                BG_IMG_MENU = ((e.target as LoaderInfo).content) as Bitmap;
                positionImage(BG_IMG_MENU);
                this.addChild(BG_IMG_MENU);
            }
        }

        private function e_bgGameLoaded(e:Event):void
        {
            // Position Loaded Banner Image
            if (e.type == Event.COMPLETE && e.target != null && ((e.target as LoaderInfo).content) != null)
            {
                BG_IMG_GAME = ((e.target as LoaderInfo).content) as Bitmap;
                BG_IMG_GAME.visible = false;
                positionImage(BG_IMG_GAME);
                this.addChild(BG_IMG_GAME);
            }
        }

        private function positionImage(img:Bitmap):void
        {
            img.smoothing = true;
            img.pixelSnapping = "always";
            img.z = 1;

            var imageScale:Number = Main.GAME_WIDTH / img.width;

            img.scaleX = img.scaleY = imageScale;

            if (img.height < Main.GAME_HEIGHT)
            {
                img.scaleX = img.scaleY = 1;
                imageScale = Main.GAME_HEIGHT / img.height;
                img.scaleX = img.scaleY = imageScale;
                img.x = -((img.width - Main.GAME_WIDTH) / 2);
            }
            else
                img.y = -((img.height - Main.GAME_HEIGHT) / 2);
        }
    }
}
