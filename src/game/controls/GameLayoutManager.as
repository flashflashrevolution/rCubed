package game.controls
{
    import flash.display.Sprite;
    import game.GameOptions;
    import game.GameplayDisplay;

    public class GameLayoutManager extends Sprite
    {
        public static const LAYOUT_BAR_TOP:String = "bartop";
        public static const LAYOUT_BAR_BOTTOM:String = "barbottom";
        public static const LAYOUT_PROGRESS_BAR:String = "progressbar";
        public static const LAYOUT_PROGRESS_TEXT:String = "progresstext";
        public static const LAYOUT_RECEPTORS:String = "receptors";
        public static const LAYOUT_JUDGE:String = "judge";
        public static const LAYOUT_HEALTH:String = "health";
        public static const LAYOUT_SCORE:String = "score";
        public static const LAYOUT_COMBO:String = "combo";
        public static const LAYOUT_TOTAL:String = "combototal";
        public static const LAYOUT_COMBO_STATIC:String = "combostatic";
        public static const LAYOUT_TOTAL_STATIC:String = "combototalstatic";
        public static const LAYOUT_ACCURACY_BAR:String = "accuracybar";
        public static const LAYOUT_PA:String = "pa";
        public static const LAYOUT_RAWGOODS:String = "rawgoods";
        public static const LAYOUT_RAWGOODS_STATIC:String = "rawgoodsstatic";
        public static const LAYOUT_MP_FFR_SCORE:String = "mpffrscore";

        public var gameplay:GameplayDisplay;
        public var options:GameOptions;
        public var defaultLayout:Object;

        public function GameLayoutManager(gameplay:GameplayDisplay, options:GameOptions):void
        {
            buildDefaultLayout();

            this.gameplay = gameplay;
            this.options = options;
        }

        public function save():void
        {
            cleanLayout(options.layout);
        }

        public function interfaceLayout(key:String, defaults:Boolean = true):Object
        {
            if (defaults)
            {
                var ret:Object = {};
                var def:Object = defaultLayout[key];

                for (var i:String in def)
                    ret[i] = def[i];

                var layout:Object = options.layout[key];
                for (i in layout)
                    ret[i] = layout[i];

                return ret;
            }
            else if (!options.layout[key])
                options.layout[key] = {};

            return options.layout[key];
        }

        public function interfacePosition(sprite:Sprite, key:String):void
        {
            if (!sprite)
                return;

            var layout:Object = interfaceLayout(key);
            for (var p:String in layout)
                if (p in sprite)
                    sprite[p] = layout[p];
        }

        private function buildDefaultLayout():void
        {
            defaultLayout = {};
            defaultLayout[LAYOUT_BAR_TOP] = {x: 0, y: 0, scale: 1, alpha: 1, rotation: 0, type: 0};
            defaultLayout[LAYOUT_BAR_BOTTOM] = {x: 0, y: Main.GAME_HEIGHT, scale: 1, alpha: 1, rotation: 0, type: 0};
            defaultLayout[LAYOUT_PROGRESS_BAR] = {x: 161, y: 9, scale: 1, alpha: 1, rotation: 0};
            defaultLayout[LAYOUT_PROGRESS_TEXT] = {x: 768, y: 5, scale: 1, alpha: 1, rotation: 0, alignment: "right"};
            defaultLayout[LAYOUT_JUDGE] = {x: (Main.GAME_WIDTH / 2), y: 225, scale: 1, alpha: 1, rotation: 0};
            defaultLayout[LAYOUT_ACCURACY_BAR] = {x: (Main.GAME_WIDTH / 2), y: 328, alpha: 1, rotation: 0, width: 200, height: 16};
            defaultLayout[LAYOUT_HEALTH] = {x: Main.GAME_WIDTH - 37, y: 70, scale: 1, alpha: 1, rotation: 0};
            defaultLayout[LAYOUT_RECEPTORS] = {x: Main.GAME_WIDTH / 2, y: Main.GAME_HEIGHT / 2, z: 0, scale: 1, rotation: 0, rotationX: 0};

            defaultLayout[LAYOUT_PA] = {x: 18, y: 80, scale: 1, alpha: 1, rotation: 0, type: 0, show_labels: true};
            defaultLayout[LAYOUT_SCORE] = {x: (Main.GAME_WIDTH / 2), y: 436, scale: 1, alpha: 1, rotation: 0};
            defaultLayout[LAYOUT_COMBO] = {x: 222, y: 396, scale: 1, alpha: 1, rotation: 0, alignment: "right"};
            defaultLayout[LAYOUT_COMBO_STATIC] = {x: 220, y: 434, scale: 1, alpha: 1, rotation: 0, alignment: "left"};
            defaultLayout[LAYOUT_TOTAL] = {x: 554, y: 402, scale: 1, alpha: 1, rotation: 0, alignment: "left"};
            defaultLayout[LAYOUT_TOTAL_STATIC] = {x: 552, y: 434, scale: 1, alpha: 1, rotation: 0, alignment: "right"};
            defaultLayout[LAYOUT_RAWGOODS] = {x: 73, y: 350, scale: 1, alpha: 1, rotation: 0, alignment: "left"};
            defaultLayout[LAYOUT_RAWGOODS_STATIC] = {x: 71, y: 371, scale: 1, alpha: 1, rotation: 0, alignment: "right"};

            defaultLayout[LAYOUT_MP_FFR_SCORE] = {x: Main.GAME_WIDTH - 150, y: 0, scale: 1, alpha: 1, rotation: 0};
        }

        /**
         * Removes all non-existent components or properties that match the defaults.
         * @param layout
         */
        public function cleanLayout(layout:Object):void
        {
            var key:String;
            var prop:String;

            // Remove non-existent Components
            for (key in layout)
            {
                if (!(key in defaultLayout))
                {
                    delete layout[key];
                }
            }

            // Remove default values.
            for (key in defaultLayout)
            {
                // Component not fond.
                if (!(key in layout))
                    continue;

                var dprop:Object = defaultLayout[key];
                var sprop:Object = layout[key];

                for (prop in dprop)
                {
                    // Default prop not found.
                    if (!(prop in sprop))
                        continue;

                    // Value matches default, remove.
                    if (sprop[prop] == dprop[prop])
                    {
                        delete sprop[prop];
                    }
                }
            }

            // Remove empty components.
            for (key in layout)
            {
                var cprop:Object = layout[key];
                var ccount:Number = 0;

                for (prop in cprop)
                    ccount++;

                if (ccount == 0)
                {
                    delete layout[key];
                }
            }
        }
    }
}
