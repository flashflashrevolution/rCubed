package game.events
{
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    public class GamePlaybackSpectatorHit extends GamePlaybackEvent
    {
        public static const ID:uint = 6;

        public var direction:String;

        public function GamePlaybackSpectatorHit(index:uint, timestamp:Number, direction:String):void
        {
            super(ID, index, timestamp);
            this.direction = direction;
        }

        override public function writeData(output:IDataOutput):void
        {
            output.writeByte(ID);
            output.writeByte(4 + 4 + 1); // Length of everything below this.
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeByte(direction.charCodeAt(0));
        }

        public static function readData(input:IDataInput):GamePlaybackSpectatorHit
        {
            var index:uint = input.readUnsignedInt();
            var timestamp:uint = input.readUnsignedInt();
            var direction:String = String.fromCharCode(input.readByte());

            return new GamePlaybackSpectatorHit(index, timestamp, direction);
        }

        public function toString():String
        {
            return "[GamePlaybackSpectatorHit = " + index + ":" + timestamp + ":" + direction + "]";
        }
    }
}
