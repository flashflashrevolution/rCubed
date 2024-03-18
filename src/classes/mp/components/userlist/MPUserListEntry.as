package classes.mp.components.userlist
{
    import classes.Language;
    import classes.mp.MPUser;
    import classes.ui.Text;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class MPUserListEntry extends Sprite
    {
        private static const _lang:Language = Language.instance;

        public static const ENTRY_WIDTH:int = 219;
        public static const ENTRY_HEIGHT:int = 27;

        public var user:MPUser;

        private var title:Text;

        public var index:int = 0;
        public var isStale:Boolean = false;

        public function MPUserListEntry():void
        {
            // Text
            title = new Text(this, 5, 0, "???", 11, "#FFFFFF");
            title.setAreaParams(ENTRY_WIDTH, ENTRY_HEIGHT);
            title.cacheAsBitmap = true;

            this.mouseChildren = false;
            this.buttonMode = true;

            this.addEventListener(MouseEvent.MOUSE_OVER, e_onOver);
            this.addEventListener(MouseEvent.MOUSE_OUT, e_onOut);

            draw(false);
        }

        public function draw(hover:Boolean):void
        {
            this.graphics.clear();
            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.moveTo(0, ENTRY_HEIGHT);
            this.graphics.lineTo(ENTRY_WIDTH, ENTRY_HEIGHT);

            this.graphics.lineStyle(0, 0x000000, 0);
            this.graphics.beginFill(0xFFFFFF, hover ? 0.1 : 0);
            this.graphics.drawRect(0, 0, ENTRY_WIDTH, ENTRY_HEIGHT);
            this.graphics.endFill();
        }

        public function setData(item:MPUser):void
        {
            user = item;
            title.text = user.userLabelHTML;
        }

        public function clear():void
        {
            user = null;
        }

        private function e_onOver(event:MouseEvent):void
        {
            draw(true);
        }

        private function e_onOut(event:MouseEvent):void
        {
            draw(false);
        }
    }
}
