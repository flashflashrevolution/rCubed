package classes.replay
{
    import flash.utils.ByteArray;

    public class Base64Encoder
    {
        public static const CHARSET_UTF_8:String = "UTF-8";
        public static var newLine:int = 10;
        public var insertNewLines:Boolean = false;

        private var _buffers:Array;
        private var _count:uint;
        private var _line:uint;
        private var _work:Array = [0, 0, 0];

        public static const MAX_BUFFER_SIZE:uint = 32767;

        private static const ESCAPE_CHAR_CODE:Number = 61; // The '=' char

        private static const ALPHABET_CHAR_CODES:Array = [65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77,
            78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106,
            107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52,
            53, 54, 55, 56, 57, 43, 47];

        public function Base64Encoder()
        {
            super();
            reset();
        }

        private function drain():String
        {
            var result:String = "";

            for (var i:uint = 0; i < _buffers.length; i++)
            {
                var buffer:Array = _buffers[i] as Array;
                result += String.fromCharCode.apply(null, buffer);
            }

            _buffers = [];
            _buffers.push([]);

            return result;
        }

        public function encode(data:String, offset:uint = 0, length:uint = 0):void
        {
            if (length == 0)
                length = data.length;

            var currentIndex:uint = offset;

            var endIndex:uint = offset + length;
            if (endIndex > data.length)
                endIndex = data.length;

            while (currentIndex < endIndex)
            {
                _work[_count] = data.charCodeAt(currentIndex);
                _count++;

                if (_count == _work.length || endIndex - currentIndex == 1)
                {
                    encodeBlock();
                    _count = 0;
                    _work[0] = 0;
                    _work[1] = 0;
                    _work[2] = 0;
                }
                currentIndex++;
            }
        }

        public function encodeUTFBytes(data:String):void
        {
            var bytes:ByteArray = new ByteArray();
            bytes.writeUTFBytes(data);
            bytes.position = 0;
            encodeBytes(bytes);
        }

        public function encodeBytes(data:ByteArray, offset:uint = 0, length:uint = 0):void
        {
            if (length == 0)
                length = data.length;

            var oldPosition:uint = data.position;
            data.position = offset;
            var currentIndex:uint = offset;

            var endIndex:uint = offset + length;
            if (endIndex > data.length)
                endIndex = data.length;

            while (currentIndex < endIndex)
            {
                _work[_count] = data[currentIndex];
                _count++;

                if (_count == _work.length || endIndex - currentIndex == 1)
                {
                    encodeBlock();
                    _count = 0;
                    _work[0] = 0;
                    _work[1] = 0;
                    _work[2] = 0;
                }
                currentIndex++;
            }

            data.position = oldPosition;
        }

        private function flush():String
        {
            if (_count > 0)
                encodeBlock();

            var result:String = drain();
            reset();
            return result;
        }

        public function reset():void
        {
            _buffers = [];
            _buffers.push([]);
            _count = 0;
            _line = 0;
            _work[0] = 0;
            _work[1] = 0;
            _work[2] = 0;
        }

        public function toString():String
        {
            return flush();
        }

        private function encodeBlock():void
        {
            var currentBuffer:Array = _buffers[_buffers.length - 1] as Array;
            if (currentBuffer.length >= MAX_BUFFER_SIZE)
            {
                currentBuffer = [];
                _buffers.push(currentBuffer);
            }

            currentBuffer.push(ALPHABET_CHAR_CODES[(_work[0] & 0xFF) >> 2]);
            currentBuffer.push(ALPHABET_CHAR_CODES[((_work[0] & 0x03) << 4) | ((_work[1] & 0xF0) >> 4)]);

            if (_count > 1)
                currentBuffer.push(ALPHABET_CHAR_CODES[((_work[1] & 0x0F) << 2) | ((_work[2] & 0xC0) >> 6)]);
            else
                currentBuffer.push(ESCAPE_CHAR_CODE);

            if (_count > 2)
                currentBuffer.push(ALPHABET_CHAR_CODES[_work[2] & 0x3F]);
            else
                currentBuffer.push(ESCAPE_CHAR_CODE);

            if (insertNewLines)
            {
                if ((_line += 4) == 76)
                {
                    currentBuffer.push(newLine);
                    _line = 0;
                }
            }
        }
    }

}
