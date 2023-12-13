package game.events
{
    import flash.utils.IDataOutput;

    public class GameKeyDownEvent implements IGameEvent
    {
        private static const ID:uint = 3;

        private var index:uint;
        private var key:uint;
        private var timestamp:Number;

        public function GameKeyDownEvent(index:uint, timestamp:Number, key:uint):void
        {
            this.index = index;
            this.timestamp = timestamp;
            this.key = key;
        }

        public function writeData(output:IDataOutput):void
        {
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeByte(ID);
            output.writeByte(key);
        }
    }
}
