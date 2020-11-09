package classes.ui
{
    import assets.menu.icons.fa.iconHeartEmpty;
    import assets.menu.icons.fa.iconHeartFull;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class HeartSelector extends Sprite
    {
        private var outlineSprite:UIIcon;
        private var fillSprite:UIIcon;
        private var _checked:Boolean = false;

        public function HeartSelector(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, isActive:Boolean = true)
        {
            if (parent)
                parent.addChild(this);

            this.x = xpos;
            this.y = ypos;

            init(isActive);
        }

        private function init(isActive:Boolean):void
        {
            this.mouseChildren = false;
            if (isActive)
            {
                this.buttonMode = true;
                this.useHandCursor = true;
                this.addEventListener(MouseEvent.CLICK, e_mouseClick);
            }

            fillSprite = new UIIcon(this, new iconHeartFull(), 16, 16);
            fillSprite.setSize(32, 32);
            fillSprite.setColor("#f7b9e4");

            outlineSprite = new UIIcon(this, new iconHeartEmpty(), 16, 16);
            outlineSprite.setSize(32, 32);

            // Draw Mouse Background
            this.graphics.beginFill(0xff0000, 0);
            this.graphics.drawRect(0, 0, width, height);
            this.graphics.endFill();
        }

        private function e_mouseClick(e:MouseEvent):void
        {
            _checked = !_checked;
            updateSprites();
            dispatchEvent(new Event(Event.CHANGE));
        }

        private function updateSprites():void
        {
            fillSprite.visible = _checked;
        }

        public function get checked():Boolean
        {
            return _checked;
        }

        public function set checked(val:Boolean):void
        {
            _checked = val;
            updateSprites();
        }
    }
}
