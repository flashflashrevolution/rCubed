package game.controls
{
    import assets.GameBackgroundColor;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import game.GameOptions;

    public class ScreenCut extends Sprite
    {
        private var self:ScreenCut;

        public function ScreenCut(options:GameOptions):void
        {
            this.self = this;
            this.graphics.lineStyle(3, GameBackgroundColor.BG_STATIC, 1);
            this.graphics.beginFill(0x000000);

            switch (options.scrollDirection)
            {
                case "down":
                    this.x = 0;
                    this.y = options.screencutPosition * Main.GAME_HEIGHT;
                    this.graphics.drawRect(-Main.GAME_WIDTH, -(Main.GAME_HEIGHT * 3), Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        this.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            self.startDrag(false, new Rectangle(0, 5, 0, Main.GAME_HEIGHT - 7));
                        });
                        this.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            self.stopDrag();
                            options.screencutPosition = (self.y / Main.GAME_HEIGHT);
                        });
                    }
                    break;
                case "right":
                    this.x = options.screencutPosition * Main.GAME_WIDTH;
                    this.y = 0;
                    this.graphics.drawRect(-Main.GAME_WIDTH * 3, -Main.GAME_HEIGHT, Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        this.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            self.startDrag(false, new Rectangle(0, 0, Main.GAME_WIDTH - 7, 0));
                        });
                        this.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            self.stopDrag();
                            options.screencutPosition = (self.x / Main.GAME_WIDTH);
                        });
                    }
                    break;
                case "left":
                    this.x = Main.GAME_WIDTH - (options.screencutPosition * Main.GAME_WIDTH);
                    this.y = 0;
                    this.graphics.drawRect(0, -Main.GAME_HEIGHT, Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        this.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            self.startDrag(false, new Rectangle(0, 0, Main.GAME_WIDTH - 7, 0));
                        });
                        this.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            self.stopDrag();
                            options.screencutPosition = 1 - (self.x / Main.GAME_WIDTH);
                        });
                    }
                    break;
                default:
                    this.x = 0;
                    this.y = Main.GAME_HEIGHT - (options.screencutPosition * Main.GAME_HEIGHT);
                    this.graphics.drawRect(-Main.GAME_WIDTH, 0, Main.GAME_WIDTH * 3, Main.GAME_HEIGHT * 3);

                    if (options.isEditor)
                    {
                        this.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void
                        {
                            self.startDrag(false, new Rectangle(0, 5, 0, Main.GAME_HEIGHT - 7));
                        });
                        this.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void
                        {
                            self.stopDrag();
                            options.screencutPosition = 1 - (self.y / Main.GAME_HEIGHT);
                        });
                    }
                    break;
            }
            this.graphics.endFill();
            if (options.isEditor)
            {
                this.buttonMode = true;
                this.useHandCursor = true;
            }
        }
    }
}
