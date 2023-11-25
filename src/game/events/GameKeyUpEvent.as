package game.events
{
    import flash.utils.IDataOutput;

    public class GameKeyUpEvent implements IGameEvent
    {
        private static const ID:uint = 4;

        private var index:uint;
        private var key:uint;
        private var timestamp:Number;

        public function GameKeyUpEvent(index:uint, key:uint, timestamp:Number):void
        {
            this.index = index;
            this.key = key;
            this.timestamp = timestamp;
        }

        public function writeData(output:IDataOutput):void
        {
            output.writeUnsignedInt(index);
            output.writeByte(ID);
            output.writeByte(key);
            output.writeFloat(timestamp);
        }
    }
}
