package com.flashfla.utils
{

    public class RollingAverage
    {
        private var size:int;
        private var data:Object;
        private var dataValue:int;

        private static var flash10:Boolean;
        {
            flash10 = SystemUtil.isFlashNewerThan(10);
        }

        private static function newvector(size:int):Object
        {
            return new Vector.<int>(size);
        }

        public function RollingAverage(size:int, value:int = 0)
        {
            this.size = size;
            this.dataValue = value * size;

            if (flash10)
                data = newvector(size);
            else
                data = new Array(size);

            for (var i:int = 0; i < size; i++)
                data[i] = value;
        }

        public function addValue(value:int):void
        {
            if (flash10)
            {
                dataValue += value - data.pop();
                data.unshift(value);
            }
            else
            {
                dataValue += value - data.splice(0, 1)[0];
                data.push(value);
            }
        }

        public function reset(value:int = 0):void
        {
            dataValue = value * size;
            for (var i:int = 0; i < size; i++)
                data[i] = value;
        }

        public function get value():int
        {
            return dataValue / size;
        }
    }
}
