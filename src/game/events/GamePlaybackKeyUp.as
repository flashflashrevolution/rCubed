package game.events
{
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    public class GamePlaybackKeyUp extends GamePlaybackEvent
    {
        public static const ID:uint = 4;

        private var key:uint;

        public function GamePlaybackKeyUp(index:uint, timestamp:Number, key:uint):void
        {
            super(index, timestamp);
            this.key = key;
        }

        override public function writeData(output:IDataOutput):void
        {
            output.writeByte(ID);
            output.writeByte(4 + 4 + 1) // Length of everything below this.
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeByte(key);
        }

        public static function readData(input:IDataInput):GamePlaybackKeyUp
        {
            var index:uint = input.readUnsignedInt();
            var timestamp:uint = input.readUnsignedInt();
            var key:uint = input.readUnsignedByte();

            return new GamePlaybackKeyUp(index, timestamp, key);
        }
    }
}
