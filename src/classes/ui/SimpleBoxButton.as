package classes.ui
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class SimpleBoxButton extends Sprite
    {
        private var _width:Number;
        private var _height:Number;

        public function SimpleBoxButton(width:Number, height:Number)
        {
            super();
            this._height = height;
            this._width = width;

            drawBox(false);

            this.mouseChildren = false;
            this.tabEnabled = false;
            this.useHandCursor = true;
            this.buttonMode = true;

            addEventListener(MouseEvent.MOUSE_OVER, e_mouseOver);
        }

        private function e_mouseOver(e:MouseEvent):void
        {
            addEventListener(MouseEvent.MOUSE_OUT, e_mouseOut);
            drawBox(true);
        }

        private function e_mouseOut(e:MouseEvent):void
        {
            removeEventListener(MouseEvent.MOUSE_OUT, e_mouseOut);
            drawBox(false);
        }

        private function drawBox(doHover:Boolean):void
        {
            graphics.clear();
            graphics.lineStyle(0, 0, 0);
            graphics.beginFill(0xffffff, doHover ? 0.2 : 0);
            graphics.drawRect(0, 0, _width, _height);
            graphics.endFill();
        }

    }

}
