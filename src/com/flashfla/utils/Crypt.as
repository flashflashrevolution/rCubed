/**
 * R^2 Encryption Library
 * @author Jonathan (Velocity)
 */

package com.flashfla.utils
{

    public class Crypt
    {
        public static var B64Chars:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

        /**
         * Preforms a Crypt Encode
         */
        public static function Encode(src:String):String
        {
            var output:String = "";
            var gLength:Number = Math.ceil(Math.random() * 8) + 1;

            // Base64 Encode Input
            output = B64Encode(src);

            // Add the random garbage data to the end
            for (var c:uint = 0; c < gLength; c++)
            {
                output += B64Chars.charAt(Math.floor(Math.random() * 63));
            }

            // Add the total characters to the beginning, and flip/reverse the string.
            output = gLength + output;
            // output = flipString(gLength + output);

            // Add garbage chars every 4 characters
            for (var g:int = 4; g < output.length; g += 5)
            {
                output = output.substr(0, g) + B64Chars.charAt(Math.floor(Math.random() * 63)) + output.substr(g);
            }

            output = ROT255(output);
            output = B64Encode(output);
            return output;
        }

        /**
         * Decodes a Crypt Encode
         */
        public static function Decode(src:String):String
        {
            if (src.length == 0)
                return "";

            var input:String = "";
            var output:String = "";

            // Decode
            input = B64Decode(src);
            input = ROT255(input);

            // Rip out every 5th char as it's garbage.
            for (var n:int = 0; n <= (input.length + 4); n += 5)
            {
                output += input.substr(n, 4);
            }

            // Flip the string
            // output = flipString(output);

            // Rip garbage data
            output = output.substr(1, (output.length - Number(output.charAt(0)) - 1));

            // Do decoding another round of decoding
            output = B64Decode(output);

            return output;
        }

        /**
         * Encodes a base64 string.
         */
        public static function B64Encode(src:String):String
        {
            var i:Number = 0;
            var output:String = "";
            var chr1:Number, chr2:Number, chr3:Number;
            var enc1:Number, enc2:Number, enc3:Number, enc4:Number;

            // Do the normal Base64
            while (i < src.length)
            {
                chr1 = src.charCodeAt(i++);
                chr2 = src.charCodeAt(i++);
                chr3 = src.charCodeAt(i++);
                enc1 = chr1 >> 2;
                enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
                enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
                enc4 = chr3 & 63;
                if (isNaN(chr2))
                    enc3 = enc4 = 64;
                else if (isNaN(chr3))
                    enc4 = 64;
                output += B64Chars.charAt(enc1) + B64Chars.charAt(enc2) + B64Chars.charAt(enc3) + B64Chars.charAt(enc4);
            }
            return output;
        }

        /**
         * Decodes a base64 string.
         */
        public static function B64Decode(src:String):String
        {
            var i:Number = 0;
            var output:String = "";
            var chr1:Number, chr2:Number, chr3:Number;
            var enc1:Number, enc2:Number, enc3:Number, enc4:Number;
            while (i < src.length)
            {
                enc1 = B64Chars.indexOf(src.charAt(i++));
                enc2 = B64Chars.indexOf(src.charAt(i++));
                enc3 = B64Chars.indexOf(src.charAt(i++));
                enc4 = B64Chars.indexOf(src.charAt(i++));
                chr1 = (enc1 << 2) | (enc2 >> 4);
                chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
                chr3 = ((enc3 & 3) << 6) | enc4;
                output += String.fromCharCode(chr1);
                if (enc3 != 64)
                    output = output + String.fromCharCode(chr2);
                if (enc4 != 64)
                    output = output + String.fromCharCode(chr3);
            }
            return output;
        }

        /**
         * Preforms a ROT255.
         */
        public static function ROT255(src:String):String
        {
            const mL:int = src.length;
            var arr:Array = new Array(mL);

            // 255 XOR Wrap
            for (var i:uint = 0; i < mL; ++i)
            {
                arr[i] = src.charCodeAt(i) ^ ((mL + i * 4) % 255);
            }

            return String.fromCharCode.apply(null, arr);
        }

        /**
         * Converts the input to a charCode array.
         */
        public static function toCharCode(s:String):String
        {
            var output:String = "";
            for (var c:int = 0; c < s.length; c++)
            {
                output += s.charCodeAt(c) + ",";
            }
            output = output.substr(0, output.length - 1);
            return "String.fromCharCode(" + output + ")";
        }

        public static function urlencode(s:String):String
        {
            s = s.replace(/=/g, "%3D");
            s = s.replace(/\//g, "%2F");
            s = s.replace(/\+/g, "%2B");
            return s;
        }

        /**
         * Reverses the input string.
         */
        private static function flipString(s:String):String
        {
            return s.split("").reverse().join("");
        }
    }
}
