package com.flashfla.media
{
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    public class SwfParser
    {
        public static const SWF_TAG_END:int = 0;
        public static const SWF_TAG_SHOWFRAME:int = 1;
        public static const SWF_TAG_DOACTION:int = 12;
        public static const SWF_TAG_DEFINESOUND:int = 14;
        public static const SWF_TAG_STREAMHEAD:int = 18;
        public static const SWF_TAG_STREAMBLOCK:int = 19;
        public static const SWF_TAG_STREAMHEAD2:int = 45;
        public static const SWF_TAG_FILEATTRIBUTES:int = 69;

        public static const SWF_ACTION_END:int = 0x00;
        public static const SWF_ACTION_CONSTANTPOOL:int = 0x88;
        public static const SWF_ACTION_PUSH:int = 0x96;
        public static const SWF_ACTION_POP:int = 0x17;
        public static const SWF_ACTION_DUPLICATE:int = 0x4C;
        public static const SWF_ACTION_STORE_REGISTER:int = 0x87;
        public static const SWF_ACTION_GET_VARIABLE:int = 0x1C;
        public static const SWF_ACTION_SET_VARIABLE:int = 0x1D;
        public static const SWF_ACTION_INIT_ARRAY:int = 0x42;
        public static const SWF_ACTION_GET_MEMBER:int = 0x4E;
        public static const SWF_ACTION_SET_MEMBER:int = 0x4F;

        public static const SWF_TYPE_STRING_LITERAL:int = 0;
        public static const SWF_TYPE_FLOAT_LITERAL:int = 1;
        public static const SWF_TYPE_NULL:int = 2;
        public static const SWF_TYPE_UNDEFINED:int = 3;
        public static const SWF_TYPE_REGISTER:int = 4;
        public static const SWF_TYPE_BOOLEAN:int = 5;
        public static const SWF_TYPE_DOUBLE:int = 6;
        public static const SWF_TYPE_INTEGER:int = 7;
        public static const SWF_TYPE_CONSTANT8:int = 8;
        public static const SWF_TYPE_CONSTANT16:int = 9;

        public static const SWF_CODEC_MP3:int = 2;

        public static function readHeader(data:ByteArray):Object
        {
            if (data.length == 0)
                return null;
            data.endian = Endian.LITTLE_ENDIAN;
            if (isCompressed(data))
                uncompress(data);

            var ret:Object = new Object();

            data.position = 3;
            ret.version = data.readUnsignedByte();
            ret.size = data.readInt();

            // SWF Rectangle
            data.position += (4 * (data.readUnsignedByte() >>> 3) - 3 + 7) / 8 + 1;

            ret.frameRate = data.readUnsignedShort();
            ret.frameCount = data.readUnsignedShort();

            return ret;
        }

        public static function readTag(data:ByteArray):Object
        {
            var ret:Object = new Object();
            var tag:int = data.readUnsignedShort();
            var len:uint = tag & 0x3f;
            ret.tag = (tag >>> 6);
            ret.length = (len == 0x3f ? data.readUnsignedInt() : len);
            ret.position = data.position;
            return ret;
        }

        public static function writeTag(data:ByteArray, tag:uint, length:uint = 0):void
        {
            data.writeShort(((tag << 6) & 0xffc0) | (length < 0x3f ? length : 0x3f));
            if (length >= 0x3f)
                data.writeUnsignedInt(length);
        }

        public static function readAction(data:ByteArray):Object
        {
            var ret:Object = new Object();
            ret.action = data.readUnsignedByte();
            ret.length = (ret.action & 0x80) ? data.readUnsignedShort() : 0;
            ret.position = data.position;
            return ret;
        }

        public static function readString(data:ByteArray):String
        {
            var ret:String = new String();
            while (true)
            {
                var read:int = data.readUnsignedByte();
                if (!read)
                    break;
                ret += String.fromCharCode(read);
            }
            return ret;
        }

        private static function isCompressed(bytes:ByteArray):Boolean
        {
            return bytes[0] == 0x43;
        }

        private static function uncompress(bytes:ByteArray):void
        {
            var cBytes:ByteArray = new ByteArray();
            cBytes.writeBytes(bytes, 8);
            bytes.length = 8;
            bytes.position = 8;
            cBytes.uncompress();
            bytes.writeBytes(cBytes);
            bytes[0] = 0x46;
            cBytes.length = 0;
        }
    }
}
