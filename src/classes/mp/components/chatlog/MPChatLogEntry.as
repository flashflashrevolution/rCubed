package classes.mp.components.chatlog
{
    import flash.display.Sprite;

    public class MPChatLogEntry extends Sprite
    {
        public var built:Boolean = false;

        protected var _width:Number = 200;
        protected var _height:Number = 30;

        public function MPChatLogEntry():void
        {

        }

        public function build(width:Number):void
        {

        }

        override public function get height():Number
        {
            return _height;
        }

    }
}
