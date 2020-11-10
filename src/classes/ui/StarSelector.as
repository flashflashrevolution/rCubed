package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;

    public class StarSelector extends Sprite
    {
        private var outlineSprite:Sprite;
        private var fillSprite:Sprite;
        private var fillMask:Sprite;
        private var _value:Number = 1;
        private var _hovervalue:Number = 0;
        public var MIN_VALUE:Number = 0;
        public var MAX_VALUE:Number = 5;

        public function StarSelector(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, isActive:Boolean = true)
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
                this.addEventListener(MouseEvent.MOUSE_OVER, e_mouseOver);
            }
            // Draw Star Mask
            fillMask = new Sprite();
            for (var i:int = 0; i < 5; i++)
                drawStar(fillMask.graphics, 28, i * 32, 0, false, 0, 2, true);
            addChild(fillMask);

            // Draw Star Fills
            fillSprite = new Sprite();
            drawFill();
            fillSprite.mask = fillMask;
            addChild(fillSprite);

            // Draw Star Outlines
            outlineSprite = new Sprite();
            for (i = 0; i < 5; i++)
                drawStar(outlineSprite.graphics, 28, i * 32, 0);

            // Draw Mouse Background
            this.graphics.beginFill(0xff0000, 0);
            this.graphics.drawRect(0, 0, width, height);
            this.graphics.endFill();

            addChild(outlineSprite);
        }

        private function e_mouseClick(e:MouseEvent):void
        {
            if (_hovervalue != value)
            {
                value = _hovervalue;
                dispatchEvent(new Event(Event.CHANGE));
            }
        }

        private function e_mouseOver(e:MouseEvent):void
        {
            this.addEventListener(MouseEvent.MOUSE_MOVE, e_mouseMove);
            this.addEventListener(MouseEvent.MOUSE_OUT, e_mouseOut);
        }

        private function e_mouseOut(e:MouseEvent):void
        {
            this.removeEventListener(MouseEvent.MOUSE_MOVE, e_mouseMove);
            this.removeEventListener(MouseEvent.MOUSE_OUT, e_mouseOut);
            _hovervalue = 0;
            drawFill();
        }

        private function e_mouseMove(e:MouseEvent):void
        {
            var posX:Number = ((e.localX + 8) / outlineSprite.width);
            var val:Number = Math.round((((MAX_VALUE - MIN_VALUE) * posX) + MIN_VALUE) * 2) / 2;
            if (val != _hovervalue && val >= 0.5)
            {
                _hovervalue = val;
                drawFill();
            }
        }

        private function drawFill():void
        {
            fillSprite.graphics.clear();
            fillSprite.graphics.lineStyle(1, 0, 0);
            fillSprite.graphics.beginFill(0xF2D60D, 1);
            fillSprite.graphics.drawRect(0, 0, value * 32 - 2, 32);
            fillSprite.graphics.endFill();

            if (_hovervalue > 0)
            {
                fillSprite.graphics.beginFill(0x4EBFE5, 1);
                fillSprite.graphics.drawRect(0, 0, _hovervalue * 32 - 2, 32);
                fillSprite.graphics.endFill();
            }
        }

        public function addBackgroundStars():void
        {
            var bgStars:Sprite = new Sprite();
            for (var i:int = 0; i < 5; i++)
                drawStar(bgStars.graphics, 28, i * 32, 0, true, 0xFFFFFF, 0, false);
            bgStars.alpha = 0.2;
            addChildAt(bgStars, 0);
        }

        public function get value():Number
        {
            return _value;
        }

        public function set value(val:Number):void
        {
            _value = val;
            drawFill();
        }

        public function set outline(val:Boolean):void
        {
            outlineSprite.visible = val;
        }

        public static function drawStar(grph:Graphics, size:Number, _x:Number = 0, _y:Number = 0, _fill:Boolean = false, _fillColor:uint = 0xffffff, _borderThickness:int = 2, _isMask:Boolean = false):void
        {
            var STAR_WIDTH:Number = size;
            var STAR_HEIGHT:Number = size;

            if (!_isMask)
            {
                grph.lineStyle(1, 0, 0);
                grph.beginFill(0, 0);
                grph.drawRect(0, 0, size, size);
                grph.endFill();
            }

            grph.beginFill(_fillColor, _fill ? 1 : 0);
            grph.lineStyle(_borderThickness, 0xffffff, 1, true);
            grph.moveTo(_x + (0.5 * STAR_WIDTH), _y + (0 * STAR_HEIGHT));
            grph.lineTo(_x + (0.667 * STAR_WIDTH), _y + (0.296 * STAR_HEIGHT));
            grph.lineTo(_x + (1 * STAR_WIDTH), _y + (0.37 * STAR_HEIGHT));
            grph.lineTo(_x + (0.778 * STAR_WIDTH), _y + (0.611 * STAR_HEIGHT));
            grph.lineTo(_x + (0.815 * STAR_WIDTH), _y + (0.944 * STAR_HEIGHT));
            grph.lineTo(_x + (0.5 * STAR_WIDTH), _y + (0.815 * STAR_HEIGHT));
            grph.lineTo(_x + (0.185 * STAR_WIDTH), _y + (0.944 * STAR_HEIGHT));
            grph.lineTo(_x + (0.241 * STAR_WIDTH), _y + (0.611 * STAR_HEIGHT));
            grph.lineTo(_x + (0 * STAR_WIDTH), _y + (0.37 * STAR_HEIGHT));
            grph.lineTo(_x + (0.333 * STAR_WIDTH), _y + (0.296 * STAR_HEIGHT));
            grph.lineTo(_x + (0.5 * STAR_WIDTH), _y + (0 * STAR_HEIGHT));
            grph.endFill();
        }
    }
}
