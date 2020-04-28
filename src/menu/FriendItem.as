/**
 * @author Jonathan (Velocity)
 */

package menu
{
    import classes.Box;
    import classes.Text;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class FriendItem extends Sprite
    {
        //- Song Details
        private var nameText:Text;
        private var statusText:Text;
        public var index:Number;
        public var box:Box;

        public function FriendItem(sO:Object, isActive:Boolean = false):void
        {
            //- Make Display
            box = new Box(577, 27 + (isActive ? 60 : 0), false);
            box.active = isActive;

            //- Name
            nameText = new Text(sO["user"], 14);
            nameText.x = 5;
            nameText.width = 350;
            nameText.height = 27;
            box.addChild(nameText);

            //- Diff
            statusText = new Text(sO["status"], 14);
            statusText.x = 70;
            statusText.width = 500;
            statusText.height = 27;
            statusText.align = Text.RIGHT;
            box.addChild(statusText);

            this.addChild(box);

            //- Set Button Mode
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            this.addEventListener(MouseEvent.ROLL_OVER, boxOver);
            this.addEventListener(MouseEvent.ROLL_OUT, boxOut);
        }

        public function dispose():void
        {
            this.removeEventListener(MouseEvent.ROLL_OVER, boxOver);
            this.removeEventListener(MouseEvent.ROLL_OUT, boxOut);

            //- Remove is already existed.
            if (box != null)
            {
                nameText.dispose();
                box.removeChild(nameText);
                nameText = null;
                statusText.dispose();
                box.removeChild(statusText);
                statusText = null;
                box.dispose();
                this.removeChild(box);
                box = null;
            }
        }

        private function boxOver(e:Event = null):void
        {
            box.boxOver();
        }

        private function boxOut(e:Event = null):void
        {
            box.boxOut();
        }
    }
}
