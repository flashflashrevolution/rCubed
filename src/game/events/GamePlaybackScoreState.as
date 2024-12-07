package game.events
{
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;

    public class GamePlaybackScoreState extends GamePlaybackEvent
    {
        public static const ID:uint = 1;

        public var raw_score:int;
        public var amazing:int;
        public var perfect:int;
        public var good:int;
        public var average:int;
        public var miss:int;
        public var boo:int;
        public var combo:int;
        public var max_combo:int;

        public function GamePlaybackScoreState(index:uint, timestamp:Number):void
        {
            super(ID, index, timestamp);
        }

        override public function writeData(output:IDataOutput):void
        {
            output.writeByte(ID);
            output.writeByte(4 + 4 + 4 + 4 + 4 + 4 + 4 + 4 + 4 + 4 + 4); // Length of everything below this.
            output.writeUnsignedInt(index);
            output.writeUnsignedInt(timestamp);
            output.writeInt(raw_score);
            output.writeInt(amazing);
            output.writeInt(perfect);
            output.writeInt(good);
            output.writeInt(average);
            output.writeInt(miss);
            output.writeInt(boo);
            output.writeInt(combo);
            output.writeInt(max_combo);
        }

        public static function readData(input:IDataInput):GamePlaybackScoreState
        {
            var index:uint = input.readUnsignedInt();
            var timestamp:uint = input.readUnsignedInt();

            const state:GamePlaybackScoreState = new GamePlaybackScoreState(index, timestamp);
            state.raw_score = input.readInt();
            state.amazing = input.readInt();
            state.perfect = input.readInt();
            state.good = input.readInt();
            state.average = input.readInt();
            state.miss = input.readInt();
            state.boo = input.readInt();
            state.combo = input.readInt();
            state.max_combo = input.readInt();

            return state;
        }

        public function toString():String
        {
            return index + ":" + timestamp + ":" + raw_score;
        }
    }
}
