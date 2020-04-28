package com.flashfla.media
{
    import flash.utils.ByteArray;
    import flash.utils.Endian;

    public class MP3Extraction
    {
        public static function extractSound(data:ByteArray, metadata:Object = null):ByteArray
        {
            var header:Object = SwfParser.readHeader(data);

            if (header == null)
                return null;

            var mp3:ByteArray = new ByteArray();
            var frame:int = 0;
            var mp3Frame:int = 0;
            var mp3Seek:int = 0;
            var mp3Samples:int = 0;
            var mp3Id:int = 0;
            var mp3Format:int = 0;
            var mp3Stream:Boolean = false;
            var done:Boolean = false;
            while (data.bytesAvailable > 0 && !done)
            {
                var tag:Object = SwfParser.readTag(data);
                switch (tag.tag)
                {
                    case SwfParser.SWF_TAG_END:
                        done = true;
                        break;
                    case SwfParser.SWF_TAG_SHOWFRAME:
                        frame++;
                        break;
                    case SwfParser.SWF_TAG_STREAMBLOCK:
                        if (!mp3Stream)
                            break;
                        if ((tag.length - 4) == 0)
                            break;
                        if (!mp3Frame)
                            mp3Frame = frame + 1;
                        mp3Samples += data.readUnsignedShort(); // frame samples
                        data.readUnsignedShort(); // seek samples
                        mp3.writeBytes(data, data.position, tag.length - 4);
                        break;
                    case SwfParser.SWF_TAG_STREAMHEAD:
                    case SwfParser.SWF_TAG_STREAMHEAD2:
                        data.readUnsignedByte();
                        mp3Format = data.readUnsignedByte();
                        data.readUnsignedShort(); // average frame samples
                        mp3Seek = data.readUnsignedShort();
                        if (((mp3Format >>> 4) & 0xf) == SwfParser.SWF_CODEC_MP3)
                            mp3Stream = true;
                        break;
                    case SwfParser.SWF_TAG_DEFINESOUND:
                        if (!mp3Stream)
                        {
                            var id:int = data.readUnsignedShort();
                            var format:int = data.readUnsignedByte();
                            if (((format >>> 4) & 0xf) == SwfParser.SWF_CODEC_MP3)
                            {
                                mp3Id = id;
                                mp3Format = format;
                                mp3Samples = data.readInt();
                                mp3Seek = data.readUnsignedShort();
                                mp3.writeBytes(data, data.position, tag.length - 9);
                                done = true;
                            }
                        }
                        break;
                    default:
                        break;
                }
                data.position = tag.position + tag.length;
            }

            if (metadata)
            {
                metadata.frame = mp3Frame - 1;
                metadata.samples = mp3Samples;
                metadata.seek = mp3Seek;
                metadata.id = mp3Id;
                metadata.format = mp3Format;
            }

            return mp3;
        }

        public static function formatRate(format:int):int
        {
            switch ((format & 0x0C) >> 2)
            {
                case 0:
                    return 5500;
                case 1:
                    return 11000;
                case 2:
                    return 22050;
                case 3:
                    return 44100;
            }
            return 0;
        }
    }
}
