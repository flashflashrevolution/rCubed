package classes.mp
{
    import classes.Language;
    import classes.ui.UILockWait;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.KeyboardEvent;

    public class MPView extends Sprite
    {
        protected static const _gvars:GlobalVariables = GlobalVariables.instance;
        protected static const _mp:Multiplayer = Multiplayer.instance;
        protected static const _lang:Language = Language.instance;

        protected var _lock:UILockWait;

        public function MPView(parent:DisplayObjectContainer, xpos:Number = 0, ypos:Number = 0):void
        {
            this.x = xpos;
            this.y = ypos;

            parent.addChild(this);
        }

        public function build():void
        {

        }

        public function dispose():void
        {

        }

        public function onKeyInput(e:KeyboardEvent):void
        {

        }

        public function onSelect():void
        {

        }

        public function onExit():void
        {

        }

        public function setBlocker(enabled:Boolean):void
        {
            if (enabled && _lock == null)
            {
                _lock = new UILockWait(parent.stage, true);
            }
            else if (!enabled && _lock != null)
            {
                _lock.remove();
                _lock = null;
            }
        }
    }
}
