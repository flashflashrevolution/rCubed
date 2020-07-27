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

        public function MenuButton(message:String, isActive:Boolean = false):void
        {
            super(115, 28, message, 12, "#FFFFFF", true, true);
        }
    }
}
