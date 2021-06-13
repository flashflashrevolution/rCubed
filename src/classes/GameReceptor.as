package classes
{
    import com.greensock.TweenLite;
    import flash.display.BitmapData;
    import flash.display.MovieClip;

    public dynamic class GameReceptor extends MovieClip
    {
        private var _note:MovieClip;
        public var DIR:String;

        public var animationSpeed:Number = 1;

        public function GameReceptor(dir:String, bitmap:BitmapData)
        {
            this.DIR = dir;

            _note = new MovieClip();
            _note.graphics.beginBitmapFill(bitmap, null, false);
            _note.graphics.drawRect(0, 0, bitmap.width, bitmap.height);
            _note.graphics.endFill();
            _note.cacheAsBitmap = true;

            _note.x = -(bitmap.width >> 1);
            _note.y = -(bitmap.height >> 1);
            this.addChild(_note);
        }

        public function playAnimation(color:uint):void
        {
            _note.scaleX = _note.scaleY = 1;
            update();
            TweenLite.to(_note, (0.1 / animationSpeed), {scaleX: 1.25, scaleY: 1.25, tint: color, useFrames: false, onUpdate: update, onComplete: function():void
            {
                TweenLite.to(_note, (0.066 / animationSpeed), {scaleX: 1, scaleY: 1, tint: null, useFrames: false, onUpdate: update});
            }});
        }

        private function update():void
        {
            _note.x = -(_note.width >> 1);
            _note.y = -(_note.height >> 1);
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
