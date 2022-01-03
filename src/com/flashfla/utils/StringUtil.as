/**
 * @author Jonathan (Velocity)
 */

package com.flashfla.utils
{
    import flash.xml.XMLDocument;
    import flash.xml.XMLNode;
    import flash.xml.XMLNodeType;

    public class StringUtil
    {
        public static const KEY_ARRAY:Array = ["", "", "", "", "", "", "", "",
            "Backspace", "Tab", "", "", "Clear", "Enter", "", "", "Shift", "Ctrl", "Alt", "Pause", "Capslock",
            "", "", "", "", "", "", "Esc", "", "", "", "", "Space", "PgUp", "PgDown", "End", "Home",
            "Left", "Up", "Right", "Down", "", "", "", "", "Insert", "Delete", "",
            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "", "", "", "", "", "", "",
            "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
            "Win L", "Win R", "Context", "", "",
            "Num 0", "Num 1", "Num 2", "Num 3", "Num 4", "Num 5", "Num 6", "Num 7", "Num 8", "Num 9",
            "*", "+", "", "-", ".", "/",
            "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
            "F13", "F14", "F15", "F16", "F17", "F18", "F19", "F20", "F21", "F22", "F23", "F24",
            "", "", "", "", "", "", "", "", "Num Lock", "Sc Lk", "", "", "", "", "", "", "", "", "", "",
            "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
            "", "", "", "", "", "", "", ";", "=", ",", "-", ".", "/", "`", "", "", "", "", "", "", "", "",
            "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "[", "\\", "]", "'"];

        public static const STR_PAD_LEFT:String = "LeftPad";
        public static const STR_PAD_RIGHT:String = "RightPad";

        public static function fromCharArray(hexArray:Array):String
        {
            var output:String = "";
            for each (var char:uint in hexArray)
            {
                output += String.fromCharCode(char);
            }
            return output;
        }

        public static function toHex(input:String):String
        {
            var out:String = "";
            for (var c:uint = 0; c < input.length; c++)
            {
                out += "0x" + pad(Number(input.charCodeAt(c)).toString(16).toUpperCase(), 2, "0", STR_PAD_LEFT) + ",";
            }
            return out.substr(0, out.length - 1);
        }

        public static function pad(input:String, pad_length:uint, pad_string:String = " ", pad_type:String = null):String
        {
            var ret:String = input;

            if (pad_type == null)
                pad_type = STR_PAD_LEFT;

            if (pad_string == "")
                return input;

            if (pad_type == STR_PAD_LEFT)
                while (ret.length < pad_length)
                    ret = pad_string + ret;

            else if (pad_type == STR_PAD_RIGHT)
                while (ret.length < pad_length)
                    ret += pad_string;

            return ret;
        }

        public static function upperCase(str:String):String
        {
            return str.substr(0, 1).toUpperCase() + str.substr(1, str.length);
        }

        public static function keyCodeChar(input:uint):String
        {
            return KEY_ARRAY[input] || ("[" + input.toString() + "]");
        }

        public static function getURLPieces(urlStr:String):Array
        {
            return splitMultiple(urlStr.replace(/http(s|):\/\//, "").toLowerCase(), ["/", ".", "?", "&", "="]);
        }

        public static function splitMultiple(str:String, delimiters:Array):Array
        {
            if (delimiters.length > 1)
            {
                for (var i:int = 1; i < delimiters.length; i++)
                {
                    str = str.split(delimiters[i]).join(delimiters[0]);
                }
            }
            return str.split(delimiters[0]);
        }

        public static function htmlEscape(str:String):String
        {
            return XML(new XMLNode(XMLNodeType.TEXT_NODE, str)).toXMLString();
        }

        public static function htmlUnescape(str:String):String
        {
            try
            {
                return new XMLDocument(str).firstChild.nodeValue;
            }
            catch (error:Error)
            {
            }
            return str;
        }

        public static function stripMessage(str:String):String
        {
            if (str == null)
                return "";
            while (str.length && str.charAt(str.length - 1) == '\n')
                str = str.substr(0, str.length - 1);
            while (str.length && str.charAt(0) == '\n')
                str = str.substr(1);
            return str;
        }
    }
}
