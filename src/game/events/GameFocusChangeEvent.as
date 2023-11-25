package game.events
{
    import flash.utils.IDataOutput;

    public class GameFocusChangeEvent implements IGameEvent
    {
        private static const ID:uint = 5;

        private var index:uint;
        private var isFocus:Boolean;
        private var timestamp:int;

        public function GameFocusChangeEvent(index:uint, isFocus:Boolean, timestamp:int):void
        {
            this.index = index;
            this.isFocus = isFocus;
            this.timestamp = timestamp;
        }

        public function writeData(output:IDataOutput):void
        {
            output.writeUnsignedInt(index);
            output.writeByte(ID);
            output.writeByte(isFocus ? 1 : 0);
            output.writeInt(timestamp);
        }
    }
}
