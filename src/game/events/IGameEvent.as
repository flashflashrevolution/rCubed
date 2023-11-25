package game.events
{
    import flash.utils.IDataOutput;

    public interface IGameEvent
    {
        function writeData(output:IDataOutput):void;
    }
}
