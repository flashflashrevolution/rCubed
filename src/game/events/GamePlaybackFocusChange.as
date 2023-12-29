package game.events
{
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    public class GamePlaybackFocusChange extends GamePlaybackEvent
    {
        public static const ID:uint = 5;

        private var isFocus:Boolean;

        public function GamePlaybackFocusChange(index:uint, timestamp:int, isFocus:Boolean):void
        {
            super(index, timestamp);
            this.isFocus = isFocus;
        }

        override public function writeData(output:IDataOutput):void
        {
            output.writeByte(ID);
            output.writeByte(4 + 4 + 1) // Length of everything below this.
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeByte(isFocus ? 1 : 0);
        }

        public static function readData(input:IDataInput):GamePlaybackFocusChange
        {
            var index:uint = input.readUnsignedInt();
            var timestamp:uint = input.readUnsignedInt();
            var isFocus:Boolean = input.readUnsignedByte() == 1 ? true : false;

            return new GamePlaybackFocusChange(index, timestamp, isFocus);
        }
    }
}
