package classes
{
    import flash.display.Sprite;
    import flash.geom.ColorTransform;
    import com.flashfla.utils.ColorUtil;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.events.Event;
    import flash.geom.Point;

    dynamic public class BoxIcon extends Box
    {
        private var _icon:UIIcon;
        private var _enabled:Boolean = true;
        private var _iconPadding:int = 11;

        private var _hoverText:String;
        private var _hoverPosition:String = "top";
        private var _hoverSprite:MouseTooltip;
        private var _hoverTimer:Timer = new Timer(500, 1);

        public function BoxIcon(width:Number, height:Number, icon:Sprite, useHover:Boolean = true, useGradient:Boolean = false)
        {
            super(width, height, useHover, useGradient);

            //- Add Icon
            _icon = new UIIcon(this, icon, width / 2 + 1, height / 2 + 1);
            _icon.icon.transform.colorTransform = new ColorTransform(0.88, 0.99, 1);
            _icon.setSize(width - _iconPadding, height - _iconPadding);

            //- Set Defaults
            this.mouseEnabled = true;
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;
        }

        public function setIconColor(color:String):void
        {
            var newColorJ:int = parseInt("0x" + color.replace("#", ""), 16);
            if (isNaN(newColorJ) || newColorJ < 0)
                newColorJ = 0;
            var rgb:Object = ColorUtil.hexToRgb(newColorJ);
            _icon.icon.transform.colorTransform = new ColorTransform((rgb.r / 255), (rgb.g / 255), (rgb.b / 255));
        }

        ////////////////////////////////////////////////////////////////////////
        //- Hover

        public function setHoverText(hover_text:String, position:String = "top"):void
        {
            _hoverText = hover_text;
            _hoverPosition = position;

            this.addEventListener(MouseEvent.ROLL_OVER, e_hoverRollOver);
        }

        private function e_hoverRollOver(e:MouseEvent):void
        {
            this.addEventListener(MouseEvent.ROLL_OUT, e_hoverRollOut);

            if (this.parent && this.parent.stage)
            {
                if (_hoverSprite == null)
                {
                    _hoverSprite = new MouseTooltip(_hoverText, 300);
                }
                _hoverTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
                _hoverTimer.start();
            }
        }

        private function e_hoverRollOut(e:MouseEvent):void
        {
            _hoverTimer.stop();
            this.removeEventListener(MouseEvent.ROLL_OUT, e_hoverRollOut);
            this.removeEventListener(Event.ENTER_FRAME, e_onEnterFrame);

            if (_hoverSprite.parent)
                _hoverSprite.parent.removeChild(_hoverSprite);
        }

        private function e_hoverTimerComplete(e:Event):void
        {
            _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);

            var placePoint:Point = new Point(width / 2, height / 2);

            if (_hoverPosition == "top" || _hoverPosition == "bottom")
                placePoint.x -= (_hoverSprite.width / 2);
            if (_hoverPosition == "left" || _hoverPosition == "right")
                placePoint.y -= (_hoverSprite.height / 2);

            if (_hoverPosition == "top")
                placePoint.y -= (height / 2) + _hoverSprite.height + 2;
            if (_hoverPosition == "bottom")
                placePoint.y += (height / 2) + 2;
            if (_hoverPosition == "left")
                placePoint.x -= (width / 2) + _hoverSprite.width + 2;
            if (_hoverPosition == "right")
                placePoint.x += (width / 2) + 2;

            var stagePoint:Point = this.localToGlobal(placePoint);

            // Keep on Stage
            if (stagePoint.x < 5)
                stagePoint.x = 5;

            if (stagePoint.x + _hoverSprite.width > Main.GAME_WIDTH - 5)
                stagePoint.x = Main.GAME_WIDTH - 5 - _hoverSprite.width;

            if (stagePoint.y < 5)
                stagePoint.y = 5;

            if (stagePoint.y + _hoverSprite.height > Main.GAME_HEIGHT - 5)
                stagePoint.y = Main.GAME_HEIGHT - 5 - _hoverSprite.height;

            // Position
            _hoverSprite.x = stagePoint.x;
            _hoverSprite.y = stagePoint.y;

            if (this.parent && this.parent.stage)
            {
                this.parent.stage.addChild(_hoverSprite);
                this.addEventListener(Event.ENTER_FRAME, e_onEnterFrame, false, 0, true);
            }
        }

        private function e_onEnterFrame(e:Event):void
        {
            if (!this.parent || !this.parent.stage)
            {
                this.removeEventListener(Event.ENTER_FRAME, e_onEnterFrame);

                if (_hoverSprite && _hoverSprite.parent)
                    _hoverSprite.parent.removeChild(_hoverSprite);
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        public function set padding(value:int):void
        {
            _iconPadding = value;
            _icon.setSize(width - _iconPadding, height - _iconPadding);
        }

        override public function set width(value:Number):void
        {
            _icon.setSize(value - _iconPadding, height - _iconPadding);
            super.width = value;
        }

        override public function set height(value:Number):void
        {
            _icon.setSize(width - _iconPadding, value - _iconPadding);
            super.height = value;
        }

        override public function get highlight():Boolean
        {
            return enabled && super.highlight;
        }

        public function set enabled(value:Boolean):void
        {
            _enabled = value;
            this.mouseEnabled = value;
            this.useHandCursor = value;
            this.alpha = value ? 1 : 0.5;
            setHoverStatus(value);
        }

        public function get enabled():Boolean
        {
            return _enabled;
        }
    }
}
