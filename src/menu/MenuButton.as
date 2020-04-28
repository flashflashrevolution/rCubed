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

    public class MenuButton extends Sprite
    {
        private var box:Box;
        private var boxText:Text;

        private var _message:String;
        private var _isActive:Boolean;

        public var panel:String;
        public var index:String;

        public function MenuButton(message:*, isActive:Boolean = false):void
        {
            this._message = message;
            this._isActive = isActive;

            if (stage)
                init();
            else
                this.addEventListener(Event.ADDED_TO_STAGE, init);
        }

        private function init(e:Event = null):void
        {
            //- Remove Stage Listener
            if (e != null)
                this.removeEventListener(Event.ADDED_TO_STAGE, init);

            //- Add Box
            box = new Box(115, 28);
            box.active = _isActive;

            //- Add Text
            boxText = new Text(_message);
            boxText.width = 115;
            boxText.height = 28;
            boxText.align = Text.CENTER;
            box.addChild(boxText);
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
                boxText.dispose();
                this.removeChild(boxText);
                boxText = null;
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
