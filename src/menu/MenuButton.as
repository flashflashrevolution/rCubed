package menu
{
    import classes.ui.BoxButton;
    import flash.display.DisplayObjectContainer;

    public class MenuButton extends BoxButton
    {
        public var panel:String;
        public var index:String;

        public function MenuButton(parent:DisplayObjectContainer = null, xpos:Number = 0, wid:Number = 0, message:String = "", isActive:Boolean = false, listener:Function = null):void
        {
            super(parent, xpos, 0, wid, 28, message, 12, listener);
            super.active = isActive;
        }
    }
}
