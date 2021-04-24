package classes
{
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;

    public class Alert
    {
        public static const RED:uint = 0x6D0E0E;
        public static const GREEN:uint = 0x116D0E;
        public static const DARK_GREEN:uint = 0x084400;
        public static const BLUE:uint = 0x0E3F6D;

        public static var STAGE_REF:Stage;

        private static var ALERT_DISPLAY:AlertDisplay;
        private static var ALERT_QUEUE:Array = [];
        private static var HAS_EVENT:Boolean = false;

        public static function init(ref:Stage):void
        {
            STAGE_REF = ref;
            ALERT_DISPLAY = new AlertDisplay();
        }

        public static function add(message:String, age:int = 120, color:uint = 0x000000):void
        {
            // Nothing is being displayed, start a new one.
            if (ALERT_DISPLAY.isFinished)
            {
                ALERT_DISPLAY.setData(message, age, color);
                ALERT_DISPLAY.x = Main.GAME_WIDTH - ALERT_DISPLAY.width - 5;
                ALERT_DISPLAY.y = Main.GAME_HEIGHT - ALERT_DISPLAY.height - 5;
                STAGE_REF.addChild(ALERT_DISPLAY);

                if (!HAS_EVENT)
                {
                    STAGE_REF.addEventListener(Event.ENTER_FRAME, alertOnFrame, false, int.MAX_VALUE - 2);
                    HAS_EVENT = true;
                }
            }
            else
            {
                ALERT_QUEUE.push(new AlertQueueItem(message, age, color));
            }
        }

        private static function alertOnFrame(e:Event):void
        {
            // Progress Active Alert
            if (!ALERT_DISPLAY.isFinished)
            {
                ALERT_DISPLAY.progress();
                if (ALERT_DISPLAY.time > ALERT_DISPLAY.age)
                {
                    ALERT_DISPLAY.isFinished = true;
                    STAGE_REF.removeChild(ALERT_DISPLAY);

                    if (ALERT_QUEUE.length == 0)
                    {
                        STAGE_REF.removeEventListener(Event.ENTER_FRAME, alertOnFrame);
                        HAS_EVENT = false;
                    }
                }
            }

            // Add new alert if the old alert is finished
            else if (ALERT_QUEUE.length > 0)
            {
                var newAlert:AlertQueueItem = ALERT_QUEUE.pop();
                add(newAlert.message, newAlert.age, newAlert.color);
            }
        }
    }
}

internal class AlertQueueItem
{
    public var message:String;
    public var age:int;
    public var color:uint;

    public function AlertQueueItem(message:String, age:int = 120, color:uint = 0x000000)
    {
        this.message = message;
        this.age = age;
        this.color = color;
    }
}

import flash.display.Sprite;
import flash.text.AntiAliasType;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

internal class AlertDisplay extends Sprite
{
    public var message:String;
    public var age:int = 120;
    public var time:int = 0;
    public var isFinished:Boolean = true;

    private var _textfield:TextField;

    public function AlertDisplay()
    {
        this.mouseEnabled = false;
        this.mouseChildren = false;

        this.message = message;

        _textfield = new TextField();
        _textfield.x = 6;
        _textfield.y = 2;
        _textfield.selectable = false;
        _textfield.embedFonts = true;
        _textfield.antiAliasType = AntiAliasType.ADVANCED;
        _textfield.autoSize = TextFieldAutoSize.LEFT;
        _textfield.defaultTextFormat = Constant.TEXT_FORMAT;

        this.addChild(_textfield);
    }

    public function setData(message:String, age:int = 120, color:uint = 0x000000):void
    {
        _textfield.htmlText = message;

        this.graphics.clear()
        this.graphics.lineStyle(1, 0xFFFFFF, 2, true);
        this.graphics.beginFill(color, 0.75);
        this.graphics.drawRect(0, 0, _textfield.width + 13, _textfield.height + 5);
        this.graphics.endFill();

        this.age = age;
        this.time = 0;
        this.alpha = 0;

        this.isFinished = false;
    }

    public function progress():void
    {
        time += 1;
        if (time <= 15)
        {
            this.alpha = (time / 15);
        }
        else if (time >= age - 14)
        {
            this.alpha = 1 + ((age - 14 - time) / 15);
        }
        else
        {
            this.alpha = 1;
        }
    }
}
