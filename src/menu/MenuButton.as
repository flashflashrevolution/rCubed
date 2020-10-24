/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.BoxButton;
    import flash.display.DisplayObjectContainer;

    public class MenuButton extends BoxButton
    {
        public var panel:String;
        public var index:String;

        public function MenuButton(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, message:String = "", isActive:Boolean = false):void
        {
            super(parent, xpos, ypos, 115, 28, message, 12);
            super.active = isActive;
        }
    }
}
