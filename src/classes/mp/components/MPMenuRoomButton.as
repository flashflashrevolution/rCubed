package classes.mp.components
{
    import classes.ui.Box;
    import classes.ui.Text;
    import flash.display.DisplayObjectContainer;
    import flash.events.MouseEvent;

    public class MPMenuRoomButton extends Box
    {
        private var _name:Text;
        private var _state:Text;

        private var _listener:Function = null;

        public function MPMenuRoomButton(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, width:Number = 0, height:Number = 0, listener:Function = null)
        {
            super(parent, xpos, ypos, true, false);
            super.setSize(width, height);

            //- Add Text
            _name = new Text(this, 2, 0, "---name---", 10, "#FFFFFF");
            _name.setAreaParams(width - 4, height / 2 + 1, "center");

            _state = new Text(this, 0, height / 2, "----state----", 10, "#FFFFFF");
            _state.setAreaParams(width - 4, height / 2 + 1, "center");

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

            if (_name != null)
            {
                _name.dispose();
            }
        }

        override public function draw():void
        {
            super.draw();

            this.graphics.lineStyle(1, 0xFFFFFF, 0.35);
            this.graphics.moveTo(5, height / 2);
            this.graphics.lineTo(_width - 5, height / 2);
        }

        public function updateText(name:String, state:String):void
        {
            _name.text = name;
            _state.text = state;
        }

    }
}
