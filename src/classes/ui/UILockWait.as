package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import classes.ui.Throbber;

    public class UILockWait extends Sprite
    {
        private var icon:Throbber;

        public function UILockWait(parent:DisplayObjectContainer):void
        {
            this.graphics.beginFill(0x000000, 0.5);
            this.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            this.graphics.endFill();

            this.graphics.lineStyle(3, 0xFFFFFF, 1);
            this.graphics.beginFill(0x000000, 1);
            this.graphics.drawRoundRect(Main.GAME_WIDTH / 2 - 48, Main.GAME_HEIGHT / 2 - 48, 96, 96, 12, 12);
            this.graphics.endFill();

            icon = new Throbber(64, 64, 3);
            icon.x = Main.GAME_WIDTH / 2 - 32;
            icon.y = Main.GAME_HEIGHT / 2 - 32;
            addChild(icon);

            icon.start();

            parent.addChild(this);
        }

        public function remove():void
        {
            icon.stop();

            if (parent != null && parent.contains(this))
            {
                parent.removeChild(this);
            }
        }
    }
}
