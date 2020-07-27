package game.controls
{

    import flash.display.Sprite;

    public class LifeBar extends Sprite
    {
        // 3 Color Gradient, 100 Steps: [#FF0700 -> #F77600 -> #00E900]
        private static const HP_BAR_COLOR:Vector.<uint> = new <uint>[0xFF0700, 0xFF0700, 0xFE0900, 0xFE0B00, 0xFE0D00, 0xFE1000, 0xFE1200, 0xFE1400, 0xFD1600, 0xFD1900, 0xFD1B00,
            0xFD1D00, 0xFD1F00, 0xFD2200, 0xFC2400, 0xFC2600, 0xFC2800, 0xFC2B00, 0xFC2D00, 0xFC2F00, 0xFB3200,
            0xFB3400, 0xFB3600, 0xFB3800, 0xFB3B00, 0xFB3D00, 0xFA3F00, 0xFA4100, 0xFA4400, 0xFA4600, 0xFA4800,
            0xFA4A00, 0xF94D00, 0xF94F00, 0xF95100, 0xF95400, 0xF95600, 0xF95800, 0xF85A00, 0xF85D00, 0xF85F00,
            0xF86100, 0xF86300, 0xF86600, 0xF76800, 0xF76A00, 0xF76C00, 0xF76F00, 0xF77100, 0xF77300, 0xF77600,
            0xF67800, 0xF17800, 0xEC7A00, 0xE77D00, 0xE27F00, 0xDD8100, 0xD88400, 0xD38600, 0xCE8800, 0xC98B00,
            0xC48D00, 0xBF8F00, 0xBA9200, 0xB59400, 0xB09600, 0xAB9900, 0xA69B00, 0xA19D00, 0x9CA000, 0x97A200,
            0x92A400, 0x8DA700, 0x88A900, 0x83AB00, 0x7EAE00, 0x78B000, 0x73B300, 0x6EB500, 0x69B700, 0x64BA00,
            0x5FBC00, 0x5ABE00, 0x55C100, 0x50C300, 0x4BC500, 0x46C800, 0x41CA00, 0x3CCC00, 0x37CF00, 0x32D100,
            0x2DD300, 0x28D600, 0x23D800, 0x1EDA00, 0x19DD00, 0x14DF00, 0x0FE100, 0x0AE400, 0x05E600, 0x00E900];

        // Display
        private var _width:Number = 22;
        private var _height:Number = 337;

        // Variables
        private var _health:int = 50;

        public function LifeBar():void
        {
            this.mouseChildren = false;
        }

        public function draw():void
        {
            this.graphics.clear();

            const percent:Number = _health / 100;

            // Draw Health
            this.graphics.lineStyle(0, 0, 0);
            this.graphics.beginFill(HP_BAR_COLOR[_health], 1);
            this.graphics.drawRect(0, _height * (1 - percent), width - 1, (height - 1) * percent);
            this.graphics.endFill();

            // Draw Border
            this.graphics.lineStyle(4, 0xFFFFFF, 1);
            this.graphics.beginFill(0, 0)
            this.graphics.drawRect(0, 0, width - 1, height - 1);
            this.graphics.endFill();

        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        public function set health(val:int):void
        {
            _health = val;
            if (_health < 0)
                _health = 0;
            if (_health > 100)
                _health = 100;

            draw();
        }

        override public function get width():Number
        {
            return _width;
        }

        override public function get height():Number
        {
            return _height;
        }
    }
}
