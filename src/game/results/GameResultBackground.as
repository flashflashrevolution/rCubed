package game.results
{
    import assets.GameBackgroundStripes;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.display.GradientType;

    public class GameResultBackground extends Sprite
    {
        static public var BG_LIGHT:int = 0x1495BD;
        static public var BG_DARK:int = 0x033242;

        public function GameResultBackground():void
        {
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
    }
}
