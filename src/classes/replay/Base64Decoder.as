package classes.replay
{
    import flash.utils.ByteArray;

    public class Base64Decoder
    {

        private var count:int = 0;
        private var data:ByteArray;
        private var filled:int = 0;
        private var work:Array = [0, 0, 0, 0];

        private static const ESCAPE_CHAR_CODE:Number = 61; // The '=' char

        private static const inverse:Array = [64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63, 52, 53, 54,
            55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64, 64, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
            19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64, 64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
            43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
            64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64];

        public function Base64Decoder()
        {
            super();
            data = new ByteArray();
        }

        public function decode(encoded:String):void
        {
            for (var i:uint = 0; i < encoded.length; ++i)
            {
                var c:Number = encoded.charCodeAt(i);

                if (c == ESCAPE_CHAR_CODE)
                    work[count++] = -1;
                else if (inverse[c] != 64)
                    work[count++] = inverse[c];
                else
                    continue;

                if (count == 4)
                {
                    count = 0;
                    data.writeByte((work[0] << 2) | ((work[1] & 0xFF) >> 4));
                    filled++;

                    if (work[2] == -1)
                        break;

                    data.writeByte((work[1] << 4) | ((work[2] & 0xFF) >> 2));
                    filled++;

                    if (work[3] == -1)
                        break;

                    data.writeByte((work[2] << 6) | work[3]);
                    filled++;
                }
            }
        }

        private function drain():ByteArray
        {
            var result:ByteArray = new ByteArray();

            var oldPosition:uint = data.position;
            data.position = 0; // technically, shouldn't need to set this, but carrying over from previous implementation
            result.writeBytes(data, 0, data.length);
            data.position = oldPosition;
            result.position = 0;

            filled = 0;
            return result;
        }

        private function flush():ByteArray
        {
            return drain();
        }

        private function reset():void
        {
            data = new ByteArray();
            count = 0;
            filled = 0;
        }

        public function toByteArray():ByteArray
        {
            var result:ByteArray = flush();
            reset();
            return result;
        }
    }

}
