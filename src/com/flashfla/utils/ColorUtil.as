package com.flashfla.utils
{

    public class ColorUtil
    {
        public static function brightenColor(hexColor:Number, percent:Number):Number
        {
            if (isNaN(percent))
                percent = 0;
            if (percent > 1)
                percent = 1;
            if (percent < 0)
                percent = 0;

            var rgb:Object = hexToRgb(hexColor);

            rgb.r += (255 - rgb.r) * percent;
            rgb.b += (255 - rgb.b) * percent;
            rgb.g += (255 - rgb.g) * percent;

            return rgbToHex(Math.round(rgb.r), Math.round(rgb.g), Math.round(rgb.b));
        }

        public static function darkenColor(hexColor:Number, percent:Number):Number
        {
            if (isNaN(percent))
                percent = 0;
            if (percent > 1)
                percent = 1;
            if (percent < 0)
                percent = 0;

            var factor:Number = 1 - percent;
            var rgb:Object = hexToRgb(hexColor);

            rgb.r *= factor;
            rgb.b *= factor;
            rgb.g *= factor;

            return rgbToHex(Math.round(rgb.r), Math.round(rgb.g), Math.round(rgb.b));
        }

        public static function rgbToHex(r:Number, g:Number, b:Number):Number
        {
            return (r << 16 | g << 8 | b);
        }

        public static function hexToRgb(hex:Number):Object
        {
            return {r: (hex & 0xff0000) >> 16, g: (hex & 0x00ff00) >> 8, b: hex & 0x0000ff};
        }

        public static function brightness(hex:Number):Number
        {
            var max:Number = 0;
            var rgb:Object = hexToRgb(hex);
            if (rgb.r > max)
                max = rgb.r;
            if (rgb.g > max)
                max = rgb.g;
            if (rgb.b > max)
                max = rgb.b;
            max /= 255;
            return max;
        }

    }

}
