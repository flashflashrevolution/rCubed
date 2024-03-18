package game.controls
{
    import flash.display.DisplayObjectContainer;
    import game.GameOptions;

    public class ComboTotal extends Combo
    {
        public function ComboTotal(options:GameOptions, parent:DisplayObjectContainer)
        {
            super(options, parent);
        }

        override public function get id():String
        {
            return GameLayoutManager.LAYOUT_TOTAL;
        }
    }
}
