package game.controls
{
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.display.GradientType;

    public class FlashlightOverlay extends Sprite
    {
        private static var _matrix:Matrix = new Matrix();
        {
            _matrix.createGradientBox(Main.GAME_WIDTH, Main.GAME_HEIGHT, 1.5707963267948966);
        }

        public function FlashlightOverlay():void
        {
            this.graphics.beginGradientFill(GradientType.LINEAR, [0, 0, 0, 0, 0, 0], [0.95, 0.55, 0, 0, 0.55, 0.95], [0x00, 0x52, 0x6C, 0x92, 0xAC, 0xFF], _matrix);
            this.graphics.drawRect(0, -Main.GAME_HEIGHT, Main.GAME_WIDTH, Main.GAME_HEIGHT * 3);
            this.graphics.endFill();
        }
    }
}
