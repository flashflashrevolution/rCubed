package com.flashfla.utils
{

    public class VectorUtil
    {

        public static function fromArr(arr:Array):Vector.<*>
        {
            var vec:Vector.<*> = new <*>[];
            for each (var value:* in arr)
                vec.push(value);
            return vec;
        }

        public static function inVector(vec:*, items:*):Boolean
        {
            if (!(vec is Vector) || !(items is Vector))
            {
                return false;
            }

            var _vec:Vector.<*> = vec as Vector.<*>;
            var _items:Vector.<*> = items as Vector.<*>;

            for (var y:int = 0; y < _items.length; y++)
            {
                for (var x:int = 0; x < _vec.length; x++)
                {
                    if (_vec[x] == _items[y])
                    {
                        return true;
                    }
                }
            }
            return false;
        }


        public static function removeFirst(value:Object, vec:*):Boolean
        {
            if (!(vec is Vector))
                return false;

            var _vec:Vector.<*> = vec as Vector.<*>;

            if (_vec.length == 0)
                return false;

            var ind:int;
            if ((ind = _vec.indexOf(value)) != -1)
            {
                _vec.removeAt(ind);
                return true;
            }
            return false;
        }

    }

}
