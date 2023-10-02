package classes.ui
{
    import flash.display.DisplayObjectContainer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.Point;
    import flash.utils.Timer;

    dynamic public class BoxButton extends Box
    {
        private var _text:Text;
        private var _enabled:Boolean = true;

        private var _listener:Function = null;

        private var _hoverDisplayed:Boolean = false;
        private var _hoverText:String;
        private var _hoverPosition:String = "top";
        private var _hoverSprite:MouseTooltip;
        private var _hoverTimer:Timer = new Timer(500, 1);

        public function BoxButton(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:Number = 0, height:Number = 0, text:String = "", size:int = 12, listener:Function = null)
        {
            super(parent, xpos, ypos, true, false);
            super.setSize(width, height);

            //- Add Text
            _text = new Text(this, 0, 0, text, size, "#FFFFFF");
            _text.setAreaParams(width, height + 1, Text.CENTER);

            //- Set Defaults
            this.mouseEnabled = true;
            this.mouseChildren = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            //- Set click event listener
            if (listener != null)
            {
                this._listener = listener;
                this.addEventListener(MouseEvent.CLICK, listener);
            }
        }

        override public function dispose():void
        {
            if (_listener != null)
                this.removeEventListener(MouseEvent.CLICK, _listener);

            super.dispose();

            if (_text != null)
            {
                _text.dispose();
            }
        }

        ////////////////////////////////////////////////////////////////////////
        //- Hover
        public function setHoverText(hover_text:String, position:String = "top"):void
        {
            if (hover_text != _hoverText)
            {
                // No previous text, add Roll Over Event
                if (_hoverText == null)
                {
                    this.addEventListener(MouseEvent.ROLL_OVER, e_hoverRollOver);
                }
                // Previous Text, clean-up old.
                else
                {
                    if (_hoverSprite)
                    {
                        if (_hoverSprite.parent)
                            _hoverSprite.parent.removeChild(_hoverSprite);

                        _hoverSprite = null;
                    }

                    this.removeEventListener(Event.REMOVED_FROM_STAGE, e_removedFromStage);
                    _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
                }

                // New text is null, clear events.
                if (hover_text == null)
                {
                    this.removeEventListener(MouseEvent.ROLL_OVER, e_hoverRollOver);
                    this.removeEventListener(MouseEvent.ROLL_OUT, e_hoverRollOut);
                    this.removeEventListener(Event.REMOVED_FROM_STAGE, e_removedFromStage);
                    _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
                }

                _hoverText = hover_text;
            }
            _hoverPosition = position;

            // Update Tooltip Instantly
            if (_hoverDisplayed && _hoverText != null)
            {
                e_hoverTimerComplete();
            }
        }

        private function e_hoverRollOver(e:MouseEvent = null):void
        {
            this.addEventListener(MouseEvent.ROLL_OUT, e_hoverRollOut);

            if (this.parent && this.parent.stage)
            {
                _hoverTimer.addEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
                _hoverTimer.start();
            }
        }

        private function e_hoverRollOut(e:MouseEvent):void
        {
            _hoverDisplayed = false;
            _hoverTimer.stop();
            _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);
            this.removeEventListener(MouseEvent.ROLL_OUT, e_hoverRollOut);
            this.removeEventListener(Event.REMOVED_FROM_STAGE, e_removedFromStage);

            if (_hoverSprite && _hoverSprite.parent)
                _hoverSprite.parent.removeChild(_hoverSprite);
        }

        private function e_hoverTimerComplete(e:Event = null):void
        {
            _hoverTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, e_hoverTimerComplete);

            if (_hoverSprite == null)
            {
                _hoverSprite = new MouseTooltip(_hoverText, 300);
            }

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
                _hoverDisplayed = true;
                this.parent.stage.addChild(_hoverSprite);
                this.addEventListener(Event.REMOVED_FROM_STAGE, e_removedFromStage, false, 0, true);
            }
            else
            {
                _hoverDisplayed = false;
            }
        }

        private function e_removedFromStage(e:Event):void
        {
            _hoverDisplayed = false;
            this.removeEventListener(Event.REMOVED_FROM_STAGE, e_removedFromStage);

            if (_hoverSprite && _hoverSprite.parent)
                _hoverSprite.parent.removeChild(_hoverSprite);
        }

        ////////////////////////////////////////////////////////////////////////
        //- Getters / Setters
        override public function set width(value:Number):void
        {
            _text.width = value;
            super.setSize(value, super.height);
        }

        override public function set height(value:Number):void
        {
            _text.height = value;
            super.setSize(super.width, value);
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

        public function get text():String
        {
            return _text.text;
        }

        public function set text(value:String):void
        {
            _text.text = value;
        }

        public function set textColor(color:String):void
        {
            _text.fontColor = color;
        }
    }
}
