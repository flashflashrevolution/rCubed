package com.flashfla.parser
{
    import com.flashfla.utils.StringUtil;

    public class YAML
    {
        public static var ARRAY_TOKEN:Array = ['- ', '  '];

        /**
         * Decodes a YAML string.
         * This doesn't follow spec at all and shouldn't be used for anything except
         * Quaver chart files, as it was created to parse only those following a mostly
         * standard file without using the more advanced things found in the spec.
         * @param data YAML string
         * @return
         */
        public static function decode(data:String):Object
        {
            var out:Object = {};

            var bufflines:Array = data.split("\n");

            // Advanced File Basic
            var buckets:Array = [out];
            var bucket_keys:Array = [null];
            var bucket_depths:Array = [0];
            var bucket_depth:int = 0;
            var bucket_last_depth:int = 0;

            var line:String;
            var collection_key:String;

            var key:String;
            var val:*;
            var keyToken:String;

            var stackBucket:Object;
            var stackBucketKey:String;

            for (var l:int = 0; l < bufflines.length; l++)
            {
                line = bufflines[l];

                bucket_depth = 0;

                var splitIndex:int = line.indexOf(":");
                var startArrayItem:Boolean = false;

                key = line.substr(0, splitIndex);
                val = parseValue(StringUtil.trim(line.substr(splitIndex + 1)));
                keyToken = key.substr(0, 2);

                // Empty Line
                if (line.length == 0 || splitIndex < 0)
                    continue;

                // Bucket Depth
                if (ARRAY_TOKEN.indexOf(keyToken) >= 0)
                {
                    startArrayItem ||= (keyToken.indexOf("-") >= 0);
                    while (true)
                    {
                        key = key.substr(2);
                        keyToken = key.substr(0, 2);
                        bucket_depth++;

                        startArrayItem ||= (keyToken.indexOf("-") >= 0);

                        if (ARRAY_TOKEN.indexOf(keyToken) < 0)
                            break;
                    }
                }

                // New Array Item at the same depth.
                if (startArrayItem && bucket_depth == bucket_last_depth)
                {
                    stackBucket = buckets.pop();
                    stackBucketKey = bucket_keys.pop();
                    bucket_depths.pop();

                    if (stackBucketKey == null)
                        buckets[buckets.length - 1].push(stackBucket);
                }

                // Depth changed, close up open buckets.
                if (bucket_depth < bucket_last_depth)
                {
                    var returnDepth:Number = bucket_depths.pop();
                    while (returnDepth >= bucket_depth)
                    {
                        stackBucket = buckets.pop();
                        stackBucketKey = bucket_keys.pop();

                        // Either Object or Array, no key means array.
                        if (stackBucketKey == null)
                            buckets[buckets.length - 1].push(stackBucket);
                        else
                            buckets[buckets.length - 1][stackBucketKey] = stackBucket;

                        // Don't empty the buffer, the main collection resides at 0.
                        if (bucket_depths.length <= 1)
                            break;

                        returnDepth = bucket_depths.pop();
                    }
                }

                // Start New Object
                if (startArrayItem)
                {
                    buckets[buckets.length] = {};
                    bucket_keys[bucket_keys.length] = null;
                    bucket_depths[bucket_depths.length] = bucket_depth;
                }

                // New Array
                if (val == null)
                {
                    buckets[buckets.length] = [];
                    bucket_keys[bucket_keys.length] = key;
                    bucket_depths[bucket_depths.length] = bucket_depth;
                }
                else
                {
                    buckets[buckets.length - 1][key] = val;
                }

                // Save Last State
                bucket_last_depth = bucket_depth;
            }

            // Collapse Remaining Buckets
            while (buckets.length > 1)
            {
                stackBucket = buckets.pop();
                stackBucketKey = bucket_keys.pop();

                // Either Object or Array, no key means array.
                if (stackBucketKey == null)
                    buckets[buckets.length - 1].push(stackBucket);
                else
                    buckets[buckets.length - 1][stackBucketKey] = stackBucket;
            }

            return out;
        }

        private static function parseValue(val:String):*
        {
            if (val == "" || val.length == 0)
                return null;

            if (val == "[]")
                return [];

            else if (val == "''")
                return '';

            else if (val.charAt(0) == "'")
                return val.substr(1, val.length - 2);

            // Has quote escape characters, maintains \\ as well.
            else if (val.charAt(0) == '"')
            {
                if (val.indexOf("\\\\") >= 0)
                    return val.substr(1, val.length - 2).replace(/\\\\/gm, "!---slash-replace---!").replace(/\\/gm, "").replace(/!---slash-replace---!/gm, "\\");
                else
                    return val.substr(1, val.length - 2).replace(/\\/gm, "");
            }

            return val;
        }
    }
}
