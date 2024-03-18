package game.events
{
    import flash.utils.IDataOutput;

    public class GamePlaybackEvent
    {
        public var id:uint;
        public var index:uint;
        public var timestamp:uint;

        public function GamePlaybackEvent(id:uint, index:uint, timestamp:uint)
        {
            this.id = id;
            this.index = index;
            this.timestamp = timestamp;
        }

        public function writeData(output:IDataOutput):void
        {

        }
    }
}
