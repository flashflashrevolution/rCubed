package be.aboutme.airserver.endpoints
{
    import flash.events.IEventDispatcher;

    public interface IEndPoint extends IEventDispatcher
    {
        function open():Boolean;
        function close():void;
        function type():String;
        function currentPort():uint;
    }
}
