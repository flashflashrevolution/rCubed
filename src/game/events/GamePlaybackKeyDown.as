package game.events
{
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    public class GamePlaybackKeyDown extends GamePlaybackEvent
    {
        public static const ID:uint = 3;

        public var key:uint;

        public function GamePlaybackKeyDown(index:uint, timestamp:Number, key:uint):void
        {
            super(ID, index, timestamp);
            this.key = key;
        }

        override public function writeData(output:IDataOutput):void
        {
            output.writeByte(ID);
            output.writeByte(4 + 4 + 1); // Length of everything below this.
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeByte(key);
        }

        public static function readData(input:IDataInput):GamePlaybackKeyDown
        {
            var index:uint = input.readUnsignedInt();
            var timestamp:uint = input.readUnsignedInt();
            var key:uint = input.readUnsignedByte();

            return new GamePlaybackKeyDown(index, timestamp, key);
        }
    }
}
