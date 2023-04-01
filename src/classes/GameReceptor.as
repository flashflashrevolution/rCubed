package classes
{
    import com.greensock.TweenLite;
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.geom.Matrix;

    public dynamic class GameReceptor extends MovieClip
    {
        private static var DRAW_MATRIX:Matrix = new Matrix();
        private var _note:MovieClip;
        public var DIR:String;

        public var animationSpeed:Number = 1;

        public function GameReceptor(dir:String)
        {
            this.DIR = dir;
        }

        public function attachMovieclip(mc:MovieClip):GameReceptor
        {
            _note = mc;
            this.addChild(_note);
            return this;
        }

        public function attachBitmap(bitmap:BitmapData):GameReceptor
        {
            DRAW_MATRIX.tx = -(bitmap.width >> 1);
            DRAW_MATRIX.ty = -(bitmap.height >> 1);

            _note = new MovieClip();
            _note.graphics.beginBitmapFill(bitmap, DRAW_MATRIX, false);
            _note.graphics.drawRect(-(bitmap.width >> 1), -(bitmap.height >> 1), bitmap.width, bitmap.height);
            _note.graphics.endFill();
            _note.cacheAsBitmap = true;

            this.addChild(_note);

            return this;
        }

        public function playAnimation(color:uint):void
        {
            _note.scaleX = _note.scaleY = 1;
            TweenLite.to(_note, (0.1 / animationSpeed), {scaleX: 1.15, scaleY: 1.15, tint: color, useFrames: false, onComplete: function():void
            {
                TweenLite.to(_note, (0.066 / animationSpeed), {scaleX: 1, scaleY: 1, tint: null, useFrames: false});
            }});
        }

        public function dispose():void
        {
            if (_note != null && this.contains(_note))
            {
                this.removeChild(_note);
            }

            _note = null;
        }

    }

}
