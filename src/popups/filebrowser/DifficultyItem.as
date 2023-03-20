package popups.filebrowser
{
    import assets.menu.ChartDifficultyItem;
    import classes.ui.Text;
    import flash.display.Sprite;

    public class DifficultyItem extends Sprite
    {
        protected const DIFFICULTY_COLORS:Array = [0x349a2b, 0xecd433, 0xd58d10, 0xba3b22, 0x8d0e0e, 0x444444];
        protected const CHART_TYPE_COLORS:Array = [,,,, "ffffff", "00c7ff", "a0ffb9", "ffb600", "ffaaaa", "ac00e5", "000000"];

        public var chart:Object;
        public var chart_id:int;
        public var chart_type:int;
        public var chart_difficulty:String;
        public var chart_difficulty_value:Number;

        public var index:int;
        public var sorting_key:Number = 0;

        public function DifficultyItem(index:int, chart:Object):void
        {
            this.buttonMode = true;
            this.useHandCursor = true;
            this.mouseChildren = false;

            this.chart = chart;
            this.chart_id = index;
            this.chart_type = chart['type'];
            this.chart_difficulty = chart['class_color'];
            this.chart_difficulty_value = parseFloat(chart['difficulty']);

            updateSortingValue();

            drawUI();
        }

        protected function drawUI():void
        {
            addChild(new ChartDifficultyItem());

            var diff:Text = new Text(this, -1, 0, chart['difficulty']);
            diff.setAreaParams(24, 25, "center");

            var name:Text = new Text(this, 27, 0, chart['class']);
            name.setAreaParams(89, 25);

            var type:Text = new Text(this, 105, 0, getChartType(chart['type']));
            type.setAreaParams(30, 25, "right");

            this.graphics.lineStyle(0, 0, 0);
            this.graphics.beginFill(DIFFICULTY_COLORS[getChartColorIndex(chart['class_color'])], 1);
            this.graphics.drawRect(1, 1, 24, 22);
            this.graphics.endFill();
        }

        protected function getChartType(type:int):String
        {
            if (CHART_TYPE_COLORS[type] != null)
                return '<font color="#' + CHART_TYPE_COLORS[type] + '">' + type + 'K</font>';

            return "??";
        }

        protected function getChartColorIndex(type:String):uint
        {
            switch (type)
            {
                case 'Beginner':
                    return 0;
                case 'Easy':
                    return 1;
                case 'Medium':
                    return 2;
                case 'Hard':
                    return 3;
                case 'Challenge':
                    return 4;
                case 'Edit':
                    return 5;
            }
            return 0;
        }

        protected function updateSortingValue():void
        {
            var val:Number = 1;

            val += (chart_type - 4) * 10000;
            val += getChartColorIndex(chart_difficulty) * 10;
            val += chart_difficulty_value;

            this.sorting_key = val;
        }
    }
}
