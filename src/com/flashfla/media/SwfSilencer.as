package com.flashfla.media
{
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    public class SwfSilencer
    {
        public static function stripSound(data:ByteArray, metadata:Object = null):ByteArray
        {
            var odata:ByteArray = new ByteArray();
            odata.endian = Endian.LITTLE_ENDIAN;

            var header:Object = SwfParser.readHeader(data);
            odata.writeBytes(data, 0, data.position);

            if (header.version < 9)
                odata[3] = 9;

            var firstTag:Boolean = true;
            var done:Boolean = false;
            while (data.bytesAvailable > 0 && !done)
            {
                var tag:Object = SwfParser.readTag(data);
                switch (tag.tag)
                {
                    case SwfParser.SWF_TAG_STREAMBLOCK:
                    case SwfParser.SWF_TAG_STREAMHEAD:
                    case SwfParser.SWF_TAG_STREAMHEAD2:
                    case SwfParser.SWF_TAG_DEFINESOUND:
                        break;
                    case SwfParser.SWF_TAG_END:
                        done = true;
                        break;
                    case SwfParser.SWF_TAG_FILEATTRIBUTES:
                        SwfParser.writeTag(odata, tag.tag, tag.length);
                        var position:int = odata.position;
                        odata.writeBytes(data, tag.position, tag.length);
                        odata[position] |= 0x08;
                        break;
                    default:
                        if (firstTag)
                        { // Insert a FileAttributes tag
                            SwfParser.writeTag(odata, SwfParser.SWF_TAG_FILEATTRIBUTES, 4);
                            odata.writeUnsignedInt(0x00000008);
                        }
                        SwfParser.writeTag(odata, tag.tag, tag.length);
                        if (tag.length > 0)
                            odata.writeBytes(data, tag.position, tag.length);
                        break;
                }
                data.position = tag.position + tag.length;
                firstTag = false;
            }
            SwfParser.writeTag(odata, SwfParser.SWF_TAG_END);

            if (metadata)
            {
            }

            return odata;
        }
    }
}
