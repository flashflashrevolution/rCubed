package popups.settings
{
    import classes.ui.MouseTooltip;
    import classes.ui.ScrollPaneContent;
    import classes.ui.Text;
    import game.GameOptions;
    import flash.geom.Point;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.display.DisplayObject;

    public class SettingsTabBase
    {
        protected static var DEFAULT_OPTIONS:GameOptions = new GameOptions();

        protected var parent:SettingsWindow;
        public var container:ScrollPaneContent;
        private var hover_message:MouseTooltip;

        protected var judgeTitles:Array = ["amazing", "perfect", "good", "average", "miss", "boo"];
        protected var receptorRotations:Array = [1, 0, 2, -1];

        public function SettingsTabBase(settingWindow:SettingsWindow):void
        {
            this.parent = settingWindow;
        }

        public function get name():String
        {
            return null
        }

        public function openTab():void
        {

        }

        public function closeTab():void
        {
            hideTooltip();

            for (var index:int = container.numChildren - 1; index >= 0; index--)
            {
                var olditem:DisplayObject = container.getChildAt(index);
                olditem.removeEventListener(MouseEvent.CLICK, clickHandler);
                olditem.removeEventListener(Event.CHANGE, changeHandler);
            }
        }

        public function setValues():void
        {

        }

        public function clickHandler(e:MouseEvent):void
        {

        }

        public function changeHandler(e:Event):void
        {

        }

        public function drawSeperator(container:ScrollPaneContent, x:int, w:int, y:int, a:int = 0, b:int = 0):int
        {
            container.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            container.graphics.moveTo(x, y + 10 + a);
            container.graphics.lineTo(x + w, y + 10 + a);
            return 20 + a + b;
        }

        protected function setTextMaxWidth(maxWidth:Number):void
        {
            for (var i:int = 0; i < container.numChildren; i++)
            {
                var chd:* = container.getChildAt(i);
                if (chd is Text)
                {
                    chd.width = maxWidth;
                }
            }
        }

        public function displayToolTip(tx:Number, ty:Number, text:String, align:String = "left"):void
        {
            if (!hover_message)
                hover_message = new MouseTooltip();
            hover_message.message = text;

            var messagePoint:Point = parent.globalToLocal(parent.pane.content.localToGlobal(new Point(tx, ty)));

            switch (align)
            {
                default:
                case "left":
                    hover_message.x = messagePoint.x;
                    hover_message.y = messagePoint.y;
                    break;
                case "right":
                    hover_message.x = messagePoint.x - hover_message.width;
                    hover_message.y = messagePoint.y;
                    break;
            }

            parent.addChild(hover_message);
        }

        public function hideTooltip():void
        {
            if (hover_message && parent.contains(hover_message))
                parent.removeChild(hover_message);
        }
    }
}
