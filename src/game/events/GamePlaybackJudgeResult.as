package game.events
{
    import flash.utils.IDataOutput;
    import flash.utils.IDataInput;

    public class GamePlaybackJudgeResult extends GamePlaybackEvent
    {
        public static const ID:uint = 2;

        public var noteID:int;
        public var accuracy:int;

        public function GamePlaybackJudgeResult(index:uint, noteID:uint, accuracy:int, timestamp:Number):void
        {
            super(ID, index, timestamp);
            this.noteID = index;
            this.accuracy = accuracy;
        }

        override public function writeData(output:IDataOutput):void
        {
            output.writeByte(ID);
            output.writeByte(4 + 4 + 4 + 2); // Length of everything below this.
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeInt(noteID);
            output.writeShort(accuracy);
        }

        public static function readData(input:IDataInput):GamePlaybackJudgeResult
        {
            var index:uint = input.readUnsignedInt();
            var timestamp:uint = input.readUnsignedInt();
            var noteID:int = input.readInt();
            var accuracy:int = input.readShort();

            return new GamePlaybackJudgeResult(index, noteID, accuracy, timestamp);
        }

        public function toString():String
        {
            return index + ":" + timestamp + ":" + noteID + ":" + accuracy;
        }
    }
}
