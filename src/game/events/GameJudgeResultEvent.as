package game.events
{
    import flash.utils.IDataOutput;

    public class GameJudgeResultEvent implements IGameEvent
    {
        private static const ID:uint = 2;

        private var index:uint;
        private var timestamp:Number;

        private var noteID:int;
        private var accuracy:int;

        public function GameJudgeResultEvent(index:uint, noteID:uint, accuracy:int, timestamp:Number):void
        {
            this.index = index;
            this.timestamp = timestamp;
            this.noteID = index;
            this.accuracy = accuracy;
        }

        public function writeData(output:IDataOutput):void
        {
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeByte(ID);
            output.writeInt(noteID);
            output.writeShort(accuracy);
        }
    }
}
