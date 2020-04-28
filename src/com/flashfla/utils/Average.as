package com.flashfla.utils
{

    public class Average
    {
        private var size:int;
        public var value:Number;
        public var valueDeviation:Number;

        public function Average()
        {
            value = 0;
            valueDeviation = 0;
            size = 0;
        }

        public function addValue(value:int):void
        {
            this.value = (this.value * size + value) / (size + 1);
            value -= this.value;
            valueDeviation = (valueDeviation * size + value * value) / (size + 1);
            size++;
        }

        public function get deviation():Number
        {
            return Math.sqrt(valueDeviation);
        }
    }
}
