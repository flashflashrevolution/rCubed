package classes.ui
{
    import classes.Language;
    import classes.ui.Throbber;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    public class UILockWait extends Sprite
    {
        private var icon:Throbber;
        private var timer:Timer;
        private var callback:Function;
        private var closeBtn:BoxButton;

        public function UILockWait(parent:DisplayObjectContainer, useTimer:Boolean = false, closeFunction:Function = null):void
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

            if (useTimer)
            {
                timer = new Timer(10000, 1);
                timer.addEventListener(TimerEvent.TIMER_COMPLETE, e_timerComplete);
                timer.start();

                closeBtn = new BoxButton(this, Main.GAME_WIDTH / 2 - 75, Main.GAME_HEIGHT - 50, 150, 30, Language.instance.string("menu_close"), 12, e_closeButton);
                closeBtn.visible = false;
            }
        }

        private function e_timerComplete(e:TimerEvent):void
        {
            closeBtn.visible = true;
        }

        private function e_closeButton(e:Event):void
        {
            remove();

            if (callback != null)
                callback();
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
