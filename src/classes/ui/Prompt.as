package classes.ui
{
    import assets.GameBackgroundColor;
    import com.flashfla.utils.SpriteUtil;
    import flash.display.Bitmap;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.display.DisplayObject;
    import flash.filters.DropShadowFilter;
    import flash.display.CapsStyle;
    import flash.display.JointStyle;

    public class Prompt extends Sprite
    {
        protected var _width:Number;
        protected var _height:Number;
        protected var _content:Sprite;
        protected var _dropshadow:Sprite;

        public function Prompt(parent:DisplayObjectContainer, width:Number = 200, height:Number = 200)
        {
            _width = width;
            _height = height;

            parent.addChild(this);

            // Background
            const bmp:Bitmap = SpriteUtil.getBitmapSprite(parent.stage);
            this.graphics.beginBitmapFill(bmp.bitmapData);
            this.graphics.drawRect((Main.GAME_WIDTH - _width) / 2, (Main.GAME_HEIGHT - _height) / 2, _width, _height);
            this.graphics.endFill();

            this.graphics.beginFill(0x000000, 0.5);
            this.graphics.drawRect(0, 0, Main.GAME_WIDTH, Main.GAME_HEIGHT);
            this.graphics.endFill();

            // Box
            _content = new Sprite();
            _content.graphics.lineStyle(1, 0x000000, 0, true);
            _content.graphics.beginFill(0xFFFFFF, 0.15);
            _content.graphics.drawRect(0, 0, _width, _height);
            _content.graphics.endFill();
            _content.graphics.lineStyle(3, 0xFFFFFF, 0.35);
            _content.graphics.beginFill(GameBackgroundColor.BG_POPUP, 0.6);
            _content.graphics.drawRect(0, 0, _width, _height);
            _content.graphics.endFill();
            _content.x = (Main.GAME_WIDTH - _width) / 2;
            _content.y = (Main.GAME_HEIGHT - _height) / 2;
            super.addChild(_content);

            _content.graphics.lineStyle(1, 0xFFFFFF, 0.35);

            // Shadow
            _dropshadow = new Sprite();
            _dropshadow.graphics.beginFill(0x000000, 1);
            _dropshadow.graphics.drawRect(0, 0, _width, _height);
            _dropshadow.graphics.endFill();
            _dropshadow.x = _content.x;
            _dropshadow.y = _content.y;
            _dropshadow.filters = [new DropShadowFilter(0, 45, GameBackgroundColor.BG_DARK, 1, 128, 128, 1, 1, false, true, true)];
            super.addChildAt(_dropshadow, 0);
        }

        override public function addChild(child:DisplayObject):DisplayObject
        {
            return _content.addChild(child);
        }

        override public function removeChild(child:DisplayObject):DisplayObject
        {
            return _content.removeChild(child);
        }

        override public function get width():Number
        {
            return _width;
        }

        override public function get height():Number
        {
            return _height;
        }
    }
}
