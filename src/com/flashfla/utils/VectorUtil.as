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
            var _vec:Vector.<*> = Vector.<*>(vec);
            var _items:Vector.<*> = Vector.<*>(items);

            if (!(vec.length) || !(items.length) || vec.length < items.length)
            {
                return false;
            }

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
            if (!(vec is Vector.<*>))
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

        // Returns element index closest to target
        public static function binarySearch(vec:*, target:Number, prop: String): int
        {
            if (!(vec is Vector.<*>))
                return -1;

            var _vec:Vector.<*> = vec as Vector.<*>;

            var n: int = _vec.length;
            var i: int = 0;
            var j: int = n;
            var mid: int = 0;
        
            // Corner cases
            if (n == 0)
                return -1;
            if (target <= _vec[0][prop])
                return 0;
            if (target >= _vec[n - 1][prop])
                return n - 1;
        
            // Doing binary search
            while (i < j)
            {
                mid = (i + j) / 2;
        
                if (_vec[mid][prop] == target) {
                    return mid;
                }
        
                // If target is less than array
                // element,then search in left
                if (target < _vec[mid][prop])
                {
                    // If target is greater than previous
                    // to mid, return closest of two
                    if (mid > 0 && target > _vec[mid - 1][prop]) {
                        return getClosest(_vec[mid - 1][prop], _vec[mid][prop], target) == _vec[mid - 1][prop] ? mid - 1 : mid;
                    }
                    
                    // Repeat for left half
                    j = mid;             
                }
        
                // If target is greater than mid
                else
                {
                    if (mid < n - 1 && target < _vec[mid + 1][prop]) {
                        return getClosest(_vec[mid][prop], _vec[mid + 1][prop], target) == _vec[mid][prop] ? mid : mid + 1;
                    }             
                    i = mid + 1; // update i
                }
            }
        
            // Only single element left after search
            return mid;
        }
        
        // Method to compare which one is the more close
        // We find the closest by taking the difference
        // between the target and both values. It assumes
        // that val2 is greater than val1 and target lies
        // between these two.
        private static function getClosest(val1: Number, val2: Number, target: Number): Number
        {
            return target - val1 >= val2 - target ? val2 : val1;
        }
    }
}
