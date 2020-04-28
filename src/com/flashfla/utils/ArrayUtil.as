package com.flashfla.utils
{

    public class ArrayUtil
    {

        public static function in_array(inAr:Array, items:Array):Boolean
        {
            for (var y:int = 0; y < items.length; y++)
            {
                for (var x:int = 0; x < inAr.length; x++)
                {
                    if (inAr[x] == items[y])
                    {
                        return true;
                    }
                }
            }
            return false;
        }

        /**
         *	Remove first of the specified value from the array,
         *
         * 	@param arr The array from which the value will be removed
         *
         *	@param value The object that will be removed from the array.
         *
         * 	@langversion ActionScript 3.0
         *	@playerversion Flash 9.0
         *	@tiptext
         */
        public static function remove(value:Object, arr:Array):Boolean
        {
            if (!arr || arr.length == 0)
                return false;

            var ind:int;
            if ((ind = arr.indexOf(value)) != -1)
            {
                arr.splice(ind, 1);
                return true;
            }
            return false;
        }

        /**
         *	Remove all instances of the specified value from the array,
         *
         * 	@param arr The array from which the value will be removed
         *
         *	@param value The object that will be removed from the array.
         *
         * 	@langversion ActionScript 3.0
         *	@playerversion Flash 9.0
         *	@tiptext
         */
        public static function removeValue(value:Object, arr:Array):void
        {
            var len:uint = arr.length;

            for (var i:Number = len; i > -1; i--)
            {
                if (arr[i] === value)
                {
                    arr.splice(i, 1);
                }
            }
        }

        public static function randomize(ar:Array):Array
        {
            var newarr:Array = new Array(ar.length);

            var randomPos:Number = 0;
            for (var i:int = 0; i < newarr.length; i++)
            {
                randomPos = int(Math.random() * ar.length);
                newarr[i] = ar.splice(randomPos, 1)[0];
            }

            return newarr;
        }

    }

}
