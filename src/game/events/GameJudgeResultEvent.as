package game.events
{
    import flash.utils.IDataOutput;

    public class GameJudgeResultEvent implements IGameEvent
    {
        private static const ID:uint = 1;

        private var index:uint;

        private var noteID:uint;
        private var accuracy:int;
        private var timestamp:Number;

        public function GameJudgeResultEvent(index:uint, noteID:uint, accuracy:int, timestamp:Number):void
        {
            this.index = index;
            this.noteID = index;
            this.accuracy = accuracy;
            this.timestamp = timestamp;
        }

        public function writeData(output:IDataOutput):void
        {
            output.writeUnsignedInt(index);
            output.writeByte(ID);
            output.writeInt(noteID);
            output.writeShort(accuracy);
            output.writeUnsignedInt(timestamp);
        }
    }
}
