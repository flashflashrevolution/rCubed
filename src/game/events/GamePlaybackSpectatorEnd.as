package game.events
{
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    public class GamePlaybackSpectatorEnd extends GamePlaybackEvent
    {
        public static const ID:uint = 7;

        public var direction:String;

        public function GamePlaybackSpectatorEnd(index:uint, timestamp:Number):void
        {
            super(ID, index, timestamp);
        }

        override public function writeData(output:IDataOutput):void
        {
            output.writeByte(ID);
            output.writeByte(4 + 4 + 1); // Length of everything below this.
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeByte(0);
        }

        public static function readData(input:IDataInput):GamePlaybackSpectatorEnd
        {
            var index:uint = input.readUnsignedInt();
            var timestamp:uint = input.readUnsignedInt();
            var end_type:uint = input.readByte();

            return new GamePlaybackSpectatorEnd(index, timestamp);
        }

        public function toString():String
        {
            return "[GamePlaybackSpectatorEnd = " + index + ":" + timestamp + "]";
        }
    }
}
