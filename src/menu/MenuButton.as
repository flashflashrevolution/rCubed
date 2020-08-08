/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.BoxButton;

    public class MenuButton extends BoxButton
    {
        public var panel:String;
        public var index:String;

        public function MenuButton(message:String, isActive:Boolean = false, width:Number = 115, height:Number = 28, size:int = 12):void
        {
            super(width, height, message, size, "#FFFFFF", true, true);
            super.active = isActive;
        }
    }
}
