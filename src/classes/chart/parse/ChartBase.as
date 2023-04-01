package classes.chart.parse
{

    import flash.utils.ByteArray;

    public class ChartBase
    {
        public var ignoreValidation:Boolean = false;

        public var validColumnCounts:Array = [4]; //, 5, 6, 7, 8, 9, 10];

        public static var COLUMNS:Object = {4: ['L', 'D', 'U', 'R'],
                5: ['L', 'D', 'C', 'U', 'R'],
                6: ['L', 'Q', 'D', 'U', 'W', 'R'],
                7: ['L', 'Q', 'D', 'C', 'U', 'W', 'R'],
                8: ['L', 'D', 'U', 'R', 'Q', 'W', 'T', 'Y'],
                9: ['L', 'D', 'U', 'R', 'C', 'Q', 'W', 'T', 'Y'],
                10: ['L', 'D', 'C', 'U', 'R', 'Q', 'W', 'V', 'T', 'Y']};

        public var data:Object = {"notes": []};
        public var charts:Array = [];

        public var loaded:Boolean = false;
        public var parsed:Boolean = false;

        public function parse():void
        {

        }

        public function load(fileData:ByteArray, fileName:String = null):Boolean
        {
            return false;
        }

        public function getChartTimeFast(chart_index:Object = null):Number
        {
            return 0;
        }
    }
}
