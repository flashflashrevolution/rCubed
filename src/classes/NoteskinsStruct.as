package classes
{
    import game.GameOptions;

    public class NoteskinsStruct
    {
        public static function getDefaultStruct():Object
        {
            var DEFAULT_OPTIONS:GameOptions = new GameOptions();
            DEFAULT_OPTIONS.noteColors.push("receptor");

            var output:Object = {"options": {"grid_dim": "5,2", "rotate": "90"}};
            for (var c:int = 0; c < DEFAULT_OPTIONS.noteColors.length; c++)
            {
                var color_obj:Object = {};
                for (var d:int = 0; d < DEFAULT_OPTIONS.noteDirections.length; d++)
                {
                    var dir_obj:Object = {"r": "", "c": ""};
                    color_obj[DEFAULT_OPTIONS.noteDirections[d]] = dir_obj;
                }
                output[DEFAULT_OPTIONS.noteColors[c]] = color_obj;
            }
            return output;
        }

        public static function getDirectionValue(struct:Object, color:String, dir:String, key:String):*
        {
            if (struct && struct[color] && struct[color][dir] && struct[color][dir][key])
            {
                return struct[color][dir][key];
            }
            return "";
        }

        public static function setDirectionValue(struct:Object, color:String, dir:String, key:String, val:String):void
        {
            if (struct)
            {
                if (!struct[color])
                    struct[color] = {};
                if (!struct[color][dir])
                    struct[color][dir] = {};
                struct[color][dir][key] = val;
            }
        }

        public static function parseCellInput(text:String):Array
        {
            var out:Array = [1, 1];
            var cell_values:Array = text.split(",");
            if (cell_values.length >= 2)
            {
                out[0] = parseInt(cell_values[0]);
                out[1] = parseInt(cell_values[1]);
            }
            else if (cell_values.length == 1)
                out[0] = out[1] = parseInt(cell_values[0]);

            if (isNaN(out[0]) || !isFinite(out[0]) || out[0] < 0 || out[0] > 20)
                out[0] = 1;
            if (isNaN(out[1]) || !isFinite(out[1]) || out[1] < 0 || out[1] > 20)
                out[1] = 1;
            return out;
        }

        public static function textToRotation(t:String, def:Number):Number
        {
            var n:Number = parseFloat(t);
            if (isNaN(n) || !isFinite(n))
                n = def;

            return n % 360;
        }
    }

}
