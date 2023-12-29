package game.events
{
    import flash.utils.IDataOutput;

    public class GamePlaybackEvent
    {
        public var index:uint;
        public var timestamp:uint;

        public function GamePlaybackEvent(index:uint, timestamp:uint)
        {
            this.index = index;
            this.timestamp = timestamp;
        }

        public function writeData(output:IDataOutput):void
        {

        }
    }
}
